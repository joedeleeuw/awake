#!/bin/zsh
# Builds a local debug copy of Awake, installs it to ~/Applications and launches it.
# Extra arguments are passed to the app, e.g. ./build.sh --show-panel
set -euo pipefail
cd "${0:A:h}"

xcodegen generate --quiet
xcodebuild -project Awake.xcodeproj -scheme Awake -configuration Debug \
  -derivedDataPath build/dd -allowProvisioningUpdates -quiet build

pkill -x Awake 2>/dev/null || true
rm -rf ~/Applications/Awake.app
mkdir -p ~/Applications
cp -R build/dd/Build/Products/Debug/Awake.app ~/Applications/
open ~/Applications/Awake.app --args "$@"
echo "Installed and launched ~/Applications/Awake.app"
