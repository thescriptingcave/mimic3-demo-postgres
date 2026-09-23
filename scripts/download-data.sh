#!/usr/bin/env bash
#
# Downloads the MIMIC-III Clinical Database Demo (v1.4) CSV files from
# PhysioNet and extracts them into ./data for the docker-compose loader.
#
# Usage:
#   ./scripts/download-data.sh [dest_dir]   (default: ./data)
#
set -Eeuo pipefail

VERSION="1.4"
ZIP_URL="https://physionet.org/content/mimiciii-demo/get-zip/${VERSION}/"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-${ROOT_DIR}/data}"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "${TMP_DIR}"' EXIT

hash_check() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$1"
  else
    shasum -a 256 -c "$1"
  fi
}

echo "Downloading MIMIC-III Clinical Database Demo v${VERSION} (~13 MB)..."
curl -fSL --retry 3 -o "${TMP_DIR}/mimic-demo.zip" "${ZIP_URL}"

echo "Extracting to ${DEST} ..."
mkdir -p "${DEST}"
unzip -oq "${TMP_DIR}/mimic-demo.zip" -d "${TMP_DIR}/unzipped"
cp -R "${TMP_DIR}/unzipped"/mimic-iii-clinical-database-demo-*/ "${DEST}/"

echo "Verifying checksums (SHA256SUMS.txt)..."
(cd "${DEST}" && hash_check SHA256SUMS.txt)

echo "Done. MIMIC-III demo CSV files are ready in ${DEST}"
echo "Start the database with: docker compose up -d"