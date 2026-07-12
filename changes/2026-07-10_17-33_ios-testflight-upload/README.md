# iOS TestFlight upload script

## Summary

Added `upload_ios.sh` to build and upload the Flutter iOS app to TestFlight, mirroring the existing `upload_snap.sh` style.

## What was added

- `upload_ios.sh` at project root (gitignored, same as `upload_snap.sh`)

## How it works

1. Runs `fvm flutter build ipa --release` to produce an `.xcarchive` and `.ipa`
2. Uploads to TestFlight via `xcrun xcodebuild -exportArchive` with `destination=upload`
3. Authenticates using the App Store Connect API key at `~/.private_keys/AuthKey_<API_KEY_ID>.p8`

## Usage

```bash
./upload_ios.sh                  # build + upload to TestFlight
./upload_ios.sh --build-only     # build IPA, skip upload
./upload_ios.sh --skip-build     # upload existing archive
```

## Before first run

1. Set `API_ISSUER_ID` in the script to the App Store Connect issuer ID (App Store Connect > Users and Access > Keys > top-right "Issuer ID")
2. Ensure an Apple Distribution certificate for team `<TEAM_ID>` exists in keychain (Xcode > Settings > Accounts > Manage Certificates)
3. Ensure the app record exists in App Store Connect for bundle ID `it.ricu.notionOpenAi`

## Details

- Bundle ID: `it.ricu.notionOpenAi`
- Team ID: `<TEAM_ID>`
- API key ID: `<API_KEY_ID>`
- ExportOptions.plist is generated as a temp file (no permanent file in repo)
- Script validates API key existence and issuer ID before attempting upload