#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=${1:-public}
DEB_GLOB=${2:-"dist/*.deb"}
ARCHITECTURES=${ARCHITECTURES:-"amd64 arm64"}

mkdir -p "$OUT_DIR"

POOL_DIR="$OUT_DIR/pool/main/hello"
mkdir -p "$POOL_DIR"

for deb in $(ls $DEB_GLOB 2>/dev/null || true); do
  cp "$deb" "$POOL_DIR/"
done

DIST_DIR="$OUT_DIR/dists/stable"

if ! command -v dpkg-scanpackages >/dev/null 2>&1; then
  echo "dpkg-scanpackages not found. Install dpkg-dev to generate Packages." >&2
  exit 2
fi

# Generate Packages and Packages.gz for each architecture
MD5_ENTRIES=""
SHA256_ENTRIES=""

for ARCH in $ARCHITECTURES; do
  BINARY_DIR="$DIST_DIR/main/binary-$ARCH"
  mkdir -p "$BINARY_DIR"

  # generate Packages (uncompressed) and Packages.gz
  (cd "$OUT_DIR" && dpkg-scanpackages --arch "$ARCH" pool /dev/null > "dists/stable/main/binary-$ARCH/Packages")
  gzip -9c "$BINARY_DIR/Packages" > "$BINARY_DIR/Packages.gz"

  PACKAGES_FILE="$BINARY_DIR/Packages"
  PACKAGES_GZ="$BINARY_DIR/Packages.gz"

  PACKAGES_SIZE=$(stat -c%s "$PACKAGES_FILE")
  PACKAGES_GZ_SIZE=$(stat -c%s "$PACKAGES_GZ")
  PACKAGES_MD5=$(md5sum "$PACKAGES_FILE" | awk '{print $1}')
  PACKAGES_GZ_MD5=$(md5sum "$PACKAGES_GZ" | awk '{print $1}')
  PACKAGES_SHA256=$(sha256sum "$PACKAGES_FILE" | awk '{print $1}')
  PACKAGES_GZ_SHA256=$(sha256sum "$PACKAGES_GZ" | awk '{print $1}')

  # Append entries with proper formatting (space + hash + space + size + space + path)
  MD5_ENTRIES="${MD5_ENTRIES} ${PACKAGES_MD5} ${PACKAGES_SIZE} main/binary-${ARCH}/Packages
 ${PACKAGES_GZ_MD5} ${PACKAGES_GZ_SIZE} main/binary-${ARCH}/Packages.gz
"
  SHA256_ENTRIES="${SHA256_ENTRIES} ${PACKAGES_SHA256} ${PACKAGES_SIZE} main/binary-${ARCH}/Packages
 ${PACKAGES_GZ_SHA256} ${PACKAGES_GZ_SIZE} main/binary-${ARCH}/Packages.gz
"
done

# generate Release file with checksums for all architectures
{
  echo "Origin: GitHub Pages"
  echo "Label: GitHub Pages APT Repo"
  echo "Suite: stable"
  echo "Codename: stable"
  echo "Architectures: $ARCHITECTURES"
  echo "Components: main"
  echo "Description: A simple APT repo hosted on GitHub Pages"
  echo "Date: $(date -Ru)"
  echo "MD5Sum:"
  printf "%s" "$MD5_ENTRIES"
  echo "SHA256:"
  printf "%s" "$SHA256_ENTRIES"
} > "$DIST_DIR/Release"

if [[ "${GPG_SIGN:-}" == "true" ]]; then
  if ! command -v gpg >/dev/null 2>&1; then
    echo "gpg not found. Install gnupg to sign the Release file." >&2
    exit 3
  fi
  # InRelease (clearsigned, preferred by modern apt)
  gpg --batch --yes --armor --clearsign --output "$DIST_DIR/InRelease" "$DIST_DIR/Release"
  # Release.gpg (detached signature, for older apt versions)
  gpg --batch --yes --armor --detach-sign --output "$DIST_DIR/Release.gpg" "$DIST_DIR/Release"
  echo "Release signed with GPG"
fi

if [[ "${GPG_SIGN:-}" == "true" ]]; then
  gpg --batch --yes --armor --export > "$OUT_DIR/signing-key.asc"
  gpg --batch --yes --export > "$OUT_DIR/signing-key.gpg"
  echo "Public key exported to $OUT_DIR/signing-key.asc and $OUT_DIR/signing-key.gpg"
fi

echo "APT repo generated in $OUT_DIR"
