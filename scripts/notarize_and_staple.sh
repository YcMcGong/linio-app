#!/usr/bin/env bash
# Submit a macOS artifact to Apple notary service and staple the ticket.
#
# Prerequisites (one-time):
#   xcrun notarytool store-credentials "PROFILE_NAME" \
#     --apple-id "you@example.com" \
#     --team-id "XXXXXXXXXX" \
#     --password "app-specific-password"
#
# Usage:
#   ./scripts/notarize_and_staple.sh <path/to/file.dmg|.zip|.app> [keychain_profile_name]
#
# Default keychain profile name: NOTARYTOOL_PROFILE (override with second argument).

set -euo pipefail

usage() {
  echo "Usage: $0 <artifact.dmg|.zip|.app> [keychain_profile_name]" >&2
  exit 1
}

if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
  usage
fi

ARTIFACT="${1}"
PROFILE="${2:-NOTARYTOOL_PROFILE}"

if [[ ! -e "${ARTIFACT}" ]]; then
  echo "error: not found: ${ARTIFACT}" >&2
  exit 1
fi

echo "Submitting for notarization: ${ARTIFACT}"
echo "Using notarytool keychain profile: ${PROFILE}"
xcrun notarytool submit "${ARTIFACT}" --keychain-profile "${PROFILE}" --wait

echo "Stapling: ${ARTIFACT}"
xcrun stapler staple "${ARTIFACT}"

echo "Verify (optional):"
echo "  spctl --assess --type open --context context:primary-signature -v \"${ARTIFACT}\""
