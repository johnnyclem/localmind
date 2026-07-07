# Handwritten Feature Example

Use this as a compact reference for new handwritten Riverpod code. Adapt it to the project's repository, error, pagination, and serialization conventions.

## Contents

- [Model](#model)
- [Repository](#repository)
- [Providers](#providers)
- [Page](#page)
- [Components](#components)

## Model

```dart
// features/orders/data/models/order_model.dart
class OrderModel {
  const OrderModel({
    required this.id,
    required this.customerName,
    required this.total,
  });

  final String id;
  final String customerName;
  final double total;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'total': total,
    };
  }

  OrderModel copyWith({
    String? id,
    String? customerName,
    double? total,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      total: total ?? this.total,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OrderModel &&
            other.id == id &&
            other.customerName == customerName &&
            other.total == total;
  }

  @override
  int get hashCode => Object.hash(id, customerName, total);
}
```

## Repository

```dart
// features/orders/data/repositories/orders_repository.dart
class OrdersRepository {
  const OrdersRepository(this._client);

  final ApiClient _client;

  Future<List<OrderModel>> fetchOrders({String query = ''}) async {
    final response = await _client.get('/orders', query: {'q': query});
    return (response as List)
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteOrder(String id) {
    return _client.delete('/orders/$id');
  }
}
```

## Providers

```dart
// features/orders/providers/orders_providers.dart
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return OrdersRepository(client);
});

final orderSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final ordersProvider =
    AsyncNotifierProvider.autoDispose<OrdersNotifier, List<OrderModel>>(
  OrdersNotifier.new,
);

class OrdersNotifier extends AutoDisposeAsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() {
    final repository = ref.watch(ordersRepositoryProvider);
    final query = ref.watch(orderSearchQueryProvider);
    return repository.fetchOrders(query: query);
  }

  Future<void> deleteOrder(String id) async {
    state = const AsyncLoading<List<OrderModel>>();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(ordersRepositoryProvider);
      await repository.deleteOrder(id);
      final query = ref.read(orderSearchQueryProvider);
      return repository.fetchOrders(query: query);
    });
  }
}
```

## Page

```dart
// features/orders/views/orders_page.dart
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return orders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ErrorView(error: error),
      data: (items) => OrdersList(
        orders: items,
        onDelete: (id) => ref.read(ordersProvider.notifier).deleteOrder(id),
      ),
    );
  }
}
```

## Components

```dart
// features/orders/views/components/orders_list.dart
class OrdersList extends StatelessWidget {
  const OrdersList({
    super.key,
    required this.orders,
    required this.onDelete,
  });

  final List<OrderModel> orders;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderListTile(
          order: order,
          onDelete: () => onDelete(order.id),
        );
      },
    );
  }
}
```

```dart
// features/orders/views/components/order_list_tile.dart
class OrderListTile extends StatelessWidget {
  const OrderListTile({
    super.key,
    required this.order,
    required this.onDelete,
  });

  final OrderModel order;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(order.customerName),
      subtitle: Text('\$${order.total.toStringAsFixed(2)}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
```
