import 'package:flutter_riverpod/flutter_riverpod.dart';

final modelSearchQueryProvider = NotifierProvider<ModelSearchNotifier, String>(
  ModelSearchNotifier.new,
);

class ModelSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
  void clear() => state = '';
}
