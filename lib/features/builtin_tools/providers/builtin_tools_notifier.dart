import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/builtin_tool_meta.dart';
import '../services/builtin_tools_storage.dart';
import '../states/builtin_tools_state.dart';
import 'builtin_tools_storage_provider.dart';

class BuiltinToolsNotifier extends Notifier<BuiltinToolsState> {
  late BuiltinToolsStorage _storage;

  @override
  BuiltinToolsState build() {
    _storage = ref.watch(builtinToolsStorageProvider);
    return BuiltinToolsState(enabled: BuiltinToolsState.defaultEnabled());
  }

  Future<void> init() async {
    final stored = _storage.loadEnabled();
    state = state.copyWith(enabled: stored);
  }

  Future<void> toggleTool(String id, bool enabled) async {
    final next = Map<String, bool>.from(state.enabled);
    next[id] = enabled;
    state = state.copyWith(enabled: next, saving: true);
    await _storage.saveEnabled(next);
    state = state.copyWith(saving: false);
  }

  Future<void> reset() async {
    state = state.copyWith(saving: true);
    await _storage.clear();
    state = BuiltinToolsState(enabled: BuiltinToolsState.defaultEnabled());
  }

  List<BuiltinToolMeta> enabledTools() {
    return BuiltinToolRegistry.all
        .where((t) => state.isEnabled(t.id))
        .toList();
  }
}

final builtinToolsProvider =
    NotifierProvider<BuiltinToolsNotifier, BuiltinToolsState>(
  BuiltinToolsNotifier.new,
);