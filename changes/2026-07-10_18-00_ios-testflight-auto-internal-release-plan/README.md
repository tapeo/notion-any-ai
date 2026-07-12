# iOS TestFlight auto-release to internal testing (plan)

## Status

Planning. Implementation pending user go-ahead.

## Goal

After uploading an IPA to TestFlight via `altool`, automatically release the build to the internal testing group via the App Store Connect API, with no manual UI steps.

## Approach

Extend `upload_ios.sh` with App Store Connect API calls that poll build processing, set export compliance, find the internal beta group, and link the build to it.

Only `upload_ios.sh` is modified. No other files change.

## Prerequisites (confirmed by user)

- API key `<API_KEY_ID>` has App Manager or Admin role with access to the app
- `jq` is available for JSON parsing (script will check and print install hint if missing)
- API key file at `~/.private_keys/AuthKey_<API_KEY_ID>.p8`
- Issuer ID already set in the script: `<ISSUER_ID>`

## Script flow (after altool upload)

```
1. Build IPA            (fvm flutter build ipa --release)
2. Upload IPA           (xcrun altool --upload-app)
3. Generate JWT         (openssl ES256, from ~/.private_keys/AuthKey_<API_KEY_ID>.p8)
4. Find App ID          (GET /v1/apps?filter[bundleId]=it.ricu.notionOpenAi)
5. Poll build status    (GET /v1/builds?filter[app]=APP_ID&sort=-uploadedDate&limit=1)
   -> repeat until processingState == VALID (timeout 30 min, poll every 30s)
   -> extract BUILD_ID
6. Export compliance    (PATCH /v1/builds/{BUILD_ID})
   body: usesNonExemptEncryption = false
7. Find internal group  (GET /v1/betaGroups?filter[app]=APP_ID&filter[isInternalGroup]=true)
   -> extract GROUP_ID
8. Add build to group   (POST /v1/builds/{BUILD_ID}/relationships/betaGroups)
   -> 204 No Content = success
9. Print success
```

## JWT signing detail (ES256)

The API key is an EC private key in PKCS#8 format. JWT requires ES256 (ECDSA P-256 SHA-256).

Steps:
1. Build header: `{"alg":"ES256","kid":"<API_KEY_ID>","typ":"JWT"}`
2. Build payload: `{"iss":"<ISSUER_ID>","iat":<now>,"exp":<now+1200>,"aud":"appstoreconnect-v1"}`
3. Base64url-encode both, join with "."
4. Sign with `openssl dgst -sha256 -sign key.p8` (outputs ASN.1 DER)
5. Convert DER signature to raw R (32 bytes) || S (32 bytes):
   - Parse DER SEQUENCE of two INTEGERs
   - Extract R and S hex
   - Strip leading 0x00 padding bytes
   - Pad each to 32 bytes (64 hex chars)
   - Concatenate, base64url-encode (no padding)
6. JWT = `header.payload.signature`

## New script elements

### Variables
- `MAX_WAIT` = 1800 (30 min poll timeout, seconds)
- `POLL_INTERVAL` = 30 (seconds between polls)

### Flags
- `--skip-release` - upload only, skip the API release step

### Functions
- `generate_jwt()` - ES256 JWT from API key, handles DER-to-raw signature conversion
- `api_call()` - curl wrapper with auth header, takes method + URL + optional body
- `wait_for_build()` - polls build processing state until VALID, returns build ID
- `release_to_internal_testing()` - orchestrates steps 3-8

### Pre-flight checks
- `jq` availability (print `brew install jq` hint if missing)
- API key file exists (already present)
- Issuer ID not placeholder (already resolved)

## API endpoints used

| Step | Method | Endpoint | Purpose |
|------|--------|----------|---------|
| 4 | GET | `/v1/apps?filter[bundleId]=it.ricu.notionOpenAi` | Find app resource ID |
| 5 | GET | `/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=1` | Poll latest build, get BUILD_ID |
| 6 | PATCH | `/v1/builds/{BUILD_ID}` | Set `usesNonExemptEncryption: false` |
| 7 | GET | `/v1/betaGroups?filter[app]={APP_ID}&filter[isInternalGroup]=true` | Find internal group ID |
| 8 | POST | `/v1/builds/{BUILD_ID}/relationships/betaGroups` | Link build to internal group |

## Error handling

- Build processing state `INVALID` or `FAILED` -> abort with error message
- Poll timeout (30 min) -> abort with error, suggest checking App Store Connect
- API HTTP errors (4xx/5xx) -> abort with response body
- `jq` missing -> abort with `brew install jq` hint
- `--skip-release` -> skip all API calls, print reminder to release manually

## Dependencies

- `jq` (new, for JSON parsing)
- `openssl` (already available on macOS, for JWT signing)
- `curl` (already available on macOS, for API calls)
- `fvm`, `xcrun altool` (already used in current script)