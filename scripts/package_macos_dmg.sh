#!/usr/bin/env bash
# Build a compressed read-only DMG from a signed macOS .app bundle.
#
# Usage:
#   ./scripts/package_macos_dmg.sh /path/to/YourApp.app [output_directory]
#
# The default output directory is ./dist relative to the current working directory.
# Output file name includes the app bundle name and short version when Info.plist is readable.

set -euo pipefail

usage() {
  echo "Usage: $0 <path/to/App.app> [output_directory]" >&2
  exit 1
}

if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
  usage
fi

SOURCE_APP="${1}"
OUTPUT_DIR="${2:-dist}"

if [[ ! -d "${SOURCE_APP}" ]]; then
  echo "error: not a directory: ${SOURCE_APP}" >&2
  exit 1
fi

if [[ "${SOURCE_APP}" != *.app ]]; then
  echo "error: expected path ending in .app, got: ${SOURCE_APP}" >&2
  exit 1
fi

INFO_PLIST="${SOURCE_APP}/Contents/Info.plist"
if [[ ! -f "${INFO_PLIST}" ]]; then
  echo "error: missing Info.plist: ${INFO_PLIST}" >&2
  exit 1
fi

APP_BASENAME="$(basename "${SOURCE_APP}")"
APP_NAME="${APP_BASENAME%.app}"

VERSION=""
if /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}" &>/dev/null; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}" 2>/dev/null || true)"
fi

VOLUME_NAME="${APP_NAME}"
if [[ -n "${VERSION}" ]]; then
  VOLUME_NAME="${APP_NAME} ${VERSION}"
fi

DMG_NAME="${APP_NAME}"
if [[ -n "${VERSION}" ]]; then
  DMG_NAME="${APP_NAME}-${VERSION}"
fi

mkdir -p "${OUTPUT_DIR}"

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/dmg-staging.XXXXXX")"
cleanup() {
  rm -rf "${STAGING}"
}
trap cleanup EXIT

ditto "${SOURCE_APP}" "${STAGING}/${APP_BASENAME}"
ln -sf /Applications "${STAGING}/Applications"

DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}.dmg"
if [[ -f "${DMG_PATH}" ]]; then
  rm -f "${DMG_PATH}"
fi

echo "Creating ${DMG_PATH} (volume: ${VOLUME_NAME})"
hdiutil create \
  -volname "${VOLUME_NAME}" \
  -srcfolder "${STAGING}" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "${DMG_PATH}"

echo "Done: ${DMG_PATH}"
