import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/chat/data/tools/adapters/on_device_tool_adapter.dart';

void main() {
  group('OnDeviceToolAdapter', () {
    test('collects function calls and returns them', () {
      final adapter = OnDeviceToolAdapter();
      adapter.consumeFunctionCall('calc.add', {'a': 1, 'b': 2});
      final calls = adapter.takeCompletedCalls();
      expect(calls.length, 1);
      expect(calls.single.name, 'calc.add');
      expect(calls.single.arguments['a'], 1);
    });

    test('clears state after takeCompletedCalls', () {
      final adapter = OnDeviceToolAdapter();
      adapter.consumeFunctionCall('calc.add', {'a': 1, 'b': 2});
      adapter.takeCompletedCalls();
      expect(adapter.takeCompletedCalls(), isEmpty);
    });
  });
}
