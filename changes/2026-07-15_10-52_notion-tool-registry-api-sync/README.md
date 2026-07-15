# Expand Notion tool registry to match API reference

## Summary

Aligned `notion_tool_registry.dart` with the Notion API reference
(https://developers.notion.com/reference/intro) and added 9 new tools with
matching backend handlers.

## Files changed

### Flutter (app-any-ai-for-notion)

- `lib/features/notion/services/notion_tool_registry.dart`
  - Rewrote the registry with corrected descriptions and parameters.
  - Centralized the supported block type list and rich_text hint into
    `_blockTypes` / `_richTextHint` constants shared across tools.

### Backend (backend-any-ai-for-notion)

- `lib/server/notion-tools.ts`
  - Added 9 new case branches + handler functions.
  - Updated `search` to accept object filter (in addition to legacy string).
  - Updated `queryDatabase` to forward `filter_properties` as a query array.
  - Updated `updatePage` to make `properties` optional and forward `in_trash`.

## Existing tools fixed

| tool | fix |
| --- | --- |
| notion_search | filter is now an object `{property:"object",value:"page"\|"data_source",in_trash?:boolean}` or `{in_trash:boolean}`. Added `sort` param. |
| notion_query_database | added `is_archived`, `result_type`, `filter_properties`. Noted 10,000 row cap. |
| notion_create_page | parent union now includes `data_source_id` and `workspace`. Added `markdown`, `template`, `allow_async`. Expanded block type list. |
| notion_update_page | `properties` is now optional. Added `in_trash` (bool). |
| notion_update_block | description now documents the block payload body and `in_trash`. |
| notion_append_blocks | expanded supported block types list. |
| notion_delete_block | description clarified (permanent removal). |

## New tools added (registry + backend handler)

1. `notion_get_block` - GET /v1/blocks/{id}
2. `notion_get_page_property` - GET /v1/pages/{page_id}/properties/{property_id}
3. `notion_get_page_markdown` - GET /v1/pages/{id}/markdown
4. `notion_update_page_markdown` - PATCH /v1/pages/{id}/markdown
5. `notion_move_page` - POST /v1/pages/{id}/move
6. `notion_create_database` - POST /v1/databases
7. `notion_update_database` - PATCH /v1/databases/{id}
8. `notion_list_views` - GET /v1/views (database_id or data_source_id query param)
9. `notion_get_view_query_results` - POST /v1/views/{view_id}/queries

## Verification

- `fvm flutter analyze lib/features/notion/services/notion_tool_registry.dart`
  -> No issues found.
- Backend: no node_modules / npm.sh wrapper in the repo; TypeScript
  verification deferred to the containerized environment. Changes were
  reviewed manually for syntax and endpoint correctness against the API
  reference.

## Notes

- `notion_get_view_query_results` exposes the create-view-query flow
  (POST /v1/views/{view_id}/queries) which returns the first page of results
  plus a `query_id`. Paginating beyond the first page would require a
  separate GET /v1/view-queries/{query_id}/results tool, not added in this
  change.
- `notion_update_page_markdown` supports `mode` (insert/replace) and an
  optional `position` anchor object forwarded as-is.
- `notion_query_database` now resolves `database_id` to a data source via
  the existing `resolveDataSourceId` helper, same as before; new optional
  params are forwarded when present.