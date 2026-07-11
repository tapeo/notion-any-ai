# env-refactor-upload-scripts

Refactored `upload_ios.sh` and `upload_snap.sh` to load credentials from a gitignored `.env` file instead of hardcoding them in the scripts.

## Changes

### New files
- `.env` (gitignored) - actual credentials for iOS App Store Connect and Snap Store
- `.env.example` (committed) - placeholder template documenting required env vars

### `.gitignore`
- Added `.env` to ignored files (kept `.env.example` tracked)

### `upload_ios.sh`
- Added `.env` loader with fail-fast if file missing
- `BUNDLE_ID`, `TEAM_ID`, `API_KEY_ID`, `API_ISSUER_ID` now sourced from `IOS_BUNDLE_ID`, `IOS_TEAM_ID`, `IOS_API_KEY_ID`, `IOS_API_ISSUER_ID`
- Replaced placeholder guard with empty-value check on `IOS_API_ISSUER_ID`
- Updated header comment to reference `.env`

### `upload_snap.sh`
- Added `.env` loader with fail-fast if file missing
- `SNAP_STORE_EMAIL`, `SNAP_STORE_PASSWORD` now sourced from env
- Removed "Credentials are embedded below" comment
- VM config (`VM_NAME`, `BASE_IMAGE`, `CPUS`, `MEMORY`, `DISK`, `REMOTE_DIR`) kept hardcoded as non-sensitive infra config

## Env variables

| Variable | Used by | Description |
| --- | --- | --- |
| `IOS_BUNDLE_ID` | upload_ios.sh | iOS app bundle identifier |
| `IOS_TEAM_ID` | upload_ios.sh | Apple Developer Team ID |
| `IOS_API_KEY_ID` | upload_ios.sh | App Store Connect API key ID |
| `IOS_API_ISSUER_ID` | upload_ios.sh | App Store Connect issuer ID |
| `SNAP_STORE_EMAIL` | upload_snap.sh | Snap Store login email |
| `SNAP_STORE_PASSWORD` | upload_snap.sh | Snap Store login password |