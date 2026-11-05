#!/bin/bash
# SPDX-FileCopyrightText: 2026 EDALVIX
# SPDX-License-Identifier: MIT
#
# Install the Edalvix Cloud theme into a Nextcloud tree (an installation or an
# extracted release). The theme lives in themes/, which Nextcloud's integrity
# check ignores, so the official code signature stays valid.
#
# Usage: apply-theme.sh <nextcloud-dir>

set -euo pipefail

NC_DIR="${1:?Usage: apply-theme.sh <nextcloud-dir>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAND_DIR="$(dirname "$HERE")"

if [ ! -f "$NC_DIR/version.php" ]; then
  echo "error: '$NC_DIR' does not look like a Nextcloud directory (no version.php)" >&2
  exit 1
fi

TARGET="$NC_DIR/themes/edalvix"
rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -a "$BRAND_DIR/theme/." "$TARGET/"
# Images used by provision-tenant.sh (occ theming:config needs paths inside the instance)
mkdir -p "$TARGET/assets"
cp -a "$BRAND_DIR/assets/." "$TARGET/assets/"

echo "Edalvix Cloud theme installed at $TARGET"
