import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorder {
  VoiceRecorder();

  final AudioRecorder _recorder = AudioRecorder();
  final ValueNotifier<bool> isRecordingNotifier = ValueNotifier<bool>(false);
  Completer<void>? _startCompleter;

  static const _startTimeout = Duration(seconds: 5);
  static const _stopTimeout = Duration(seconds: 5);

  bool get isRecording => isRecordingNotifier.value;

  Future<bool> requestPermission() async {
    try {
      return await _recorder.hasPermission(request: true).timeout(
        _startTimeout,
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> start() async {
    if (isRecording) return true;

    bool hasPermission;
    try {
      hasPermission = await _recorder.hasPermission(request: false).timeout(
        _startTimeout,
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
    if (!hasPermission) return false;

    _startCompleter = Completer<void>();

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    final parent = File(path).parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    try {
      await _recorder
          .start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path)
          .timeout(_startTimeout, onTimeout: () {});

      bool platformRecording;
      try {
        platformRecording = await _recorder.isRecording().timeout(
          _startTimeout,
          onTimeout: () => false,
        );
      } catch (_) {
        platformRecording = false;
      }

      if (!platformRecording) {
        debugPrint(
          '[VoiceRecorder] start() returned but platform reports '
          'not recording; session silently failed.',
        );
        _startCompleter!.complete();
        _startCompleter = null;
        return false;
      }

      isRecordingNotifier.value = true;
      _startCompleter!.complete();
      return true;
    } catch (e) {
      debugPrint('[VoiceRecorder] start() failed: $e');
      _startCompleter!.complete();
      _startCompleter = null;
      return false;
    }
  }

  Future<String?> stop() async {
    if (_startCompleter != null && !_startCompleter!.isCompleted) {
      await _startCompleter!.future.timeout(_stopTimeout, onTimeout: () {});
    }
    if (!isRecording) {
      _startCompleter = null;
      return null;
    }

    try {
      final path = await _recorder.stop().timeout(
        _stopTimeout,
        onTimeout: () {
          debugPrint(
            '[VoiceRecorder] stop() timed out after '
            '${_stopTimeout.inSeconds}s; forcing reset.',
          );
          return null;
        },
      );
      return path;
    } catch (e) {
      debugPrint('[VoiceRecorder] stop() failed: $e');
      return null;
    } finally {
      isRecordingNotifier.value = false;
      _startCompleter = null;
    }
  }

  Future<void> cancel() async {
    if (_startCompleter != null && !_startCompleter!.isCompleted) {
      await _startCompleter!.future.timeout(_stopTimeout, onTimeout: () {});
    }
    if (!isRecording) {
      _startCompleter = null;
      return;
    }

    try {
      await _recorder.cancel().timeout(_stopTimeout, onTimeout: () {});
    } catch (e) {
      debugPrint('[VoiceRecorder] cancel() failed: $e');
    } finally {
      isRecordingNotifier.value = false;
      _startCompleter = null;
    }
  }

  Future<void> dispose() async {
    isRecordingNotifier.dispose();
    await _recorder.dispose();
  }
}
