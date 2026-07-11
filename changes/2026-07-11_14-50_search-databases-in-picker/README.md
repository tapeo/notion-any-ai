# search databases in page picker

## context

The Notion page picker (shown when tapping the attach button in the chat input
bar) only searched for pages. Data sources (databases) returned by the Notion
`/search` endpoint were silently dropped because `NotionPageSearch._extractTitle`
could not parse the data source title shape (top-level `title` array of rich
text items, instead of `properties.title.title` array used by pages).

Under Notion API version `2026-03-11`, the search endpoint returns both `page`
and `data_source` objects. Data source objects have `object: "data_source"` and
`title: [{plain_text: "..."}]` at the top level.

## changes

### `lib/features/notion/models/notion_page_ref.dart`

Added `objectType` field (`'page'` or `'data_source'`) to `NotionPageRef`, plus
`isDataSource` getter. Updated `copyWith`, `toJson`, `fromJson`, `props`.
`fromJson` reads both `object_type` and `object` keys for backward compat.

### `lib/features/notion/services/notion_page_search.dart`

`_extractTitle` now handles the data source title shape: checks the top-level
`title` array of rich text items first (extracts `plain_text` from each),
before falling back to the page `properties` path.

`_mapPage` now reads `item['object']` and passes it as `objectType`.

`fetchBreadcrumbForPage` renamed to `fetchBreadcrumb`. Now accepts a
`NotionPageRef` and resolves breadcrumbs for:
- Data sources: calls `notion_get_database` (data_source_id), then
  `notion_fetch_database` (database_id from parent), then follows the
  page parent chain.
- Pages with `database_id` parent: calls `notion_fetch_database` to get
  the database title, then follows the database's page parent.
- Pages with `data_source_id` parent: calls `notion_get_database`, then
  `notion_fetch_database`, then follows the page parent chain.
- Pages with `page_id` parent: unchanged from before.

Cache key changed from `pageId` to `'${objectType}:${id}'` to avoid
collisions between pages and data sources with the same ID.

New helpers `_walkDatabaseParent` and `_walkPageParent` extracted to
avoid duplication in the different parent traversal paths.

### `lib/features/notion/widgets/notion_page_picker_sheet.dart`

- Title: "Choose a Notion page" -> "Choose a Notion page or database"
- Subtitle: "Add a page to focus on" -> "Add a page or database to focus on"
- Search hint: "Search pages..." -> "Search pages and databases..."
- Empty states: "Type to search your Notion pages." -> "Type to search your
  Notion pages and databases."
- `_PageRow` icon: data sources show `Icons.table_view_outlined`, pages keep
  `Icons.description_outlined`.
- `_resolveBreadcrumbs`: now resolves breadcrumbs for data sources too
  (previously skipped them).

### `lib/features/chat/providers/chat_provider.dart`

`_systemPromptWithPages` now distinguishes pages from data sources in the hint
to the AI. Pages are fetched with `notion_fetch_page`, data sources with
`notion_get_database` or `notion_query_database`.

### `lib/features/chat/widgets/chat_page_selector_row.dart`

Attach button label: "Notion page" -> "Notion". Icon changed from
`Icons.book_outlined` to `Icons.add` to cover both pages and databases.

### `lib/features/notion/services/notion_tool_registry.dart`

`notion_search` tool `filter` enum: added `'data_source'` alongside `'page'`
and `'database'` to match the current API.

`notion_get_database` tool meta: updated description to mention
`data_source_id` param and made `required` empty (either ID works).

New `notion_fetch_database` tool meta: retrieves the raw database object
by `database_id` (title, parent, data_sources list, metadata).

### `backend-any-ai-for-notion/lib/server/notion-tools.ts`

New `notion_fetch_database` case in `callTool` and `fetchDatabase`
function: calls `GET /databases/{database_id}` and returns the raw
database object. Used by the Flutter breadcrumb resolver to get database
titles and parents.

## non-goals

- No pagination support added to the picker (still single page of results).
- No deduplication of data sources vs pages in the picker results.