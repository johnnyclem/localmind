import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../services/review_prompt_service.dart';
import 'app_providers.dart';
import 'storage_providers.dart';

final reviewPromptClientProvider = Provider<ReviewPromptClient>((ref) {
  return InAppReviewPromptClient();
});

final reviewPromptServiceProvider = Provider<ReviewPromptService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(reviewPromptClientProvider);

  return ReviewPromptService(
    prefs: prefs,
    client: client,
    appVersionLoader: () async {
      try {
        final packageInfo = await ref.read(packageInfoProvider.future);
        final buildNumber = packageInfo.buildNumber;
        if (buildNumber.isEmpty) {
          return packageInfo.version;
        }
        return '${packageInfo.version}+$buildNumber';
      } catch (_) {
        return AppConstants.version;
      }
    },
  );
});
