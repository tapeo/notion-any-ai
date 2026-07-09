import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../models/notion_page_ref.dart';
import '../providers/notion_connection_notifier.dart';
import '../services/notion_page_search.dart';
import '../services/notion_recent_pages_storage.dart';

Future<NotionPageRef?> showNotionPagePickerSheet(
  BuildContext context, {
  required WidgetRef ref,
  List<String> alreadySelected = const [],
}) {
  return showModalBottomSheet<NotionPageRef>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _NotionPagePickerSheet(
      alreadySelected: alreadySelected,
    ),
  );
}

class _NotionPagePickerSheet extends ConsumerStatefulWidget {
  const _NotionPagePickerSheet({this.alreadySelected = const []});

  final List<String> alreadySelected;

  @override
  ConsumerState<_NotionPagePickerSheet> createState() =>
      _NotionPagePickerSheetState();
}

class _NotionPagePickerSheetState
    extends ConsumerState<_NotionPagePickerSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  List<NotionPageRef> _results = const [];
  bool _loading = false;
  String? _error;
  int _searchGeneration = 0;
  bool _isRecentView = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadRecentPages();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    final value = _controller.text;
    if (value == _query) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _isRecentView = false;
      });
      _runSearch(value);
    });
  }

  void _loadRecentPages() {
    final storage = ref.read(notionRecentPagesStorageProvider);
    final recent = storage.load();
    if (!mounted) return;
    setState(() {
      _results = recent;
      _isRecentView = true;
    });
    if (recent.isNotEmpty) {
      _resolveRecentBreadcrumbs(recent);
    }
  }

  Future<void> _resolveRecentBreadcrumbs(List<NotionPageRef> pages) async {
    final state = ref.read(notionConnectionProvider);
    if (!state.connected || !state.enabled) return;
    final notifier = ref.read(notionConnectionProvider.notifier);
    final token = await notifier.validAccessToken();
    if (token == null || !mounted) return;
    final search = ref.read(notionPageSearchProvider);
    final generation = ++_searchGeneration;
    _resolveBreadcrumbs(
      search: search,
      token: token,
      results: pages,
      generation: generation,
    );
  }

  void _selectPage(NotionPageRef page) {
    HapticFeedback.selectionClick();
    final storage = ref.read(notionRecentPagesStorageProvider);
    storage.record(page);
    Navigator.of(context).pop(page);
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _isRecentView = true;
      });
      _loadRecentPages();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final state = ref.read(notionConnectionProvider);
    if (!state.connected || !state.enabled) {
      setState(() {
        _loading = false;
        _error = 'Connect and enable Notion to search pages.';
      });
      return;
    }
    final notifier = ref.read(notionConnectionProvider.notifier);
    final token = await notifier.validAccessToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Notion connection is unavailable.';
      });
      return;
    }
    final search = ref.read(notionPageSearchProvider);
    try {
      final results = await search.search(accessToken: token, query: trimmed);
      if (!mounted) return;
      final generation = ++_searchGeneration;
      setState(() {
        _results = results;
        _loading = false;
        _error = null;
      });
      _resolveBreadcrumbs(
        search: search,
        token: token,
        results: results,
        generation: generation,
      );
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Search failed: $err';
      });
    }
  }

  Future<void> _resolveBreadcrumbs({
    required NotionPageSearch search,
    required String token,
    required List<NotionPageRef> results,
    required int generation,
  }) async {
    final pending = results.where((p) => p.breadcrumb.isEmpty).toList();
    const maxConcurrency = 4;
    var index = 0;
    Future<void> worker() async {
      while (index < pending.length) {
        if (!mounted) return;
        if (generation != _searchGeneration) return;
        final page = pending[index++];
        final chain = await search.fetchBreadcrumbForPage(
          accessToken: token,
          pageId: page.id,
        );
        if (!mounted) return;
        if (generation != _searchGeneration) return;
        if (chain.isEmpty) continue;
        setState(() {
          _results = _results
              .map((r) => r.id == page.id ? r.copyWith(breadcrumb: chain) : r)
              .toList();
        });
      }
    }

    final workers = <Future<void>>[];
    for (var i = 0; i < maxConcurrency && i < pending.length; i++) {
      workers.add(worker());
    }
    await Future.wait(workers);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        viewInsets.bottom + AppSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a Notion page',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            'Add a page to focus on',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary(theme.brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          _SearchField(
            controller: _controller,
            focusNode: _focusNode,
          ),
          const SizedBox(height: AppSpacing.space3),
          Flexible(
            child: SizedBox(
              height: 320,
              child: _buildBody(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      );
    }
    if (_query.trim().isEmpty) {
      if (_isRecentView) {
        if (_loading) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (_results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(
                'Type to search your Notion pages.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary(theme.brightness),
                ),
              ),
            ),
          );
        }
        return _buildResultsList(theme);
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Text(
            'Type to search your Notion pages.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary(theme.brightness),
            ),
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Text(
            'No pages found.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary(theme.brightness),
            ),
          ),
        ),
      );
    }
    return _buildResultsList(theme);
  }

  Widget _buildResultsList(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _results.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: AppColors.borderSubtle(theme.brightness),
      ),
      itemBuilder: (context, index) {
        final page = _results[index];
        final alreadyAdded =
            widget.alreadySelected.contains(page.id);
        return _PageRow(
          page: page,
          alreadyAdded: alreadyAdded,
          onTap: () => _selectPage(page),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = AppColors.borderDefault(
      isDark ? Brightness.dark : Brightness.light,
    );
    return Material(
      color: AppColors.bgPrimary(theme.brightness),
      shape: AppShapes.sm(side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: AppIconSize.md,
              color: AppColors.textTertiary(theme.brightness),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search pages...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary(theme.brightness),
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.space3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.page,
    required this.onTap,
    this.alreadyAdded = false,
  });

  final NotionPageRef page;
  final VoidCallback onTap;
  final bool alreadyAdded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppColors.textSecondary(theme.brightness);
    final titleColor = alreadyAdded
        ? AppColors.textTertiary(theme.brightness)
        : muted;
    final breadcrumb = page.breadcrumb.join(' / ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space2 + 1,
          horizontal: AppSpacing.space1,
        ),
        child: Row(
          children: [
            if (page.icon != null && page.icon!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space2),
                child: Text(
                  page.icon!,
                  style: const TextStyle(fontSize: 18),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space2),
                child: Icon(
                  Icons.description_outlined,
                  size: AppIconSize.lg,
                  color: muted,
                ),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (breadcrumb.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        breadcrumb,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary(theme.brightness),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Text(
                    page.title,
                    style: AppFonts.labelMd().copyWith(color: titleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              alreadyAdded ? Icons.check : Icons.chevron_right,
              size: AppIconSize.md,
              color: AppColors.textTertiary(theme.brightness),
            ),
          ],
        ),
      ),
    );
  }
}