#!/bin/bash
# SPDX-FileCopyrightText: 2026 EDALVIX
# SPDX-License-Identifier: MIT
#
# Hermetic tests for branding/edalvix/scripts (no network, no real Nextcloud).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS="$ROOT/branding/edalvix/scripts"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

# Fake Nextcloud release
mkdir -p "$WORK/src/nextcloud/themes"
# shellcheck disable=SC2016
echo '<?php $OC_Version = [32,0,1,0];' > "$WORK/src/nextcloud/version.php"
tar -cjf "$WORK/nextcloud.tar.bz2" -C "$WORK/src" nextcloud

# apply-theme.sh
bash "$SCRIPTS/apply-theme.sh" "$WORK/src/nextcloud" > /dev/null
for f in defaults.php core/css/server.css core/css/guest.css core/img/logo/logo.svg core/img/favicon.svg assets/logo.svg assets/logoheader.svg assets/favicon.svg assets/favicon.png; do
  [ -f "$WORK/src/nextcloud/themes/edalvix/$f" ] || fail "theme file missing: $f"
done
if bash "$SCRIPTS/apply-theme.sh" "$WORK/nope" 2> /dev/null; then fail "apply-theme accepted a non-Nextcloud dir"; fi
php -l "$ROOT/branding/edalvix/theme/defaults.php" > /dev/null || fail "defaults.php has syntax errors"
# shellcheck disable=SC2016
php -r 'require $argv[1]; $t = new OC_Theme(); if ($t->getName() !== "Edalvix Cloud" || $t->getColorPrimary() !== "#0068ce") exit(1);' \
  "$ROOT/branding/edalvix/theme/defaults.php" || fail "defaults.php returns unexpected values"

# build-release.sh (local tarball, no download)
NEXTCLOUD_TARBALL="$WORK/nextcloud.tar.bz2" bash "$SCRIPTS/build-release.sh" 32.0.1 "$WORK/dist" > /dev/null
for f in edalvix-cloud-32.0.1.tar.bz2 edalvix-cloud-32.0.1.zip edalvix-cloud-32.0.1.tar.bz2.sha256 edalvix-cloud-32.0.1.zip.sha512; do
  [ -f "$WORK/dist/$f" ] || fail "package missing: $f"
done
tar -tjf "$WORK/dist/edalvix-cloud-32.0.1.tar.bz2" | grep -q '^nextcloud/themes/edalvix/defaults.php$' || fail "theme not packaged"
(cd "$WORK/dist" && sha256sum -c --quiet edalvix-cloud-32.0.1.tar.bz2.sha256) || fail "bad checksum"

# provision-tenant.sh installs the theme itself when missing, before changing anything
mkdir -p "$WORK/fresh/nextcloud"
echo '<?php' > "$WORK/fresh/nextcloud/version.php"
cat > "$WORK/fakephp" <<'MOCK'
#!/bin/bash
shift  # drop the occ path
echo "$*" >> "$OCC_LOG"
MOCK
chmod +x "$WORK/fakephp"
mkdir -p "$WORK/bin" && ln -sf "$WORK/fakephp" "$WORK/bin/php"
export OCC_LOG="$WORK/occ.log"
: > "$OCC_LOG"
PATH="$WORK/bin:$PATH" bash "$SCRIPTS/provision-tenant.sh" -u "$(id -un)" -d "$WORK/fresh/nextcloud" empresa3 > /dev/null
[ -f "$WORK/fresh/nextcloud/themes/edalvix/assets/logo.svg" ] || fail "provision did not install the missing theme"
grep -qx "theming:config logo $WORK/fresh/nextcloud/themes/edalvix/assets/logo.svg" "$OCC_LOG" || fail "provision did not use the installed logo"
if PATH="$WORK/bin:$PATH" bash "$SCRIPTS/provision-tenant.sh" -u "$(id -un)" -d "$WORK/nope" empresa3 2> /dev/null; then
  fail "provision accepted a non-Nextcloud dir"
fi

# provision-tenant.sh (occ mocked: records every call)
cat > "$WORK/occ" <<'MOCK'
#!/bin/bash
echo "$*" >> "$OCC_LOG"
if [ "$1" = "config:import" ]; then
  cat >> "$(dirname "$OCC_LOG")/stdin.log"
fi
if [ "$1" = "app:list" ]; then
  printf 'Enabled:\n  - activity: 3.0.0\n  - dashboard: 7.0.0\n  - files: 2.0.0\n  - files_sharing: 1.20.0\n  - nextcloud_announcements: 2.0.0\n  - photos: 3.0.0\n  - viewer: 3.0.0\n  - files_pdfviewer: 3.0.0\n  - my_extra_app: 1.0.0\nDisabled:\n  - encryption: 2.0.0\n'
fi
MOCK
chmod +x "$WORK/occ"
export OCC_LOG="$WORK/occ.log"
OCC="$WORK/occ" bash "$SCRIPTS/provision-tenant.sh" -d /var/www/html AlgumaEmpresa > /dev/null
grep -qx 'config:system:set trusted_domains 1 --value=algumaempresa.edalvix.cloud' "$OCC_LOG" || fail "trusted domain not set"
grep -qx 'config:system:set overwrite.cli.url --value=https://algumaempresa.edalvix.cloud' "$OCC_LOG" || fail "overwrite.cli.url not set"
grep -qx 'config:system:set theme --value=edalvix' "$OCC_LOG" || fail "theme not enabled"
grep -qx 'config:system:set default_language --value=pt_BR' "$OCC_LOG" || fail "pt_BR not the default language"
grep -qx 'config:system:set skeletondirectory --value=' "$OCC_LOG" || fail "Nextcloud sample files still given to new users"
grep -qx 'theming:config name Edalvix Cloud' "$OCC_LOG" || fail "theming name not set"
grep -qx 'theming:config logo /var/www/html/themes/edalvix/assets/logo.svg' "$OCC_LOG" || fail "logo path wrong"
grep -qx 'app:disable nextcloud_announcements' "$OCC_LOG" || fail "announcements not disabled"
# Lockdown: everything but the file apps is disabled, nothing can be installed
for app in activity dashboard photos my_extra_app; do
  grep -qx "app:disable $app" "$OCC_LOG" || fail "lockdown did not disable $app"
done
for app in files files_sharing viewer files_pdfviewer encryption; do
  if grep -qx "app:disable $app" "$OCC_LOG"; then fail "lockdown disabled $app"; fi
done
grep -qx 'config:system:set appstoreenabled --value=false --type=boolean' "$OCC_LOG" || fail "app store still enabled"
grep -qx 'config:import' "$OCC_LOG" || fail "apps_paths not imported"
grep -qF '{"system":{"apps_paths":[{"path":"/var/www/html/apps","url":"/apps","writable":false}]}}' "$WORK/stdin.log" || fail "apps_paths not read-only or path wrong"
if grep -q 'config:system:set apps_paths' "$OCC_LOG"; then fail "apps_paths set key by key (breaks occ)"; fi
grep -qx 'config:app:set files_sharing outgoing_server2server_share_enabled --value=no' "$OCC_LOG" || fail "federation still enabled"
grep -qx 'config:system:set defaultapp --value=files' "$OCC_LOG" || fail "files is not the start page"

: > "$OCC_LOG"
EDALVIX_EXTRA_APPS="my_extra_app photos" OCC="$WORK/occ" bash "$SCRIPTS/provision-tenant.sh" -d /var/www/html empresa4 > /dev/null
if grep -qE '^app:disable (my_extra_app|photos)$' "$OCC_LOG"; then fail "EDALVIX_EXTRA_APPS not kept"; fi

: > "$OCC_LOG"
OCC="$WORK/occ" bash "$SCRIPTS/provision-tenant.sh" -D example.org -k empresa2 > /dev/null
grep -qx 'config:system:set trusted_domains 1 --value=empresa2.example.org' "$OCC_LOG" || fail "custom domain ignored"
if grep -q 'app:disable' "$OCC_LOG"; then fail "-k did not keep apps"; fi
if grep -q 'appstoreenabled' "$OCC_LOG"; then fail "-k still locked the instance down"; fi

if OCC="$WORK/occ" bash "$SCRIPTS/provision-tenant.sh" 'bad_name' 2> /dev/null; then fail "invalid tenant accepted"; fi

echo "All Edalvix branding tests passed"
