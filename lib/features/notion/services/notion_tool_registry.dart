import '../models/notion_tool_meta.dart';

class NotionToolRegistry {
  const NotionToolRegistry._();

  static const allTools = <NotionToolMeta>[
    NotionToolMeta(
      name: 'notion_search',
      description:
          'Search for pages and databases in the connected Notion '
          'workspace by title or content.',
      parameters: {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The search query string.',
          },
          'filter': {
            'type': 'string',
            'enum': ['page', 'database', 'data_source'],
            'description':
                'Filter results to only pages, only databases, '
                'or only data sources.',
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
      name: 'notion_get_comments',
      description: 'Retrieve discussion comments on a Notion page or block.',
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
      name: 'notion_query_database',
      description:
          'Query a Notion database to retrieve its entries (pages) '
          'with optional filters and sorts.',
      parameters: {
        'type': 'object',
        'properties': {
          'database_id': {
            'type': 'string',
            'description': 'The ID of the database to query.',
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
          'page_size': {
            'type': 'integer',
            'description': 'Number of results per page (max 100).',
          },
          'start_cursor': {
            'type': 'string',
            'description': 'Pagination cursor from a previous response.',
          },
        },
        'required': ['database_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_create_page',
      description:
          'Create a new page in a Notion database or as a child of '
          'another page.',
      parameters: {
        'type': 'object',
        'properties': {
          'parent': {
            'type': 'object',
            'description':
                'The parent of the new page. Must contain either '
                '{"type": "page_id", "page_id": "..."} or '
                '{"type": "database_id", "database_id": "..."}.',
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
      description: 'Update the properties of an existing Notion page.',
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
        },
        'required': ['page_id', 'properties'],
      },
    ),
    NotionToolMeta(
      name: 'notion_append_blocks',
      description: 'Append content blocks to a Notion page or block.',
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
      description: 'Update the content of an existing Notion block.',
      parameters: {
        'type': 'object',
        'properties': {
          'block_id': {
            'type': 'string',
            'description': 'The ID of the block to update.',
          },
        },
        'required': ['block_id'],
      },
    ),
    NotionToolMeta(
      name: 'notion_delete_block',
      description: 'Delete (archive) a block from a Notion page.',
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
