import 'package:equatable/equatable.dart';

import '../models/builtin_tool_meta.dart';

class BuiltinToolsState extends Equatable {
  const BuiltinToolsState({
    this.enabled = const {},
    this.saving = false,
  });

  final Map<String, bool> enabled;
  final bool saving;

  static Map<String, bool> defaultEnabled() {
    final result = <String, bool>{};
    for (final tool in BuiltinToolRegistry.all) {
      result[tool.id] = true;
    }
    return result;
  }

  bool isEnabled(String id) => enabled[id] ?? true;

  BuiltinToolsState copyWith({
    Map<String, bool>? enabled,
    bool? saving,
  }) {
    return BuiltinToolsState(
      enabled: enabled ?? this.enabled,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [enabled, saving];
}