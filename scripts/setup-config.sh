#!/usr/bin/env bash
#
# setup-config.sh — create the local, git-ignored configuration files.
#
# The app reads its backend host, OAuth client IDs and wallet settings from four
# property lists. Those files are deliberately NOT committed, so that a public
# clone of this repository contains no deployment-specific endpoints.
#
# This script copies the committed templates into the locations the Xcode targets
# expect. Existing files are never overwritten.
#
# Usage:  ./scripts/setup-config.sh
#
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
templates="$repo_root/edim/Config/templates"

# template filename -> destination (relative to repo root)
copy_if_missing() {
    local src="$templates/$1"
    local dest="$repo_root/$2"

    if [[ ! -f "$src" ]]; then
        echo "  ✗ missing template: $src" >&2
        return 1
    fi

    if [[ -f "$dest" ]]; then
        echo "  • kept existing  $2"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  ✓ created        $2"
}

echo "Setting up local configuration…"

copy_if_missing "Backend-Edim.plist"    "edim/edim/API/Backend-Edim.plist"
copy_if_missing "Base-Prod.plist"       "edim/edim/API/Local communication/Bases/Base-Prod.plist"
copy_if_missing "Base-Dev.plist"        "edim/edim/API/Local communication/Bases/Base-Dev.plist"
copy_if_missing "WalletInfo-Edim.plist" "edim/edim/Resources/WalletInfo-Edim.plist"

# Signing configuration (Apple Developer Team ID).
if [[ -f "$repo_root/edim/Config/Local.xcconfig" ]]; then
    echo "  • kept existing  edim/Config/Local.xcconfig"
else
    cp "$repo_root/edim/Config/Local.xcconfig.example" "$repo_root/edim/Config/Local.xcconfig"
    echo "  ✓ created        edim/Config/Local.xcconfig"
fi

# Trust anchors. These cannot be templated — they are real certificates and must
# be supplied out of band — so the script only reports which ones are absent.
anchors=(
    "issuer_ca"
    "verifier_ca_prod"
    "pidissuerca02_eu"
    "reader_ca"
    "verifier_ca_dev"
    "eudi_pid_issuer_ut"
    "pidissuerca02_ut"
)

missing_anchors=()
for anchor in "${anchors[@]}"; do
    [[ -f "$repo_root/edim/edim/Resources/$anchor.der" ]] || missing_anchors+=("$anchor.der")
done

if [[ ${#missing_anchors[@]} -eq 0 ]]; then
    echo "  • all trust anchors present"
else
    echo "  ! missing trust anchors (${#missing_anchors[@]} of ${#anchors[@]}):"
    for anchor in "${missing_anchors[@]}"; do
        echo "      - edim/edim/Resources/$anchor"
    done
fi

cat <<'EOF'

Done.

Next steps:
  1. Edit the files above and replace the example.com placeholders with your
     own backend host, client IDs and issuer settings.
  2. Set EDIM_DEVELOPMENT_TEAM in edim/Config/Local.xcconfig to your Apple
     Developer Team ID.
  3. Add your own GoogleService-Info.plist if you use Firebase.
  4. Supply the trust anchors listed above — see edim/Config/TRUST_ANCHORS.md.
     Without them the app builds, but issuance and presentation will fail.

All of these files are git-ignored and will not be committed.
EOF
