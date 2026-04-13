#!/usr/bin/env bash
# =============================================================================
# MiniApps/build-bundles.sh
#
# Packages each mini app bundle directory into a self-contained ZIP archive
# ready to be hosted and downloaded by the SuperApp host application.
#
# Usage:
#   chmod +x build-bundles.sh
#   ./build-bundles.sh [--out <output-dir>]
#
# Output:
#   dist/shopping-bundle.zip
#   dist/health-bundle.zip
#   dist/chat-bundle.zip
#
# The resulting ZIPs extract to a flat directory (e.g. shopping-bundle/)
# containing index.html, manifest.json, css/, and js/.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/dist"

# Parse optional --out flag
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

BUNDLES=("shopping-bundle" "health-bundle" "chat-bundle")

for BUNDLE in "${BUNDLES[@]}"; do
  SRC="${SCRIPT_DIR}/${BUNDLE}"
  DEST="${OUTPUT_DIR}/${BUNDLE}.zip"

  if [[ ! -d "$SRC" ]]; then
    echo "⚠️  Bundle directory not found: $SRC — skipping"
    continue
  fi

  echo "📦  Packaging ${BUNDLE} → ${DEST}"
  rm -f "$DEST"

  # Create a clean ZIP from inside the bundle directory so that extraction
  # yields <bundle-name>/index.html (not a nested path).
  (cd "$SCRIPT_DIR" && zip -r "$DEST" "$BUNDLE" \
    --exclude "*/.DS_Store" \
    --exclude "*/__MACOSX/*" \
    --exclude "*/node_modules/*")

  SIZE=$(du -sh "$DEST" | cut -f1)
  echo "   ✅  Done — ${SIZE}"
done

echo ""
echo "All bundles built in: ${OUTPUT_DIR}"
echo ""
echo "Bundle checksums:"
for BUNDLE in "${BUNDLES[@]}"; do
  DEST="${OUTPUT_DIR}/${BUNDLE}.zip"
  if [[ -f "$DEST" ]]; then
    CHECKSUM=$(shasum -a 256 "$DEST" | awk '{print $1}')
    echo "  ${BUNDLE}.zip  sha256:${CHECKSUM}"
  fi
done
