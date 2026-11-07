#!/bin/bash
# SPDX-FileCopyrightText: 2026 EDALVIX
# SPDX-License-Identifier: MIT
#
# Configure a Nextcloud instance as the Edalvix Cloud of one customer,
# reachable at https://<tenant>.edalvix.cloud. Safe to run again.
#
# Usage: provision-tenant.sh [options] <tenant>
#   -d DIR     Nextcloud directory as seen by occ   (default: /var/www/nextcloud)
#   -u USER    user that runs occ                  (default: www-data)
#   -D DOMAIN  base domain                         (default: edalvix.cloud)
#   -k         keep the apps as they are (skip the "files only" lockdown)
#
# Lockdown (default): only files, sharing between the company's users, previews
# and security apps stay enabled; the app store is off and the apps folder is
# read-only, so no administrator can install anything. Federation (sharing with
# other servers, including other Edalvix customers) is turned off.
#
# Environment:
#   OCC        full occ command, overrides -d/-u, e.g. for Docker:
#              OCC="docker exec -u www-data nextcloud php occ" provision-tenant.sh -d /var/www/html algumaempresa
#   EDALVIX_CLIENT_DOWNLOAD_URL  where users download the Edalvix Cloud clients
#   EDALVIX_EXTRA_APPS           extra app ids to keep enabled (space separated)

set -euo pipefail

NC_DIR="/var/www/nextcloud"
RUN_AS="www-data"
DOMAIN="edalvix.cloud"
KEEP_APPS=0

while getopts "d:u:D:k" opt; do
  case "$opt" in
    d) NC_DIR="$OPTARG" ;;
    u) RUN_AS="$OPTARG" ;;
    D) DOMAIN="$OPTARG" ;;
    k) KEEP_APPS=1 ;;
    *) sed -n '5,25p' "$0"; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

TENANT="$(echo "${1:?Usage: provision-tenant.sh [options] <tenant>}" | tr '[:upper:]' '[:lower:]')"
if ! [[ "$TENANT" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "error: '$TENANT' is not a valid subdomain (letters, digits and '-')" >&2
  exit 1
fi

HOST="${TENANT}.${DOMAIN}"
URL="https://${HOST}"
CLIENT_URL="${EDALVIX_CLIENT_DOWNLOAD_URL:-https://edalvix.com.br/cloud/download}"
ASSETS="$NC_DIR/themes/edalvix/assets"

if [ -n "${OCC:-}" ]; then
  read -r -a OCC_CMD <<< "$OCC"
elif [ "$(id -un)" = "$RUN_AS" ]; then
  OCC_CMD=(php "$NC_DIR/occ")
else
  OCC_CMD=(sudo -u "$RUN_AS" php "$NC_DIR/occ")
fi

occ() { "${OCC_CMD[@]}" "$@"; }

# The theme (and the logos used below) must be inside the instance before any
# setting changes, so a missing theme cannot leave the instance half-configured.
if [ -z "${OCC:-}" ]; then
  if [ ! -f "$NC_DIR/version.php" ]; then
    echo "error: '$NC_DIR' is not a Nextcloud directory (use -d)" >&2
    exit 1
  fi
  if [ ! -f "$ASSETS/logo.svg" ]; then
    echo "==> Edalvix theme not installed yet, installing it"
    bash "$(dirname "${BASH_SOURCE[0]}")/apply-theme.sh" "$NC_DIR"
  fi
  if [ "$(id -un)" != "$RUN_AS" ]; then
    chown -R "$RUN_AS": "$NC_DIR/themes/edalvix" 2>/dev/null || true
  fi
else
  echo "note: with OCC set, run apply-theme.sh on the Nextcloud files first (theme expected at $ASSETS)"
fi

echo "==> Provisioning Edalvix Cloud for $URL"

# Address
occ config:system:set trusted_domains 1 --value="$HOST"
occ config:system:set overwrite.cli.url --value="$URL"
occ config:system:set overwriteprotocol --value="https"

# Theme defaults (themes/edalvix, installed by apply-theme.sh)
occ config:system:set theme --value="edalvix"

# Visual identity (Theming app, takes precedence over the theme defaults)
occ app:enable theming >/dev/null || true
occ theming:config name "Edalvix Cloud"
occ theming:config url "https://edalvix.com.br"
occ theming:config slogan "Seus arquivos sempre com você"
occ theming:config primary_color "#0068ce" 2>/dev/null || occ theming:config color "#0068ce"
occ theming:config background_color "#071d33" 2>/dev/null || true
occ theming:config background backgroundColor 2>/dev/null || true
occ theming:config logo "$ASSETS/logo.svg"
occ theming:config logoheader "$ASSETS/logoheader.svg"
occ theming:config favicon "$ASSETS/favicon.svg"
occ theming:config disable-user-theming no 2>/dev/null || true

# Client download links shown to users
occ config:system:set customclient_desktop --value="$CLIENT_URL"
occ config:system:set customclient_android --value="$CLIENT_URL"
occ config:system:set customclient_ios --value="$CLIENT_URL"

# Lockdown: files and previews only, nothing can be installed
if [ "$KEEP_APPS" -eq 0 ]; then
  # Files, internal sharing, previews (viewer: images/video/audio, PDF, text),
  # trash/versions, security, and the core apps Nextcloud cannot run without.
  KEEP=(
    files files_sharing files_trashbin files_versions files_lock
    viewer files_pdfviewer text
    theming notifications
    password_policy bruteforcesettings twofactor_totp twofactor_backupcodes suspicious_login admin_audit
    serverinfo logreader
    dav settings provisioning_api oauth2 cloud_federation_api federatedfilesharing
    lookup_server_connector workflowengine
  )
  read -r -a EXTRA <<< "${EDALVIX_EXTRA_APPS:-}"
  KEEP+=("${EXTRA[@]}")

  echo "==> Lockdown: keeping only file apps"
  # "app:list" prints "Enabled:" then "  - appid: version" lines, then "Disabled:"
  mapfile -t ENABLED < <(occ app:list | sed -n '/^Enabled:/,/^Disabled:/s/^  - \([a-z0-9_]*\):.*/\1/p')
  for app in "${ENABLED[@]}"; do
    keep=0
    for k in "${KEEP[@]}"; do
      [ "$app" = "$k" ] && keep=1 && break
    done
    if [ "$keep" -eq 0 ]; then
      # Apps that Nextcloud marks as "always enabled" refuse; that is fine
      if occ app:disable "$app" >/dev/null 2>&1; then
        echo "    disabled $app"
      fi
    fi
  done

  # Nothing can be installed: no app store, read-only apps folder
  occ config:system:set appstoreenabled --value=false --type=boolean
  occ config:system:set apps_paths 0 path --value="$NC_DIR/apps"
  occ config:system:set apps_paths 0 url --value="/apps"
  occ config:system:set apps_paths 0 writable --value=false --type=boolean

  # Updates are done by Edalvix, not from the web interface
  occ config:system:set upgrade.disable-web --value=true --type=boolean
  # Files is the start page; no Nextcloud help links
  occ config:system:set defaultapp --value=files
  occ config:system:set knowledgebaseenabled --value=false --type=boolean

  # No sharing with other servers: each company stays isolated
  for key in outgoing_server2server_share_enabled incoming_server2server_share_enabled \
             outgoing_server2server_group_share_enabled incoming_server2server_group_share_enabled \
             lookupServerEnabled lookupServerUploadEnabled; do
    occ config:app:set files_sharing "$key" --value=no
  done
fi

occ maintenance:theme:update >/dev/null 2>&1 || true

echo "==> Done. Desktop clients for this customer:"
echo "    build:   cmake -DEDALVIX_TENANT=${TENANT} ..."
echo "    or MSI:  msiexec /i EdalvixCloud.msi OVERRIDESERVERURL=${URL}"
echo "    or type '${TENANT}' in the server field of the generic Edalvix Cloud client."
