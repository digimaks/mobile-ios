#!/usr/bin/env bash
#
# SPDX-License-Identifier: EUPL-1.2
#
# Restricts the Firebase/Google API key shipped in GoogleService-Info.plist so that it
# is only usable by this app's iOS bundle identifiers, and only for the Google APIs the
# app actually calls.
#
# WHY THIS MATTERS
#   An iOS API key is an *identifier*, not a secret: it ships inside every IPA and can
#   be extracted from any App Store build in seconds. Rotating it achieves nothing on
#   its own, because the replacement is equally extractable. The real control is the
#   application + API restriction applied here.
#
# WHAT IT DOES NOT DO
#   It does not touch the key value, so no app update is required and existing installs
#   keep working.
#
# SAFETY
#   Both app bundle IDs are allowlisted. Restricting to the production bundle ID alone
#   would silently break Crashlytics on edim-dev, which shares this same key.
#
# Usage:
#   ./scripts/restrict-firebase-key.sh            # show what would change
#   ./scripts/restrict-firebase-key.sh --apply    # actually apply it
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLIST="$REPO_ROOT/edim/edim/GoogleService-Info.plist"

APPLY=false
[[ "${1:-}" == "--apply" ]] && APPLY=true

# --- Bundle identifiers permitted to use the key -----------------------------------
# Both app targets embed the same GoogleService-Info.plist and therefore the same key.
# SigningFileExtension links no Firebase product and must NOT be listed.
BUNDLE_IDS=(
  "lv.zzdats.edim"       # edim      (production)
  "lv.zzdats.edim.dev1"  # edim-dev  (development)
)

# --- Google APIs the app actually calls --------------------------------------------
# Firebase Installations backs both Crashlytics and Analytics. Nothing else is linked:
# Messaging, Auth, Firestore, Storage and RemoteConfig are neither linked nor imported,
# so leaving them reachable would expose e.g. Identity Toolkit to abuse.
ALLOWED_APIS=(
  "firebaseinstallations.googleapis.com"
)

fail() { echo "error: $*" >&2; exit 1; }

command -v gcloud >/dev/null 2>&1 || fail "gcloud not found.

  Install it with:
    brew install --cask gcloud-cli

  If that fails during 'Creating virtualenv' with a pyexpat / libexpat symbol
  error, Homebrew's Python cannot be used (its pyexpat links against the system
  libexpat, which is missing a symbol it needs). Install the CLI standalone and
  point it at a self-contained Python instead:

    curl -L -o /tmp/gcloud.tar.gz \\
      https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz
    tar -xzf /tmp/gcloud.tar.gz -C \"\$HOME\"
    \"\$HOME/google-cloud-sdk/install.sh\" --quiet
    brew install uv && uv python install 3.13
    export CLOUDSDK_PYTHON=\"\$(uv python find 3.13)\"

  Then authenticate:
    gcloud auth login"

[[ -f "$PLIST" ]] || fail "missing $PLIST
  This file is git-ignored; run ./scripts/setup-config.sh first."

PROJECT_ID="$(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "$PLIST" 2>/dev/null || true)"
API_KEY="$(/usr/libexec/PlistBuddy -c 'Print :API_KEY' "$PLIST" 2>/dev/null || true)"
[[ -n "$PROJECT_ID" && -n "$API_KEY" ]] || fail "could not read PROJECT_ID/API_KEY from $PLIST"

echo "project:  $PROJECT_ID"
echo "key:      ${API_KEY:0:6}…${API_KEY: -4}"
echo "bundles:  ${BUNDLE_IDS[*]}"
echo "apis:     ${ALLOWED_APIS[*]}"
echo

# Resolve the key's resource name by matching its keyString. Never echo the full key.
echo "Locating key in project…"
KEY_NAME=""
while read -r name; do
  [[ -z "$name" ]] && continue
  ks="$(gcloud services api-keys get-key-string "$name" --project "$PROJECT_ID" --format='value(keyString)' 2>/dev/null || true)"
  if [[ "$ks" == "$API_KEY" ]]; then KEY_NAME="$name"; break; fi
done < <(gcloud services api-keys list --project "$PROJECT_ID" --format='value(name)' 2>/dev/null)

[[ -n "$KEY_NAME" ]] || fail "no API key in project '$PROJECT_ID' matches the key in the plist.
  Check that you are authenticated as an account with access to this project:
    gcloud auth list"

echo "found:    $KEY_NAME"
echo

ALLOWED_BUNDLE_CSV="$(IFS=,; echo "${BUNDLE_IDS[*]}")"
ALLOWED_API_CSV="$(IFS=,; echo "${ALLOWED_APIS[*]}")"

if ! $APPLY; then
  cat <<EOF
DRY RUN — nothing changed. Would run:

  gcloud services api-keys update "$KEY_NAME" \\
      --project "$PROJECT_ID" \\
      --allowed-bundle-ids="$ALLOWED_BUNDLE_CSV"

  gcloud services api-keys update "$KEY_NAME" \\
      --project "$PROJECT_ID" \\
      --api-target=service=${ALLOWED_APIS[0]}

Re-run with --apply to perform the change.
EOF
  exit 0
fi

echo "Applying iOS bundle restriction…"
gcloud services api-keys update "$KEY_NAME" \
  --project "$PROJECT_ID" \
  --allowed-bundle-ids="$ALLOWED_BUNDLE_CSV"

echo "Applying API restriction…"
gcloud services api-keys update "$KEY_NAME" \
  --project "$PROJECT_ID" \
  --api-target=service="${ALLOWED_APIS[0]}"

echo
echo "Done. Current restrictions:"
gcloud services api-keys describe "$KEY_NAME" --project "$PROJECT_ID" \
  --format='yaml(restrictions)'

cat <<'EOF'

NEXT: verify before trusting it.
  1. Run an edim-dev build, force a test crash, confirm it appears in Crashlytics.
  2. Do the same for a production build.
  3. If reports stop arriving, re-check the bundle-ID list above — a missing entry is
     the usual cause and it fails silently.
EOF
