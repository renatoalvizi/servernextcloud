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
for f in defaults.php core/img/logo/logo.svg core/img/favicon.svg assets/logo.svg assets/logoheader.svg assets/favicon.svg; do
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

# provision-tenant.sh (occ mocked: records every call)
cat > "$WORK/occ" <<'MOCK'
#!/bin/bash
echo "$*" >> "$OCC_LOG"
MOCK
chmod +x "$WORK/occ"
export OCC_LOG="$WORK/occ.log"
OCC="$WORK/occ" bash "$SCRIPTS/provision-tenant.sh" -d /var/www/html AlgumaEmpresa > /dev/null
grep -qx 'config:system:set trusted_domains 1 --value=algumaempresa.edalvix.cloud' "$OCC_LOG" || fail "trusted domain not set"
grep -qx 'config:system:set overwrite.cli.url --value=https://algumaempresa.edalvix.cloud' "$OCC_LOG" || fail "overwrite.cli.url not set"
grep -qx 'config:system:set theme --value=edalvix' "$OCC_LOG" || fail "theme not enabled"
grep -qx 'theming:config name Edalvix Cloud' "$OCC_LOG" || fail "theming name not set"
grep -qx 'theming:config logo /var/www/html/themes/edalvix/assets/logo.svg' "$OCC_LOG" || fail "logo path wrong"
grep -qx 'app:disable nextcloud_announcements' "$OCC_LOG" || fail "announcements not disabled"

: > "$OCC_LOG"
OCC="$WORK/occ" bash "$SCRIPTS/provision-tenant.sh" -D example.org -k empresa2 > /dev/null
grep -qx 'config:system:set trusted_domains 1 --value=empresa2.example.org' "$OCC_LOG" || fail "custom domain ignored"
if grep -q 'app:disable' "$OCC_LOG"; then fail "-k did not keep apps"; fi

if OCC="$WORK/occ" bash "$SCRIPTS/provision-tenant.sh" 'bad_name' 2> /dev/null; then fail "invalid tenant accepted"; fi

echo "All Edalvix branding tests passed"
