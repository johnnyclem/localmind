import 'package:flutter/widgets.dart';

class ChatAutoScrollController {
  ChatAutoScrollController();

  bool _autoScrollEnabled = true;
  bool _scheduledAutoScroll = false;
  int _lastMessageCount = 0;
  int _lastStreamingLength = 0;
  bool _lastIsStreaming = false;

  bool _isNearBottom(ScrollController controller) {
    if (!controller.hasClients) return true;
    final position = controller.position;
    return (position.maxScrollExtent - position.pixels) <= 120;
  }

  void onScrollChanged(ScrollController controller) {
    if (!controller.hasClients) return;
    _autoScrollEnabled = _isNearBottom(controller);
  }

  void scheduleAutoScroll({
    required ScrollController controller,
    required bool streaming,
  }) {
    if (!_autoScrollEnabled || _scheduledAutoScroll) return;

    _scheduledAutoScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduledAutoScroll = false;
      if (!controller.hasClients || !_autoScrollEnabled) return;

      final target = controller.position.maxScrollExtent;
      controller.animateTo(
        target,
        duration: streaming
            ? const Duration(milliseconds: 120)
            : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool checkAndUpdate({
    required int messageCount,
    required int streamingLength,
    required bool isStreaming,
  }) {
    final hasNewMessage = messageCount != _lastMessageCount;
    final streamingProgressed =
        isStreaming && streamingLength != _lastStreamingLength;
    final streamStarted = isStreaming && !_lastIsStreaming;
    final streamEnded = !isStreaming && _lastIsStreaming;

    _lastMessageCount = messageCount;
    _lastStreamingLength = streamingLength;
    _lastIsStreaming = isStreaming;

    return hasNewMessage || streamingProgressed || streamStarted || streamEnded;
  }
}
