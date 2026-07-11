# Plan: Replace Notion MCP with Notion REST API

## Status

Planning. Not yet started.

## Context

The app currently uses a custom MCP JSON-RPC client (`notion_mcp_client.dart`) that talks to `https://mcp.notion.com/mcp` for all Notion operations (search, fetch, tool discovery, etc.). OAuth is handled via RFC 7591 dynamic client registration against `mcp.notion.com`.

This plan replaces the entire MCP integration with direct calls to the Notion REST API (`https://api.notion.com/v1/...`) and switches to Notion's public connection OAuth flow.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Tool discovery | Hardcode common tools | REST API has no `tools/list` equivalent. Static tool list is more reliable. |
| OAuth flow | Switch to public integration OAuth | Cleaner long-term. Fixed client_id, no dynamic registration. |
| Credentials storage | `--dart-define-from-file` with `api-keys.json` | Matches project's existing `String.fromEnvironment` pattern. Gitignored. |
| Existing user tokens | Ignore (development phase) | No backward compatibility needed. |
| Page fetch granularity | Two separate tools (`notion_fetch_page` + `notion_get_blocks`) | AI decides when to fetch metadata vs. full content. |
| Page content format | Markdown | LLM-friendly, compact. Requires a renderer. |
| Business plan gating | Remove entirely | Simplifies migration. Old MCP tool names no longer apply. |

## Prerequisite (manual)

Register a public connection at `https://app.notion.com/developers/connections`:

- Name: "Any AI for Notion"
- Type: Public
- Redirect URIs: `http://localhost:0/callback` (desktop), `notionopenai://oauth/callback` (mobile)
- Capabilities: all read + write
- Copy `client_id` and `client_secret` into `api-keys.json`

## Architecture changes

| Area | Current (MCP) | Target (REST API) |
|------|--------------|-----------------|
| Endpoint | `https://mcp.notion.com/mcp` (JSON-RPC 2.0) | `https://api.notion.com/v1/...` (REST) |
| Auth discovery | `mcp.notion.com/.well-known/oauth-protected-resource` + RFC 7591 dynamic registration | Fixed authorization URL + token URL |
| Auth method (token exchange) | Form-encoded `client_id` + `client_secret` | HTTP Basic auth (`base64(client_id:client_secret)`) |
| Auth method (API calls) | `Bearer` token | `Bearer` token (same) |
| Tool discovery | `tools/list` JSON-RPC, dynamic | Hardcoded list in `notion_tool_registry.dart` |
| Tool execution | `tools/call` JSON-RPC, SSE parsing | Direct REST calls to specific endpoints |
| Self identity | `notion-fetch` with `id: 'self'` | `GET /v1/users/me` or from token response |
| Page search | `notion_search` MCP tool | `POST /v1/search` |
| Page fetch | `notion_fetch` MCP tool (combined metadata + content) | `GET /v1/pages/{id}` + `GET /v1/blocks/{id}/children` (two separate tools) |
| Comments | `notion_get_comments` MCP tool | `GET /v1/comments?block_id={id}` |
| Users | `notion_get_users` MCP tool | `GET /v1/users` |
| Schema normalization | Needed (MCP JSON Schema -> OpenAI) | Not needed (schemas hand-written as OpenAI-compatible) |
| Breadcrumbs | Parsed from `<ancestor-path>` in MCP fetch response | Traverse `parent.page_id` chain via repeated `GET /v1/pages/{id}` |
| Session management | MCP session ID, re-initialization | None (stateless REST) |
| SSE parsing | Required for MCP streamable HTTP | Not needed |

## Credentials approach

### `api-keys.json` (gitignored, project root)

```json
{
  "NOTION_CLIENT_ID": "xxx-xxx-xxx",
  "NOTION_CLIENT_SECRET": "secret_xxx"
}
```

### `api-keys.example.json` (committed)

```json
{
  "NOTION_CLIENT_ID": "your-client-id-here",
  "NOTION_CLIENT_SECRET": "your-client-secret-here"
}
```

### Dart usage

```dart
const notionClientId = String.fromEnvironment('NOTION_CLIENT_ID');
const notionClientSecret = String.fromEnvironment('NOTION_CLIENT_SECRET');
```

### Run command

```bash
fvm flutter run --dart-define-from-file=api-keys.json
```

## Files to create

### 1. `lib/features/notion/services/notion_api_client.dart`

Replaces `notion_mcp_client.dart`. `NotionApiClient` class with methods:

- `search(token, query)` -> `POST /v1/search`
- `fetchPage(token, pageId)` -> `GET /v1/pages/{id}`
- `fetchBlockChildren(token, blockId, {cursor})` -> `GET /v1/blocks/{id}/children` (paginated)
- `getComments(token, blockId)` -> `GET /v1/comments?block_id={id}`
- `listUsers(token)` -> `GET /v1/users`
- `getMe(token)` -> `GET /v1/users/me`
- `getDatabase(token, databaseId)` -> `GET /v1/databases/{id}`
- `queryDatabase(token, databaseId, {filter, sorts, cursor})` -> `POST /v1/databases/{id}/query`
- `createPage(token, parent, properties, {children})` -> `POST /v1/pages`
- `updatePage(token, pageId, properties)` -> `PATCH /v1/pages/{id}`
- `appendBlocks(token, blockId, children)` -> `PATCH /v1/blocks/{id}/children`
- `updateBlock(token, blockId, blockContent)` -> `PATCH /v1/blocks/{id}`
- `deleteBlock(token, blockId)` -> `DELETE /v1/blocks/{id}`
- `archivePage(token, pageId, archived)` -> `PATCH /v1/pages/{id}` with `{archived: true/false}`

All requests: `Authorization: Bearer {token}`, `Notion-Version: 2026-03-11`, `Content-Type: application/json`.

Has a `callTool(name, arguments)` dispatcher method that routes tool names to the correct method and returns `NotionToolResult`. This keeps `NotionToolBridge` interface mostly unchanged.

### 2. `lib/features/notion/services/notion_tool_registry.dart`

Static tool registry. Returns `List<NotionToolMeta>` with hand-written OpenAI-compatible schemas (no `$ref`, `anyOf`, `oneOf`, no normalizer needed):

| Tool name | Kind | REST endpoint | Description |
|-----------|------|--------------|-------------|
| `notion_search` | read | `POST /v1/search` | Search for pages and databases in the workspace |
| `notion_fetch_page` | read | `GET /v1/pages/{id}` | Get page metadata, properties, and title |
| `notion_get_blocks` | read | `GET /v1/blocks/{id}/children` | Get the content blocks of a page or block (paginated) |
| `notion_get_comments` | read | `GET /v1/comments?block_id={id}` | Get discussion comments on a page or block |
| `notion_get_users` | read | `GET /v1/users` | List all users in the workspace |
| `notion_get_database` | read | `GET /v1/databases/{id}` | Get database schema and properties |
| `notion_query_database` | read | `POST /v1/databases/{id}/query` | Query database entries with filters and sorts |
| `notion_create_page` | write | `POST /v1/pages` | Create a new page in a database or as a child of another page |
| `notion_update_page` | write | `PATCH /v1/pages/{id}` | Update page properties (title, content, status, etc.) |
| `notion_append_blocks` | write | `PATCH /v1/blocks/{id}/children` | Append content blocks to a page or block |
| `notion_update_block` | write | `PATCH /v1/blocks/{id}` | Update the content of an existing block |
| `notion_delete_block` | write | `DELETE /v1/blocks/{id}` | Delete a block from a page |
| `notion_archive_page` | write | `PATCH /v1/pages/{id}` | Archive or unarchive a page |

### 3. `lib/features/notion/services/notion_page_renderer.dart`

Converts Notion block JSON to markdown for AI consumption. Handles:

- `paragraph` -> plain text
- `heading_1/2/3` -> `#`, `##`, `###`
- `bulleted_list_item` -> `- item`
- `numbered_list_item` -> `1. item`
- `to_do` -> `- [x] item` or `- [ ] item`
- `toggle` -> `<details><summary>text</summary>...</details>`
- `code` -> fenced code block with language
- `quote` -> `> quote`
- `callout` -> blockquote with icon
- `divider` -> `---`
- `image` -> `![alt](url)`
- `bookmark` -> `[url](url)`
- `table` / `table_row` -> markdown table
- `embed` -> `[embed](url)`
- `link_preview` -> `[title](url)`
- Rich text annotations: `**bold**`, `*italic*`, `~~strikethrough~~`, `` `code` ``
- Links: `[text](url)`
- Recursively fetches child blocks for blocks with `has_children: true`

### 4. `api-keys.example.json` (project root, committed)

Placeholder version of `api-keys.json`.

### 5. `.vscode/launch.json` (new)

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["--dart-define-from-file", "api-keys.json"]
    }
  ]
}
```

## Files to modify

### 6. `lib/features/notion/services/notion_oauth_service.dart`

Replace dynamic registration with fixed public OAuth:

- Constants: `_authUrl = 'https://api.notion.com/v1/oauth/authorize'`, `_tokenUrl = 'https://api.notion.com/v1/oauth/token'`
- Read `notionClientId` / `notionClientSecret` from `String.fromEnvironment`
- `start()`: build URL with `client_id`, `redirect_uri`, `response_type=code`, `owner=user`, `state` (CSRF token). No PKCE needed (token exchange uses HTTP Basic auth).
- `handleCallback()`: exchange code via `POST /v1/oauth/token` with HTTP Basic auth header (`base64(client_id:client_secret)`), body `{grant_type: 'authorization_code', code, redirect_uri}`. Parse response for `access_token`, `refresh_token`, `workspace_id`, `workspace_name`, `workspace_icon`, `bot_id`, `owner` (user object with name).
- `refreshAccessToken()`: `POST /v1/oauth/token` with HTTP Basic auth, body `{grant_type: 'refresh_token', refresh_token}`
- Remove `_fetchMetadata()`, `_registerClient()`, `_OAuthMetadata` class, `_RegisteredClient` class, `_notionMcpBase` constant
- `NotionPendingFlow`: remove `clientId`, `clientSecret` fields (now app constants). Keep `state`, `redirectUri`, `startedAt`, `expiresAt`.

### 7. `lib/features/notion/models/notion_tokens.dart`

- Remove `clientId` and `clientSecret` from `NotionTokens` (app-level constants now)
- Add `botId` (String?, from token response)
- `workspace_id` and `workspace_name` populated at connection time from token response
- Update `toJson()` / `fromJson()` / `copyWith()` / `props` accordingly

### 8. `lib/features/notion/models/notion_tool_meta.dart`

- Remove `businessPlanRequiredTools` constant
- Remove `requiresBusinessPlan()` function
- Keep `NotionToolKind` enum and `getToolKind()` (still needed for UI grouping)
- Keep `formatToolName()` (used by UI)

### 9. `lib/features/notion/states/notion_connection_state.dart`

- Remove `businessPlanPrompt` field
- Remove from `copyWith()` and `props`

### 10. `lib/features/notion/providers/notion_connection_notifier.dart`

- Replace `NotionMcpClient` with `NotionApiClient`
- Replace `notionMcpClientProvider` with `notionApiClientProvider`
- `_loadToolsAndIdentity()`: use `NotionToolRegistry.allTools` instead of `_mcp.listTools()`
- `_captureSelfIdentity()`: use `_apiClient.getMe()` instead of `_mcp.fetchSelf()`. Or skip if workspace info already captured from token response.
- Remove all `_mcp.reset()` calls (no session to reset)
- Update `_notionDefaultTools` to match new tool names:
  ```dart
  const _notionDefaultTools = <String>[
    'notion_search',
    'notion_fetch_page',
    'notion_get_blocks',
    'notion_get_comments',
    'notion_get_users',
    'notion_get_database',
  ];
  ```
- Remove all business plan gating logic from `toggleTool()` / `bulkToggleTools()`
- Remove `businessPlanPromptSelector` provider
- Remove `businessPlanPrompt` from state copyWith calls

### 11. `lib/features/notion/services/notion_page_search.dart`

- Replace `NotionMcpClient` with `NotionApiClient`
- `search()`: call `_api.search(token, query)` -> `POST /v1/search`. Parse `results` array for page/database objects.
- `fetchBreadcrumbForPage()`: traverse `parent.page_id` chain via repeated `GET /v1/pages/{id}`. Replaces `<ancestor-path>` parsing.
- Update `notionPageSearchProvider` to use `notionApiClientProvider`
- Update `_mapPage()` to parse Notion REST API page objects (title from `properties.title.title[].plain_text`, icon from `icon.emoji`, url from `url`)

### 12. `lib/features/chat/services/notion_tool_bridge.dart`

- Rename `mcpClient` param to `apiClient`, type `NotionApiClient`
- Update import from `notion_mcp_client.dart` to `notion_api_client.dart`
- `execute()` stays mostly the same since `NotionApiClient.callTool()` has the same interface as `NotionMcpClient.callTool()`

### 13. `lib/features/chat/providers/chat_provider.dart`

- Replace `notionMcpClientProvider` with `notionApiClientProvider` (2 references)
- Replace `NotionToolBridge(mcpClient: ...)` with `NotionToolBridge(apiClient: ...)`
- Remove `requiresBusinessPlan` import and usage from `_defaultEnabledTools()`
- Update `_defaultEnabledTools` default list to match new tool names

### 14. `lib/features/notion/widgets/notion_setup.dart`

- Remove `businessPlanPrompt` selector usage (if any)
- Verify UI still renders correctly with static tool list

### 15. `.gitignore`

- Add `api-keys.json`

## Files to delete

### 16. `lib/features/notion/services/notion_mcp_client.dart`

Fully replaced by `notion_api_client.dart`.

### 17. `lib/features/notion/services/notion_schema_normalizer.dart`

No longer needed (schemas are hand-written as OpenAI-compatible in the tool registry).

## Business plan gating removal

Remove from all files:

- `businessPlanRequiredTools` constant in `notion_tool_meta.dart`
- `requiresBusinessPlan()` function in `notion_tool_meta.dart`
- `businessPlanPrompt` field in `notion_connection_state.dart`
- All gating checks in `notion_connection_notifier.dart` (`toggleTool`, `bulkToggleTools`, `_defaultWhitelist`)
- `businessPlanPromptSelector` provider in `notion_connection_notifier.dart`
- `requiresBusinessPlan` usage in `chat_provider.dart` (`_defaultEnabledTools`)
- Any UI components that show business plan prompts (check `notion_setup.dart`, `notion_tool_list.dart`)

## Hardcoded tool schemas

Each tool in `notion_tool_registry.dart` has a hand-written OpenAI-compatible schema. Example for `notion_search`:

```dart
NotionToolMeta(
  name: 'notion_search',
  description: 'Search for pages and databases in the connected Notion workspace by query.',
  parameters: {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'The search query string.',
      },
      'page_size': {
        'type': 'integer',
        'description': 'Number of results to return (max 100).',
      },
      'start_cursor': {
        'type': 'string',
        'description': 'Pagination cursor from a previous response.',
      },
    },
    'required': ['query'],
  },
)
```

## Page renderer details

The `notion_page_renderer.dart` converts Notion block JSON to markdown. It is used by `NotionApiClient.callTool()` when executing `notion_get_blocks` to return readable content to the AI.

### Block type to markdown mapping

| Block type | Markdown output |
|-----------|----------------|
| `paragraph` | Plain text from `rich_text` |
| `heading_1` | `# text` |
| `heading_2` | `## text` |
| `heading_3` | `### text` |
| `bulleted_list_item` | `- text` |
| `numbered_list_item` | `1. text` |
| `to_do` | `- [x] text` or `- [ ] text` |
| `toggle` | `<details><summary>text</summary>\n{children}</details>` |
| `code` | ` ```language\ncode\n``` ` |
| `quote` | `> text` |
| `callout` | `> {icon} text` |
| `divider` | `---` |
| `image` | `![caption](url)` |
| `bookmark` | `[url](url)` |
| `table` | Markdown table (from `table_row` children) |
| `embed` | `[embed](url)` |
| `link_preview` | `[title](url)` |

### Rich text annotations

| Annotation | Markdown |
|-----------|----------|
| `bold: true` | `**text**` |
| `italic: true` | `*text*` |
| `strikethrough: true` | `~~text~~` |
| `code: true` | `` `text` `` |
| `color` | Ignored (no markdown equivalent) |
| `link` | `[text](url)` |

### Recursive children

For blocks with `has_children: true`, the renderer calls `fetchBlockChildren()` recursively and indents the children under the parent block.

## OAuth flow details

### Authorization URL

```
https://api.notion.com/v1/oauth/authorize?owner=user&client_id={NOTION_CLIENT_ID}&redirect_uri={REDIRECT_URI}&response_type=code&state={STATE}
```

### Token exchange

```
POST https://api.notion.com/v1/oauth/token
Authorization: Basic {base64(client_id:client_secret)}
Content-Type: application/json

{"grant_type":"authorization_code","code":"{code}","redirect_uri":"{redirect_uri}"}
```

### Token response

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "bot_id": "...",
  "duplicated_template_id": null,
  "owner": {"type": "user", "user": {"id": "...", "name": "...", ...}},
  "workspace_icon": "...",
  "workspace_id": "...",
  "workspace_name": "..."
}
```

### Token refresh

```
POST https://api.notion.com/v1/oauth/token
Authorization: Basic {base64(client_id:client_secret)}
Content-Type: application/json

{"grant_type":"refresh_token","refresh_token":"{refresh_token}"}
```

## Execution order

1. Register public connection in Notion developer portal (manual)
2. Create `api-keys.json` + `api-keys.example.json` + update `.gitignore`
3. Create `.vscode/launch.json`
4. Create `notion_api_client.dart`
5. Create `notion_tool_registry.dart`
6. Create `notion_page_renderer.dart`
7. Modify `notion_oauth_service.dart`
8. Modify `notion_tokens.dart`
9. Modify `notion_tool_meta.dart` (remove business plan)
10. Modify `notion_connection_state.dart` (remove businessPlanPrompt)
11. Modify `notion_connection_notifier.dart`
12. Modify `notion_page_search.dart`
13. Modify `notion_tool_bridge.dart`
14. Modify `chat_provider.dart`
15. Modify `notion_setup.dart`
16. Delete `notion_mcp_client.dart` + `notion_schema_normalizer.dart`
17. Run `fvm flutter analyze`
18. Test end-to-end
19. Update this README with results

## Open questions

- How to handle missing `NOTION_CLIENT_ID` / `NOTION_CLIENT_SECRET` (empty `String.fromEnvironment`): show error in settings UI, or fail silently? To be decided during implementation.
- Whether to add PKCE on top of public OAuth for extra security. Notion docs don't mention it for public connections, so skipping for now.