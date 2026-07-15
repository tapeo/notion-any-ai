import '../models/notion_tool_meta.dart';

class NotionToolRegistry {
  const NotionToolRegistry._();

  static const _blockTypes =
      'paragraph, heading_1, heading_2, heading_3, heading_4, '
      'bulleted_list_item, numbered_list_item, to_do, toggle, code, callout, '
      'quote, divider, table_of_contents, breadcrumb, embed, bookmark, image, '
      'video, pdf, file, audio, table, table_row, column_list, column, '
      'equation, link_to_page, synced_block, meeting_notes, tab';

  static const _richTextHint =
      'Keep rich_text items minimal '
      '({"type":"text","text":{"content":"..."}}).';

  static const allTools = <NotionToolMeta>[
    NotionToolMeta(
      name: 'notion_search',
      description:
          'Search for pages and data sources in the connected Notion '
          'workspace by title or content. Returns all pages and data sources '
          'shared with the connection when query is empty.',
      parameters: {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The search query string.',
          },
          'filter': {
            'type': 'object',
            'description':
                'Optional filter. Either {"property":"object",'
                '"value":"page"|"data_source","in_trash":boolean} to limit '
                'by object type, or {"in_trash":boolean} to search only '
                'trashed or non-trashed items.',
          },
          'sort': {
            'type': 'object',
            'description':
                'Sort criteria. Either {"direction":"ascending"|'
                '"descending","timestamp":"last_edited_time"} or '
                '{"property":"relevance"}.',
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
    ),
    NotionToolMeta(
      name: 'notion_fetch_page',
      description:
          'Retrieve a Notion page by ID, including its properties '
          '(title, status, etc.), parent, icon, cover, and metadata.',
      parameters: {
        'type': 'object',
        'properties': {
          'page_id': {
            'type': 'string',
            'description': 'The ID of the Notion page to fetch.',
          },
        },
        'required': ['page_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_get_blocks',
      description:
          'Retrieve the content blocks of a Notion page or block. '
          'Returns rendered markdown by default, or raw JSON blocks if '
          'as_markdown is set to false.',
      parameters: {
        'type': 'object',
        'properties': {
          'block_id': {
            'type': 'string',
            'description':
                'The ID of the block or page whose children to '
                'retrieve.',
          },
          'as_markdown': {
            'type': 'boolean',
            'description':
                'If true (default), returns content as markdown. '
                'If false, returns raw JSON blocks.',
          },
          'page_size': {
            'type': 'integer',
            'description':
                'Number of blocks per page (max 100, only used '
                'when as_markdown is false).',
          },
          'start_cursor': {
            'type': 'string',
            'description':
                'Pagination cursor (only used when as_markdown is '
                'false).',
          },
        },
        'required': ['block_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_get_block',
      description:
          'Retrieve a single Notion block by ID, including its type '
          'payload, parent, and metadata. Use this to inspect one block '
          'rather than listing all children.',
      parameters: {
        'type': 'object',
        'properties': {
          'block_id': {
            'type': 'string',
            'description': 'The ID of the block to retrieve.',
          },
        },
        'required': ['block_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_get_page_property',
      description:
          'Retrieve a single page property item by page ID and property '
          'ID. Paginated for array properties (title, rich_text, people, '
          'relation). Use this to fetch large properties without '
          're-fetching the whole page.',
      parameters: {
        'type': 'object',
        'properties': {
          'page_id': {
            'type': 'string',
            'description': 'The ID of the page.',
          },
          'property_id': {
            'type': 'string',
            'description': 'The ID of the property to retrieve.',
          },
          'page_size': {
            'type': 'integer',
            'description': 'Number of items per page (max 100).',
          },
          'start_cursor': {
            'type': 'string',
            'description': 'Pagination cursor from a previous response.',
          },
        },
        'required': ['page_id', 'property_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_get_page_markdown',
      description:
          'Retrieve the full content of a Notion page rendered as '
          'enhanced markdown. Simpler and more compact than the block API. '
          'May include <unknown> tags for unsupported or inaccessible '
          'blocks; pass those block IDs back as page_id to fetch subtrees. '
          'Returns truncated=true and unknown_block_ids when the page '
          'exceeds ~20,000 blocks.',
      parameters: {
        'type': 'object',
        'properties': {
          'page_id': {
            'type': 'string',
            'description':
                'The ID of the page (or non-navigable block ID from a '
                'truncated response) to retrieve as markdown.',
          },
          'include_transcript': {
            'type': 'boolean',
            'description':
                'Whether to include meeting note transcripts. '
                'Defaults to false.',
          },
        },
        'required': ['page_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_update_page_markdown',
      description:
          'Insert or replace content in a Notion page using enhanced '
          'markdown. Mutually exclusive with the block children API. '
          'Supports insert (append after existing content) and replace '
          '(overwrite all content) modes, with optional position anchors.',
      parameters: {
        'type': 'object',
        'properties': {
          'page_id': {
            'type': 'string',
            'description': 'The ID of the page to update.',
          },
          'markdown': {
            'type': 'string',
            'description':
                'The enhanced markdown content. Newlines must be '
                'encoded as \\n in the JSON string.',
          },
          'mode': {
            'type': 'string',
            'enum': ['insert', 'replace'],
            'description':
                'insert appends after existing content (default). '
                'replace overwrites all page content.',
          },
          'position': {
            'type': 'object',
            'description':
                'Optional position anchor. See Notion markdown update '
                'docs for the position object shape.',
          },
        },
        'required': ['page_id', 'markdown'],
      },
    ),
    NotionToolMeta(
      name: 'notion_get_comments',
      description:
          'Retrieve discussion comments on a Notion page or block.',
      parameters: {
        'type': 'object',
        'properties': {
          'block_id': {
            'type': 'string',
            'description': 'The ID of the block or page to get comments for.',
          },
          'page_size': {
            'type': 'integer',
            'description': 'Number of comments to return (max 100).',
          },
          'start_cursor': {
            'type': 'string',
            'description': 'Pagination cursor from a previous response.',
          },
        },
        'required': ['block_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_get_users',
      description: 'List all users in the connected Notion workspace.',
      parameters: {
        'type': 'object',
        'properties': {
          'page_size': {
            'type': 'integer',
            'description': 'Number of users to return (max 100).',
          },
          'start_cursor': {
            'type': 'string',
            'description': 'Pagination cursor from a previous response.',
          },
        },
        'required': [],
      },
    ),
    NotionToolMeta(
      name: 'notion_get_database',
      description:
          'Retrieve a Notion data source by ID (pass either '
          'database_id or data_source_id), including its properties schema, '
          'title, parent, and metadata.',
      parameters: {
        'type': 'object',
        'properties': {
          'database_id': {
            'type': 'string',
            'description':
                'The ID of the Notion database. The single '
                'data source under it is resolved automatically.',
          },
          'data_source_id': {
            'type': 'string',
            'description': 'The ID of the data source to fetch directly.',
          },
        },
        'required': [],
      },
    ),
    NotionToolMeta(
      name: 'notion_fetch_database',
      description:
          'Retrieve the raw Notion database object by ID, including '
          'its title, parent, data sources list, and metadata. Use this to '
          'read the database itself (not the data source schema).',
      parameters: {
        'type': 'object',
        'properties': {
          'database_id': {
            'type': 'string',
            'description': 'The ID of the Notion database to fetch.',
          },
        },
        'required': ['database_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_create_database',
      description:
          'Create a new Notion database (and its initial data source) '
          'under an existing page. Provide a title, an icon, a cover, and a '
          'properties schema mapping property names to property type objects. '
          'The parent must be a page_id. Returns the new database object.',
      parameters: {
        'type': 'object',
        'properties': {
          'parent': {
            'type': 'object',
            'description':
                'The parent of the new database. Must be '
                '{"type":"page_id","page_id":"..."}.',
          },
          'title': {
            'type': 'array',
            'items': {'type': 'object'},
            'description': 'The database title as rich text.',
          },
          'properties': {
            'type': 'object',
            'description':
                'The database properties schema. Keys are property '
                'names, values are property type objects, e.g. '
                '{"Name":{"title":{}},"Status":{"select":'
                '{"options":[{"name":"Todo","color":"gray"}]}}}.',
          },
          'icon': {
            'type': 'object',
            'description': 'An icon object for the database.',
          },
          'cover': {
            'type': 'object',
            'description': 'A cover image object for the database.',
          },
          'description': {
            'type': 'array',
            'items': {'type': 'object'},
            'description': 'The database description as rich text.',
          },
        },
        'required': ['parent', 'title', 'properties'],
      },
    ),
    NotionToolMeta(
      name: 'notion_update_database',
      description:
          'Update the attributes of a Notion database: title, '
          'description, icon, cover, and/or the properties schema. Pass only '
          'the fields you want to change. Properties updates merge into the '
          'existing schema.',
      parameters: {
        'type': 'object',
        'properties': {
          'database_id': {
            'type': 'string',
            'description': 'The ID of the database to update.',
          },
          'title': {
            'type': 'array',
            'items': {'type': 'object'},
            'description': 'The new database title as rich text.',
          },
          'description': {
            'type': 'array',
            'items': {'type': 'object'},
            'description': 'The new database description as rich text.',
          },
          'properties': {
            'type': 'object',
            'description':
                'Property schema updates. Keys are property names, '
                'values are property type objects. Merges with the existing '
                'schema.',
          },
          'icon': {
            'type': 'object',
            'description': 'A new icon object.',
          },
          'cover': {
            'type': 'object',
            'description': 'A new cover image object.',
          },
        },
        'required': ['database_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_query_database',
      description:
          'Query a Notion database (via its data source) to retrieve its '
          'entries (pages) with optional filters and sorts. Supports up to '
          '10,000 results per query; check request_status.type for '
          '"incomplete" when capped. Use filter_properties to return only '
          'the properties you need for faster responses.',
      parameters: {
        'type': 'object',
        'properties': {
          'database_id': {
            'type': 'string',
            'description':
                'The ID of the database to query. The single data '
                'source under it is resolved automatically.',
          },
          'data_source_id': {
            'type': 'string',
            'description': 'The ID of the data source to query directly.',
          },
          'filter': {
            'type': 'object',
            'description':
                'Filter criteria to narrow down results. See '
                'Notion API filter documentation for the structure.',
          },
          'sorts': {
            'type': 'array',
            'items': {'type': 'object'},
            'description': 'Sort criteria for the results.',
          },
          'filter_properties': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                'Property names or IDs to include in the response '
                '(reduces payload size). Passed as repeated query params.',
          },
          'is_archived': {
            'type': 'boolean',
            'description':
                'When true, returns archived pages. When false or '
                'omitted, returns non-archived pages.',
          },
          'result_type': {
            'type': 'string',
            'enum': ['page', 'data_source'],
            'description':
                'For wikis, filter results to only pages or only '
                'data sources. Ignored for regular databases.',
          },
          'page_size': {
            'type': 'integer',
            'description': 'Number of results per page (max 100).',
          },
          'start_cursor': {
            'type': 'string',
            'description': 'Pagination cursor from a previous response.',
          },
        },
        'required': [],
      },
    ),
    NotionToolMeta(
      name: 'notion_list_views',
      description:
          'List all views in a Notion database. Pass either database_id '
          'or data_source_id. Returns view references (id only); use '
          'notion_get_view_query_results to run a view\'s query.',
      parameters: {
        'type': 'object',
        'properties': {
          'database_id': {
            'type': 'string',
            'description': 'The ID of the database to list views for.',
          },
          'data_source_id': {
            'type': 'string',
            'description':
                'The ID of a data source to list all views for, '
                'including linked views across the workspace.',
          },
          'page_size': {
            'type': 'integer',
            'description': 'Number of views to return (max 100).',
          },
          'start_cursor': {
            'type': 'string',
            'description': 'Pagination cursor from a previous response.',
          },
        },
        'required': [],
      },
    ),
    NotionToolMeta(
      name: 'notion_get_view_query_results',
      description:
          'Execute a database view\'s filter and sort configuration and '
          'return the first page of results, plus a query_id for paginating. '
          'Cached results expire after 15 minutes. Supports up to 10,000 '
          'results per query (check request_status.type for "incomplete").',
      parameters: {
        'type': 'object',
        'properties': {
          'view_id': {
            'type': 'string',
            'description': 'The ID of the view to query.',
          },
          'page_size': {
            'type': 'integer',
            'description': 'Number of results per page (max 100).',
          },
        },
        'required': ['view_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_create_page',
      description:
          'Create a new page in a Notion database or as a child of '
          'another page. Optional `children` adds content blocks to the '
          'new page. Each item in `children` is a block object with a '
          '`type` field and a same-named payload. Supported block types: '
          '$_blockTypes. For nested blocks (table, column_list, and any '
          'block carrying a `children` array), keep `children` minimal '
          'and prefer appending complex blocks via notion_append_blocks '
          'in separate calls. A table block has the shape '
          '{"type":"table","table":{"table_width":N,'
          '"has_column_header":true,"children":[{"type":"table_row",'
          '"table_row":{"cells":[[{"type":"text","text":{"content":"..."}}]]}}]}}. '
          '$_richTextHint Alternatively, pass `markdown` to write content as '
          'enhanced markdown (mutually exclusive with children). The '
          '`template` parameter applies an existing data source template. '
          'For page parents, `properties` only accepts a title.',
      parameters: {
        'type': 'object',
        'properties': {
          'parent': {
            'type': 'object',
            'description':
                'The parent of the new page. One of '
                '{"type":"page_id","page_id":"..."}, '
                '{"type":"database_id","database_id":"..."}, '
                '{"type":"data_source_id","data_source_id":"..."}, or '
                '{"type":"workspace","workspace":true} (workspace only for '
                'public connections and personal access tokens).',
          },
          'properties': {
            'type': 'object',
            'description':
                'The page properties. Keys are property names, '
                'values depend on the property type.',
          },
          'children': {
            'type': 'array',
            'items': {'type': 'object'},
            'description': 'Content blocks to add to the new page.',
          },
          'markdown': {
            'type': 'string',
            'description':
                'Page content as enhanced markdown. Mutually '
                'exclusive with children. Newlines must be encoded as \\n.',
          },
          'template': {
            'type': 'object',
            'description':
                'Apply a data source template. Either '
                '{"type":"none"}, {"type":"default","timezone":"..."}, or '
                '{"type":"template_id","template_id":"...",'
                '"timezone":"..."}. When set, children is not allowed.',
          },
          'allow_async': {
            'type': 'boolean',
            'description':
                'When using markdown, set true to receive an '
                'async_task response instead of waiting synchronously.',
          },
          'icon': {
            'type': 'object',
            'description': 'An icon object for the page.',
          },
          'cover': {
            'type': 'object',
            'description': 'A cover image object for the page.',
          },
        },
        'required': ['parent', 'properties'],
      },
    ),
    NotionToolMeta(
      name: 'notion_update_page',
      description:
          'Update the properties of an existing Notion page. Pass '
          'properties, icon, cover, archived, or in_trash as needed. '
          'Properties keys are property names; values depend on the '
          'property type.',
      parameters: {
        'type': 'object',
        'properties': {
          'page_id': {
            'type': 'string',
            'description': 'The ID of the page to update.',
          },
          'properties': {
            'type': 'object',
            'description':
                'The properties to update. Keys are property '
                'names, values depend on the property type.',
          },
          'icon': {
            'type': 'object',
            'description': 'A new icon object for the page.',
          },
          'cover': {
            'type': 'object',
            'description': 'A new cover image object for the page.',
          },
          'archived': {
            'type': 'boolean',
            'description': 'Set to true to archive the page.',
          },
          'in_trash': {
            'type': 'boolean',
            'description':
                'Set to true to trash the page, false to restore '
                'it. Separate from archived.',
          },
        },
        'required': ['page_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_move_page',
      description:
          'Move an existing Notion page to a new parent (another page or '
          'a database data source). The bot must have edit access to the '
          'new parent. Databases and other block types are not supported, '
          'only regular pages.',
      parameters: {
        'type': 'object',
        'properties': {
          'page_id': {
            'type': 'string',
            'description': 'The ID of the page to move.',
          },
          'parent': {
            'type': 'object',
            'description':
                'The new parent. Either '
                '{"type":"page_id","page_id":"..."} or '
                '{"type":"data_source_id","data_source_id":"..."}.',
          },
        },
        'required': ['page_id', 'parent'],
      },
    ),
    NotionToolMeta(
      name: 'notion_append_blocks',
      description:
          'Append content blocks to a Notion page or block. Each item in '
          '`children` is a block object with a `type` field and a same-named '
          'payload. Supported block types: $_blockTypes. For nested blocks '
          '(table, column_list, and any block carrying a `children` array), '
          'append ONE block per call to avoid malformed JSON during '
          'streaming. A table block has the shape '
          '{"type":"table","table":{"table_width":N,'
          '"has_column_header":true,"children":[{"type":"table_row",'
          '"table_row":{"cells":[[{"type":"text","text":{"content":"..."}}]]}}]}}. '
          'A column_list block contains exactly two or more column children, '
          'each with its own children array. Keep `children` arrays flat '
          '(one level of nesting per call). $_richTextHint',
      parameters: {
        'type': 'object',
        'properties': {
          'block_id': {
            'type': 'string',
            'description':
                'The ID of the page or block to append children '
                'to.',
          },
          'children': {
            'type': 'array',
            'items': {'type': 'object'},
            'description': 'The block objects to append.',
          },
          'after': {
            'type': 'string',
            'description':
                'The ID of an existing block to insert the new '
                'blocks after.',
          },
        },
        'required': ['block_id', 'children'],
      },
    ),
    NotionToolMeta(
      name: 'notion_update_block',
      description:
          'Update the content of an existing Notion block. Pass the '
          'block type payload object (e.g. {"paragraph":{"rich_text":[...]}}) '
          'and/or in_trash to trash or restore the block. All fields except '
          'block_id are forwarded as the request body.',
      parameters: {
        'type': 'object',
        'properties': {
          'block_id': {
            'type': 'string',
            'description': 'The ID of the block to update.',
          },
          'in_trash': {
            'type': 'boolean',
            'description':
                'Set to true to trash the block, false to restore '
                'it.',
          },
        },
        'required': ['block_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_delete_block',
      description: 'Delete (permanently remove) a block from a Notion page.',
      parameters: {
        'type': 'object',
        'properties': {
          'block_id': {
            'type': 'string',
            'description': 'The ID of the block to delete.',
          },
        },
        'required': ['block_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_archive_page',
      description: 'Archive or unarchive a Notion page.',
      parameters: {
        'type': 'object',
        'properties': {
          'page_id': {
            'type': 'string',
            'description': 'The ID of the page to archive or unarchive.',
          },
          'archived': {
            'type': 'boolean',
            'description':
                'Set to true to archive, false to unarchive. '
                'Defaults to true.',
          },
        },
        'required': ['page_id'],
      },
    ),
  ];
}