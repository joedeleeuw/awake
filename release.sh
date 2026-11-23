#!/bin/zsh
# One-command release for Awake.
#
#   ./release.sh 1.1            build, sign, notarize and zip into build/release (nothing published)
#   ./release.sh 1.1 --publish  same, then commit the version bump, tag v1.1, push,
#                               and create a GitHub release with the zip attached
#
# Needs: Xcode signed in to team 73JT8436MP (signs with the team's cloud-managed
# Developer ID certificate), the "awake-notary" notarytool keychain profile,
# xcodegen, and gh (for --publish).
set -euo pipefail
cd "${0:A:h}"

VERSION=${1:?usage: ./release.sh <version> [--publish]}
PUBLISH=${2:-}
PROFILE=awake-notary
OUT=build/release
ZIP="$OUT/Awake-$VERSION.zip"

step() { print -P "%B==> $1%b"; }

if [[ $PUBLISH == --publish ]]; then
  [[ -z $(git status --porcelain) ]] || { echo "Commit or stash your changes first."; exit 1; }
  ! gh release view "v$VERSION" >/dev/null 2>&1 || { echo "v$VERSION is already released."; exit 1; }
fi

step "Version $VERSION"
BUILD=$(( $(sed -nE 's/.*CURRENT_PROJECT_VERSION: "([0-9]+)".*/\1/p' project.yml) + 1 ))
sed -i '' -E "s/(MARKETING_VERSION: )\"[^\"]*\"/\1\"$VERSION\"/" project.yml
sed -i '' -E "s/(CURRENT_PROJECT_VERSION: )\"[0-9]+\"/\1\"$BUILD\"/" project.yml
xcodegen generate --quiet

step "Archive (Apple silicon; macOS 27 has no Intel support)"
rm -rf "$OUT" && mkdir -p "$OUT"
xcodebuild -project Awake.xcodeproj -scheme Awake -configuration Release \
  -destination 'generic/platform=macOS' -archivePath "$OUT/Awake.xcarchive" \
  -allowProvisioningUpdates -quiet archive

step "Sign with Developer ID"
xcodebuild -exportArchive -archivePath "$OUT/Awake.xcarchive" -exportPath "$OUT" \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates -quiet

step "Notarize"
ditto -c -k --keepParent "$OUT/Awake.app" "$OUT/notarize.zip"
RESULT=$(xcrun notarytool submit "$OUT/notarize.zip" --keychain-profile "$PROFILE" --wait --output-format json)
rm -f "$OUT/notarize.zip"
if [[ $RESULT != *'"status":"Accepted"'* ]]; then
  echo "$RESULT"
  ID=$(echo "$RESULT" | sed -nE 's/.*"id":"([^"]+)".*/\1/p')
  [[ -n $ID ]] && xcrun notarytool log "$ID" --keychain-profile "$PROFILE"
  exit 1
fi
xcrun stapler staple -q "$OUT/Awake.app"

step "Verify"
spctl -a -vv "$OUT/Awake.app" 2>&1 | grep -q "Notarized Developer ID" || { spctl -a -vv "$OUT/Awake.app"; exit 1; }
ditto -c -k --keepParent "$OUT/Awake.app" "$ZIP"
echo "Ready: $ZIP"

if [[ $PUBLISH == --publish ]]; then
  step "Publish v$VERSION"
  git commit -qam "chore(release): v$VERSION"
  git tag "v$VERSION"
  git push -q origin HEAD "v$VERSION"
  gh release create "v$VERSION" "$ZIP" --title "Awake $VERSION" --generate-notes
fi
