// Tracks app launches and prompts the native in-app review dialog once the
// user has launched the app enough times. Best-effort, silent on failure.
// The OS rate-limits the actual prompt (Apple ~3/year, Google ~1/120 days),
// so the app must not fire it on every call.
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _launchCountKey = 'app_review_launch_count';
const String _reviewShownKey = 'app_review_shown';

const int _minLaunches = 3;

class AppReviewService {
  AppReviewService({
    required SharedPreferences sharedPreferences,
    InAppReview? inAppReview,
  })  : _prefs = sharedPreferences,
        _inAppReview = inAppReview ?? InAppReview.instance;

  final SharedPreferences _prefs;
  final InAppReview _inAppReview;

  Future<void> trackLaunch() async {
    final count = (_prefs.getInt(_launchCountKey) ?? 0) + 1;
    await _prefs.setInt(_launchCountKey, count);
    debugPrint('[app-review] launch count: $count');
  }

  Future<void> maybePrompt() async {
    if (_prefs.getBool(_reviewShownKey) ?? false) {
      return;
    }

    final count = _prefs.getInt(_launchCountKey) ?? 0;
    if (count < _minLaunches) {
      return;
    }

    try {
      final available = await _inAppReview.isAvailable();
      if (!available) {
        debugPrint('[app-review] in-app review not available');
        return;
      }

      await _inAppReview.requestReview();
      await _prefs.setBool(_reviewShownKey, true);
      debugPrint('[app-review] review prompt shown');
    } catch (err) {
      log('[app-review] failed to request review: $err');
    }
  }

  Future<ReviewPromptResult> forcePrompt() async {
    try {
      final available = await _inAppReview.isAvailable();
      if (!available) {
        debugPrint('[app-review] in-app review not available');
        return ReviewPromptResult.notAvailable;
      }

      await _inAppReview.requestReview();
      debugPrint('[app-review] review prompt forced');
      return ReviewPromptResult.shown;
    } catch (err) {
      log('[app-review] failed to force review: $err');
      return ReviewPromptResult.error;
    }
  }
}

enum ReviewPromptResult { shown, notAvailable, error }