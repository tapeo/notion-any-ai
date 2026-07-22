// Provider exposing AppReviewService. Stateful prefs are already initialized
// in main() via initSharedPrefs(), so the provider can read them synchronously.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/shared_prefs_provider.dart';
import '../services/app_review_service.dart';

final appReviewServiceProvider = Provider<AppReviewService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return AppReviewService(sharedPreferences: prefs);
});