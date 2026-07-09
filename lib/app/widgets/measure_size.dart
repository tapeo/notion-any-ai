// Reports the height of its child after layout. Used to size the message
// list bottom padding so the last message clears the floating input bar.
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({
    super.key,
    required this.onHeightChanged,
    required super.child,
  });

  final ValueChanged<double> onHeightChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onHeightChanged);
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onHeightChanged);

  final ValueChanged<double> onHeightChanged;
  double? _lastHeight;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (_lastHeight != height) {
      _lastHeight = height;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        onHeightChanged(height);
      });
    }
  }
}