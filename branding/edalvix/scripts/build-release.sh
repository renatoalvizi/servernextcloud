#!/bin/bash
# SPDX-FileCopyrightText: 2026 EDALVIX
# SPDX-License-Identifier: MIT
#
# Build an Edalvix Cloud server package from an official Nextcloud release:
# downloads nextcloud-<version>.tar.bz2, verifies its SHA-256, adds the
# Edalvix theme and repackages it as edalvix-cloud-<version>.{tar.bz2,zip}.
#
# Usage: build-release.sh <nextcloud-version> [output-dir]
#   e.g. build-release.sh 32.0.1 ./dist
#
# Set NEXTCLOUD_TARBALL=/path/to/nextcloud-<version>.tar.bz2 to use a local
# archive (for instance one produced by release-build.yml) instead of downloading.

set -euo pipefail

VERSION="${1:?Usage: build-release.sh <nextcloud-version> [output-dir]}"
OUT="$(mkdir -p "${2:-./dist}" && cd "${2:-./dist}" && pwd)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="${NEXTCLOUD_DOWNLOAD_URL:-https://download.nextcloud.com/server/releases}"
NAME="edalvix-cloud-${VERSION}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ -n "${NEXTCLOUD_TARBALL:-}" ]; then
  cp "$NEXTCLOUD_TARBALL" "$WORK/nextcloud.tar.bz2"
else
  echo "Downloading Nextcloud $VERSION..."
  curl -fsSL -o "$WORK/nextcloud.tar.bz2" "$BASE_URL/nextcloud-${VERSION}.tar.bz2"
  curl -fsSL -o "$WORK/nextcloud.tar.bz2.sha256" "$BASE_URL/nextcloud-${VERSION}.tar.bz2.sha256"
  expected="$(cut -d' ' -f1 < "$WORK/nextcloud.tar.bz2.sha256")"
  actual="$(sha256sum "$WORK/nextcloud.tar.bz2" | cut -d' ' -f1)"
  if [ "$expected" != "$actual" ]; then
    echo "error: checksum mismatch for nextcloud-${VERSION}.tar.bz2" >&2
    exit 1
  fi
fi

tar -xjf "$WORK/nextcloud.tar.bz2" -C "$WORK"
bash "$HERE/apply-theme.sh" "$WORK/nextcloud"

(
  cd "$WORK"
  tar -cjf "$OUT/${NAME}.tar.bz2" nextcloud
  rm -f "$OUT/${NAME}.zip"
  zip -qr "$OUT/${NAME}.zip" nextcloud
)
(
  cd "$OUT"
  for f in "${NAME}.tar.bz2" "${NAME}.zip"; do
    sha256sum "$f" > "$f.sha256"
    sha512sum "$f" > "$f.sha512"
  done
)

echo "Edalvix Cloud package written to $OUT/${NAME}.{tar.bz2,zip}"
