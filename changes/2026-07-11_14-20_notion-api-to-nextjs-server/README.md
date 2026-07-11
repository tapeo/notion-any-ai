# Plan: Migrate Notion API from Flutter client to Next.js server

## Status

Planning. Not yet started.

## Context

The Flutter app (`app-any-ai-for-notion`) currently calls the Notion REST API
(`https://api.notion.com/v1`) directly from the client. OAuth credentials
(`NOTION_CLIENT_ID`, `NOTION_CLIENT_SECRET`) are compiled into the app binary
via `String.fromEnvironment`. Access tokens are stored in
`flutter_secure_storage`. All 13 Notion tools run client-side via
`NotionApiClient.callTool`.

This plan moves all Notion API calls and OAuth credential handling to a new
Next.js server at `/Users/matteo/projects/any-ai-for-notion/backend-any-ai-for-notion`.
The server is stateless: no DB, no user accounts, no token persistence. The
Flutter app keeps tokens in `flutter_secure_storage` and sends the access token
per request to the server, which proxies to Notion.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Notion API approach | REST proxy (port existing 13-tool dispatcher) | Same API surface the Flutter app uses today. Smallest rewrite. |
| OAuth flow location | Server-side (client secret on server only) | Removes secret from app binary. Server exchanges code, returns tokens. |
| Token storage | Client-side (`flutter_secure_storage`) | Server is stateless, no DB. App sends access token per request. |
| App auth | Stateless (no app auth) | Backend has no user concept. Flutter sends Notion access token per request. |
| Redirect URI | Single server HTTPS callback | Notion only accepts http/https redirect URIs, not custom schemes. Server callback receives code, exchanges it, redirects tokens to app via `notionopenai://` custom scheme. |
| Server framework | Next.js 16, App Router, TypeScript strict | Latest Next.js. File structure follows sofie-wiki `app/api/` convention. |
| Server deployment | Separate deployment (standalone) | Dev: `http://localhost:3000`. Production: TBD (Vercel or GCloud). |

## Architecture

### OAuth flow (server-side exchange, client-side token storage)

```
1. App ──POST /api/notion-oauth/start──> Server
2. Server generates state JWT, builds authorization_url
3. Server ──{ authorization_url }──> App
4. App opens browser → user authorizes on Notion
5. Notion ──302 https://<server>/api/notion-oauth/callback?code=...&state=<jwt>──> Server
6. Server verifies state JWT, exchanges code (using client_secret), gets tokens
7. Server ──302 notionopenai://oauth/callback?access_token=...&refresh_token=...&...──> App
8. App deep-link handler captures tokens, saves to flutter_secure_storage
```

### API call flow

```
App ──POST /api/notion/tool { access_token, name, arguments }──> Server
Server ──> api.notion.com/v1
Server ──{ content, is_error }──> App
```

### Token refresh flow

```
App ──POST /api/notion-oauth/refresh { refresh_token }──> Server
Server exchanges with Notion (using client_secret)
Server ──{ access_token, refresh_token, access_token_expires_at, ... }──> App
App saves refreshed tokens to flutter_secure_storage
```

## API surface

| Method | Path | Request | Response |
|--------|------|---------|----------|
| `POST` | `/api/notion-oauth/start` | `{}` | `{ authorization_url }` |
| `GET` | `/api/notion-oauth/callback` | query: `code`, `state` | 302 → `notionopenai://oauth/callback?access_token=...&refresh_token=...&access_token_expires_at=...&workspace_id=...&workspace_name=...&user_name=...&bot_id=...&connected_at=...` (or `?error=...&message=...`) |
| `POST` | `/api/notion-oauth/refresh` | `{ refresh_token }` | `NotionTokens` |
| `POST` | `/api/notion/tool` | `{ access_token, name, arguments }` | `NotionToolResult` (`{ content, is_error }`) |
| `GET` | `/api/notion/self` | header `Authorization: Bearer <token>` | `NotionSelfInfo` |
| `GET` | `/api/health` | - | `{ status: "ok" }` |

## Server structure (`backend-any-ai-for-notion`)

Following the sofie-wiki `app/api/` + `lib/server/` convention:

```
backend-any-ai-for-notion/
  package.json
  tsconfig.json
  next.config.ts
  .env.local                  # NOTION_CLIENT_ID, NOTION_CLIENT_SECRET, NOTION_OAUTH_REDIRECT_URI, NOTION_OAUTH_STATE_SECRET
  .env.example
  app/
    api/
      notion-oauth/
        start/route.ts         # POST → { authorization_url }
        callback/route.ts      # GET → 302 redirect to notionopenai://oauth/callback with tokens
        refresh/route.ts       # POST { refresh_token } → NotionTokens
      notion/
        tool/route.ts          # POST { access_token, name, arguments } → NotionToolResult
        self/route.ts          # GET (Authorization: Bearer) → NotionSelfInfo
      health/route.ts          # GET → { status: "ok" }
  lib/
    server/
      notion-client.ts        # fetch helpers, headers, Notion-Version
      notion-tools.ts          # 13-tool dispatcher (switch on tool name)
      notion-markdown.ts       # port of notion_page_renderer.dart
      notion-oauth.ts          # state JWT sign/verify, token exchange, refresh
      types.ts                 # NotionToolResult, NotionSelfInfo, NotionTokens
    shared/
      config.ts                # reads NOTION_* env vars
```

### Route conventions (from sofie-wiki reference)

- Route files are always `route.ts`, exporting named HTTP verbs (`GET`, `POST`, etc.)
- `NextResponse.json(...)` for all responses
- Dynamic params are a Promise (Next.js 15+ App Router), awaited in handler
- No middleware/HOCs needed (stateless, no auth, no DB)
- Validation is manual (typeof checks, param presence), no zod
- Error responses: `{ error: string }` with appropriate HTTP status

## Server implementation details

### `lib/shared/config.ts`

Reads from `process.env`:
- `NOTION_CLIENT_ID`
- `NOTION_CLIENT_SECRET`
- `NOTION_OAUTH_REDIRECT_URI` - `https://<server-domain>/api/notion-oauth/callback`
- `NOTION_OAUTH_STATE_SECRET` - random secret for state JWT signing

### `lib/server/types.ts`

```ts
interface NotionToolResult {
  content: string;
  is_error: boolean;
}

interface NotionSelfInfo {
  workspace_id: string | null;
  workspace_name: string | null;
  user_name: string | null;
}

interface NotionTokens {
  access_token: string;
  refresh_token: string;
  access_token_expires_at: number;  // ms epoch
  workspace_id: string | null;
  workspace_name: string | null;
  user_name: string | null;
  bot_id: string | null;
  connected_at: number;  // ms epoch
}
```

### `lib/server/notion-client.ts`

Fetch-based HTTP helpers (no external HTTP library). Headers:
- `Authorization: Bearer <token>`
- `Notion-Version: 2026-03-11`
- `Content-Type: application/json`

Methods:
- `get(path, params?)` → `{ success, status, body }`
- `post(path, body)` → `{ success, status, body }`
- `patch(path, body)` → `{ success, status, body }`
- `delete(path)` → `{ success, status, body }`

Base URL: `https://api.notion.com/v1`

### `lib/server/notion-tools.ts`

The 13-tool switch from `notion_api_client.dart` translated to TypeScript.
Same param validation, same error messages, same JSON pretty-printing.

Tools (exact same names as Flutter app):

| Tool name | Notion endpoint | Method |
|-----------|----------------|--------|
| `notion_search` | `/search` | POST |
| `notion_fetch_page` | `/pages/{pageId}` | GET |
| `notion_get_blocks` | `/blocks/{blockId}/children` or markdown render | GET |
| `notion_get_comments` | `/comments?block_id={id}` | GET |
| `notion_get_users` | `/users` | GET |
| `notion_get_database` | `/databases/{databaseId}` | GET |
| `notion_query_database` | `/databases/{databaseId}/query` | POST |
| `notion_create_page` | `/pages` | POST |
| `notion_update_page` | `/pages/{pageId}` | PATCH |
| `notion_append_blocks` | `/blocks/{blockId}/children` | PATCH |
| `notion_update_block` | `/blocks/{blockId}` | PATCH |
| `notion_delete_block` | `/blocks/{blockId}` | DELETE |
| `notion_archive_page` | `/pages/{pageId}` with `{ archived }` | PATCH |

For `notion_get_blocks` with `as_markdown: true` (default), calls
`notion-markdown.ts` to render blocks to markdown.

### `lib/server/notion-markdown.ts`

Direct port of `notion_page_renderer.dart`. Recursive block fetching with
pagination (`page_size=100`), all block types:

| Block type | Markdown output |
|-----------|----------------|
| `paragraph` | Plain text from `rich_text` |
| `heading_1` | `# text` |
| `heading_2` | `## text` |
| `heading_3` | `### text` |
| `bulleted_list_item` | `- text` |
| `numbered_list_item` | `1. text` |
| `to_do` | `- [x] text` or `- [ ] text` |
| `toggle` | `<details><summary>text</summary>` |
| `code` | ` ```language\ncode\n``` ` |
| `quote` | `> text` |
| `callout` | `> {icon} text` |
| `divider` | `---` |
| `image` | `![caption](url)` |
| `bookmark` | `[caption](url)` |
| `embed` | `[embed](url)` |
| `link_preview` | `[link preview](url)` |
| `video` | `[video](url)` |
| `audio` | `[audio](url)` |
| `pdf` | `[pdf](url)` |
| `table` | `[table]` |
| `table_row` | `\| cell1 \| cell2 \|` |
| `column_list` / `column` | (empty) |
| `synced_block` | (empty) |

Rich text annotations:
- `bold: true` → `**text**`
- `italic: true` → `*text*`
- `strikethrough: true` → `~~text~~`
- `code: true` → `` `text` ``
- `href` → `[text](url)`

Mentions:
- `mention.type == 'page'` → `[page: {id}]`
- `mention.type == 'user'` → `@{name}`
- `mention.type == 'database'` → `[database: {id}]`

Equations: `$$expression$`

Recursive children: for blocks with `has_children: true`, fetches children
recursively with indentation.

### `lib/server/notion-oauth.ts`

- `startAuth()`: generate state (random hex), sign state JWT with
  `NOTION_OAUTH_STATE_SECRET`, build authorization URL:
  ```
  https://api.notion.com/v1/oauth/authorize?client_id={ID}&redirect_uri={REDIRECT_URI}&response_type=code&owner=user&state={JWT}
  ```
- `handleCallback(stateJwt, code)`: verify state JWT, exchange code via
  `POST https://api.notion.com/v1/oauth/token` with HTTP Basic auth
  (`base64(client_id:client_secret)`), body:
  `{ grant_type: "authorization_code", code, redirect_uri }`. Parse response
  for `access_token`, `refresh_token`, `expires_in`, `workspace_id`,
  `workspace_name`, `workspace_icon`, `bot_id`, `owner` (user object with name).
- `refreshAccessToken(refreshToken)`: `POST /v1/oauth/token` with HTTP Basic
  auth, body: `{ grant_type: "refresh_token", refresh_token }`. Parse and
  return refreshed tokens.

## Token delivery via redirect

The server callback redirects to:

```
notionopenai://oauth/callback?access_token=<token>&refresh_token=<token>&access_token_expires_at=<ms>&workspace_id=<id>&workspace_name=<name>&user_name=<name>&bot_id=<id>&connected_at=<ms>
```

On error:

```
notionopenai://oauth/callback?error=<code>&message=<msg>
```

The app's existing deep-link handler captures `notionopenai://oauth/callback`.
It will parse the new token params instead of `code`/`state`.

## Flutter changes

### Files to modify

| File | Change |
|------|--------|
| `lib/features/notion/services/notion_api_client.dart` | Rewrite `callTool` to POST to `${BACKEND_URL}/api/notion/tool` with `{ access_token, name, arguments }`. Delete all direct Notion HTTP helpers (`_get/_post/_patch/_delete`, `_headers`, `_missingParam`, `_errorResponse`, `_prettyJson`, `_ApiResponse`). `fetchSelf` calls `${BACKEND_URL}/api/notion/self` with Authorization header. Keep `NotionToolResult` and `NotionSelfInfo` classes. Keep `callTool` signature identical. |
| `lib/features/notion/services/notion_oauth_service.dart` | Rewrite: `start()` → POST `/api/notion-oauth/start` returns `{ authorization_url }`. Remove `handleCallback` (replaced by deep-link token parsing). `refreshAccessToken()` → POST `/api/notion-oauth/refresh` with `{ refresh_token }`. Remove all `api.notion.com` calls, `_basicAuthHeader`, `_parseTokenResponse`, `_generateState`, state generation. Remove `notionClientId`/`notionClientSecret` constants. Keep `NotionOAuthError`, `NotionStartResult`. `ensureValidToken` stays (calls rewritten `refreshAccessToken`). |
| `lib/features/notion/providers/notion_connection_notifier.dart` | `connect()` simplified: no loopback server branch, just call `_oauth.start()` and open URL. `handleCallback(code, state)` → `handleCallbackTokens(NotionTokens tokens)`: parse tokens from deep-link query params, save to storage. Remove `_awaitLoopbackCallback`, `_stopLoopbackServer`, `_loopbackServer`. Remove `NotionPendingFlow` usage. `_loadToolsAndIdentity` stays same (uses `validAccessToken`). `_captureSelfIdentity` calls `_api.fetchSelf` with the access token. |
| `lib/features/notion/services/notion_storage.dart` | Remove `loadPending`/`savePending`/`clearPending` methods (no pending flow on client). Remove `NotionPendingFlow` references. Keep token, enabled, enabledTools storage. |
| `lib/features/notion/models/notion_tokens.dart` | Remove `NotionPendingFlow` class entirely. `NotionTokens` stays unchanged. |
| `lib/main.dart` | Deep-link handler parses `notionopenai://oauth/callback?access_token=...&refresh_token=...` as tokens, calls `handleCallbackTokens`. Remove `code`/`state` parsing. Add `BACKEND_URL` env var. |
| `pubspec.yaml` | Remove `NOTION_CLIENT_ID`/`NOTION_CLIENT_SECRET` compile args (from `--dart-define-from-file`). Add `BACKEND_URL` (default `http://localhost:3000`). |
| `api-keys.example.json` | Remove `NOTION_CLIENT_ID`/`NOTION_CLIENT_SECRET`. Add `BACKEND_URL`. |

### Files to delete

| File | Reason |
|------|--------|
| `lib/features/notion/services/notion_page_renderer.dart` | Logic moves to server `notion-markdown.ts`. |
| `lib/features/notion/services/notion_loopback_server.dart` | No longer needed. Server HTTPS callback replaces desktop loopback. |

### Files with no changes

| File | Reason |
|------|--------|
| `lib/features/chat/services/notion_tool_bridge.dart` | Uses `NotionApiClient.callTool` unchanged signature. |
| `lib/features/notion/services/notion_page_search.dart` | Uses `callTool` unchanged. |
| `lib/features/notion/services/notion_tool_registry.dart` | Static tool metadata, no API calls. |
| `lib/features/notion/models/notion_tool_meta.dart` | Pure metadata. |
| `lib/features/notion/widgets/notion_setup.dart` | Watches `notionConnectionProvider`, calls `connect`/`disconnect`. |
| `lib/features/notion/widgets/notion_tool_list.dart` | Toggles tools via notifier. |
| `lib/features/notion/widgets/notion_page_picker_sheet.dart` | Uses `notionPageSearchProvider`. |
| `lib/features/chat/providers/chat_provider.dart` | Uses `validAccessToken` + `NotionToolBridge`. |

## Env vars

### Server (`.env.local`)

```
NOTION_CLIENT_ID=<from current api-keys.json>
NOTION_CLIENT_SECRET=<from current api-keys.json>
NOTION_OAUTH_REDIRECT_URI=https://<server-domain>/api/notion-oauth/callback
NOTION_OAUTH_STATE_SECRET=<random 32+ char string>
```

### Server (`.env.example`)

```
NOTION_CLIENT_ID=your-client-id-here
NOTION_CLIENT_SECRET=your-client-secret-here
NOTION_OAUTH_REDIRECT_URI=https://your-server-domain/api/notion-oauth/callback
NOTION_OAUTH_STATE_SECRET=generate-a-random-secret
```

### Flutter app (compile-time `String.fromEnvironment`)

```
BACKEND_URL=http://localhost:3000   # dev default
```

### Flutter app (`api-keys.example.json`)

```json
{
  "BACKEND_URL": "http://localhost:3000"
}
```

## Migration phases

### Phase 1: Scaffold server

1. Create Next.js 16 project at `backend-any-ai-for-notion`
2. Install deps (only Next.js itself, fetch is built-in)
3. Create folder structure, `tsconfig.json`, `next.config.ts`, `.env.example`
4. Create `lib/shared/config.ts`, `lib/server/types.ts`

### Phase 2: Port Notion client

5. Implement `lib/server/notion-client.ts` (HTTP helpers, headers)
6. Implement `lib/server/notion-tools.ts` (13-tool dispatcher)
7. Test against mock Notion API responses

### Phase 3: Port markdown renderer

8. Implement `lib/server/notion-markdown.ts` (port of `notion_page_renderer.dart`)
9. Include recursive block fetching, pagination, all block types

### Phase 4: Wire routes

10. `app/api/health/route.ts`
11. `app/api/notion/tool/route.ts`
12. `app/api/notion/self/route.ts`
13. `app/api/notion-oauth/start/route.ts`
14. `app/api/notion-oauth/callback/route.ts`
15. `app/api/notion-oauth/refresh/route.ts`

### Phase 5: Test server standalone

16. Start server, test with curl against a real Notion workspace
17. Verify: start OAuth, callback exchange, tool calls, markdown rendering, refresh

### Phase 6: Rewrite Flutter client

18. Rewrite `notion_api_client.dart` (callTool → server POST, fetchSelf → server GET)
19. Rewrite `notion_oauth_service.dart` (start → server, refresh → server)
20. Update `notion_connection_notifier.dart` (remove loopback, update callback handling)
21. Update `notion_storage.dart` (remove pending flow methods)
22. Update `notion_tokens.dart` (remove `NotionPendingFlow`)
23. Update `main.dart` (deep-link token parsing, add `BACKEND_URL`)
24. Delete `notion_page_renderer.dart`
25. Delete `notion_loopback_server.dart`
26. Update `pubspec.yaml`, `api-keys.example.json`

### Phase 7: Integration test

27. Full Flutter flow: connect, search, fetch page, get blocks as markdown, create page, append blocks, refresh token
28. Test on mobile (iOS/Android) and desktop (macOS)

### Phase 8: Cleanup

29. Remove `NOTION_CLIENT_ID`/`NOTION_CLIENT_SECRET` from Flutter compile args
30. Update `notion_api.md` docs
31. Update this README with results

## Prerequisite (manual)

Register or update the public connection at
`https://app.notion.com/developers/connections`:

- Name: "Any AI for Notion"
- Type: Public
- Redirect URIs: `https://<server-domain>/api/notion-oauth/callback` (single URI)
- Capabilities: all read + write
- Copy `client_id` and `client_secret` into server `.env.local`

## Open items

- Production server domain and deployment target (Vercel vs GCloud) to be
  decided before registering the redirect URI with Notion.
- The existing `INSTALL_BACKEND_URL` GCloud backend (used for `/install` and
  `/feedback`) is unrelated and will not be touched.
- Whether to keep `NOTION_CLIENT_ID`/`NOTION_CLIENT_SECRET` in
  `api-keys.json` for the Flutter app during a transition period (not needed
  if server is deployed before app changes ship).