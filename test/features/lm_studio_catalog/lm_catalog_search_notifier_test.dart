import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/lm_studio_catalog/data/catalog_models.dart';
import 'package:localmind/features/lm_studio_catalog/data/lm_studio_catalog_service.dart';
import 'package:localmind/features/lm_studio_catalog/providers/lm_studio_catalog_providers.dart';

void main() {
  test('clearing the query invalidates an in-flight search', () async {
    final searchCompleter = Completer<HfSearchPage>();
    final service = _FakeLmStudioCatalogService(
      staffPicks: [
        const LmCatalogModel(
          id: 'lmstudio/foo',
          owner: 'lmstudio',
          name: 'foo',
          description: 'staff pick',
          isStaffPick: true,
          isVerified: true,
        ),
      ],
      searchCompleter: searchCompleter,
    );

    final container = ProviderContainer(
      overrides: [
        lmStudioCatalogServiceProvider.overrideWithValue(service),
        lmStudioStaffPicksProvider.overrideWith(
          (ref) async => service.staffPicks,
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(lmCatalogSearchProvider.notifier);
    final searchFuture = notifier.search('foo');

    await Future<void>.delayed(Duration.zero);
    await notifier.search('');

    expect(container.read(lmCatalogSearchProvider).allModels, isEmpty);

    searchCompleter.complete(
      const HfSearchPage(
        models: [
          LmCatalogModel(id: 'community/bar', owner: 'community', name: 'bar'),
        ],
      ),
    );

    await searchFuture;
    await Future<void>.delayed(Duration.zero);

    expect(container.read(lmCatalogSearchProvider).allModels, isEmpty);
  });
}

class _FakeLmStudioCatalogService extends LmStudioCatalogService {
  _FakeLmStudioCatalogService({
    required this.staffPicks,
    required this.searchCompleter,
  }) : super(Dio());

  final List<LmCatalogModel> staffPicks;
  final Completer<HfSearchPage> searchCompleter;

  @override
  Future<List<LmCatalogModel>> fetchStaffPicks() async => staffPicks;

  @override
  Future<HfSearchPage> searchHuggingFace({
    String query = '',
    int limit = 50,
    String? nextUrl,
  }) {
    return searchCompleter.future;
  }
}
