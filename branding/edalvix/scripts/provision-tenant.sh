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
#   -k         keep Nextcloud news/survey apps enabled
#
# Environment:
#   OCC        full occ command, overrides -d/-u, e.g. for Docker:
#              OCC="docker exec -u www-data nextcloud php occ" provision-tenant.sh -d /var/www/html algumaempresa
#   EDALVIX_CLIENT_DOWNLOAD_URL  where users download the Edalvix Cloud clients

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
    *) sed -n '5,19p' "$0"; exit 2 ;;
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

# Nextcloud-branded news and telemetry are not part of the Edalvix product
if [ "$KEEP_APPS" -eq 0 ]; then
  for app in nextcloud_announcements survey_client; do
    occ app:disable "$app" >/dev/null 2>&1 || true
  done
fi

occ maintenance:theme:update >/dev/null 2>&1 || true

echo "==> Done. Desktop clients for this customer:"
echo "    build:   cmake -DEDALVIX_TENANT=${TENANT} ..."
echo "    or MSI:  msiexec /i EdalvixCloud.msi OVERRIDESERVERURL=${URL}"
echo "    or type '${TENANT}' in the server field of the generic Edalvix Cloud client."
