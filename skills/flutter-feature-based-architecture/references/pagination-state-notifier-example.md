# Pagination StateNotifier Example

Use this reference when a project already standardizes on `StateNotifierProvider` or when the user specifically asks for this indexed page-pagination style. For new projects, prefer the main skill's current Riverpod defaults first.

## Contents

- [State](#state)
- [Provider and Controller](#provider-and-controller)
- [UI Trigger Guidance](#ui-trigger-guidance)

## State

Keep pagination state immutable and handwritten. Track the loaded items, next page, initial load, pagination spinner, error text, and whether more data is available.

```dart
import 'package:flutter/foundation.dart';

import '../data/models/article_model.dart';

class PostPagination {
  static const pageSize = 10;

  const PostPagination({
    required this.posts,
    required this.page,
    required this.errorMessage,
    required this.initialLoaded,
    required this.isPaginationLoading,
    required this.hasMore,
  });

  const PostPagination.initial()
      : posts = const [],
        page = 1,
        errorMessage = '',
        initialLoaded = false,
        isPaginationLoading = false,
        hasMore = true;

  final List<ArticleModel> posts;
  final int page;
  final String errorMessage;
  final bool initialLoaded;
  final bool isPaginationLoading;
  final bool hasMore;

  bool get hasRefreshError {
    return errorMessage.isNotEmpty && posts.length <= pageSize;
  }

  PostPagination copyWith({
    List<ArticleModel>? posts,
    int? page,
    String? errorMessage,
    bool? initialLoaded,
    bool? isPaginationLoading,
    bool? hasMore,
  }) {
    return PostPagination(
      posts: posts ?? this.posts,
      page: page ?? this.page,
      errorMessage: errorMessage ?? this.errorMessage,
      initialLoaded: initialLoaded ?? this.initialLoaded,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PostPagination &&
            listEquals(other.posts, posts) &&
            other.page == page &&
            other.errorMessage == errorMessage &&
            other.initialLoaded == initialLoaded &&
            other.isPaginationLoading == isPaginationLoading &&
            other.hasMore == hasMore;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(posts),
      page,
      errorMessage,
      initialLoaded,
      isPaginationLoading,
      hasMore,
    );
  }
}
```

## Provider and Controller

Keep widget APIs out of the controller. Do not import `material.dart` or use `WidgetsBinding` here. Let the provider create the controller and start the first page load.

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/article_model.dart';
import '../data/repositories/post_repository.dart';
import 'post_pagination.dart';

final recentPostsControllerProvider =
    StateNotifierProvider.autoDispose<RecentPostsController, PostPagination>(
  (ref) {
    final repository = ref.watch(postRepositoryProvider);
    final controller = RecentPostsController(repository);
    unawaited(controller.loadNextPage());
    return controller;
  },
);

class RecentPostsController extends StateNotifier<PostPagination> {
  RecentPostsController(this._repository) : super(const PostPagination.initial());

  final PostRepository _repository;

  bool _isAlreadyLoading = false;
  int _requestGeneration = 0;

  Future<void> loadNextPage() async {
    if (_isAlreadyLoading || !state.hasMore) return;

    _isAlreadyLoading = true;
    final requestGeneration = _requestGeneration;
    final pageToLoad = state.page;
    final isFirstPage = pageToLoad == 1;

    state = state.copyWith(
      errorMessage: '',
      isPaginationLoading: !isFirstPage,
    );

    try {
      final fetched = await _repository.getAllPosts(pageNumber: pageToLoad);

      if (!mounted || requestGeneration != _requestGeneration) return;

      final posts = fetched
          .map((post) => post.copyWith(heroTag: '${post.link}recents'))
          .toList();

      state = state.copyWith(
        posts: [...state.posts, ...posts],
        page: pageToLoad + 1,
        initialLoaded: true,
        isPaginationLoading: false,
        hasMore: posts.length >= PostPagination.pageSize,
      );
    } on Exception {
      if (!mounted || requestGeneration != _requestGeneration) return;

      state = state.copyWith(
        errorMessage: 'Fetch Error',
        initialLoaded: true,
        isPaginationLoading: false,
      );
    } finally {
      if (requestGeneration == _requestGeneration) {
        _isAlreadyLoading = false;
      }
    }
  }

  void handleVisibleIndex(int index) {
    final itemPosition = index + 1;
    final reachedPageBoundary =
        itemPosition % PostPagination.pageSize == 0 && itemPosition != 0;
    final viewedPage = itemPosition ~/ PostPagination.pageSize;

    if (reachedPageBoundary && viewedPage + 1 >= state.page) {
      loadNextPage();
    }
  }

  Future<void> refresh() async {
    _requestGeneration++;
    _isAlreadyLoading = false;
    state = const PostPagination.initial();
    await loadNextPage();
  }
}
```

## UI Trigger Guidance

Use `handleVisibleIndex` when a list component has a stable visible-index callback. Avoid calling pagination triggers directly from `itemBuilder`; render callbacks can run repeatedly for reasons unrelated to user scroll intent.

If the UI has only a standard `ListView`, prefer triggering `loadNextPage()` from a scroll notification, scroll controller, or explicit "load more" affordance. Keep the list UI in `views/components/` as `StatelessWidget` components and pass callbacks from the page.
