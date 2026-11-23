# Awake

A small menu-bar app that keeps your Mac awake.

Click the cup in the menu bar and choose the moon (sleep normally) or the cup
(stay awake). Right-click the cup for Open at Login and Quit.

No network access, no updater, no tracking. It holds the same power assertion
as Apple's `caffeinate -d`, and that's all.

Requires macOS 27. Download the latest zip from [Releases](../../releases).
Design notes are in [STYLEGUIDE.md](STYLEGUIDE.md).

## Build

```sh
brew install xcodegen
./build.sh                    # debug build, installs to ~/Applications and launches
swift tools/make-icon.swift   # regenerate the app icon
```

## Release

```sh
./release.sh 1.1             # build, sign, notarize, zip into build/release
./release.sh 1.1 --publish   # ...then tag, push and publish a GitHub release
```

Releases are signed with the team's Developer ID certificate (cloud-managed, via
Xcode's signed-in account) and notarized with the `awake-notary` keychain profile:

```sh
xcrun notarytool store-credentials awake-notary --key <AuthKey.p8> --key-id <id> --issuer <issuer>
```
