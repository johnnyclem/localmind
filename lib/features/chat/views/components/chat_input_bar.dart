import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:localmind/core/theme/colors.dart';

import '../../../../core/models/enums.dart';
import '../../../servers/providers/server_providers.dart';
import '../../../stt/providers/stt_providers.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onStop,
    this.onAttach,
    this.enabled = true,
    this.isStreaming = false,
    this.focusNode,
  });

  final void Function(String message, {List<File>? attachments}) onSend;
  final VoidCallback onStop;
  final void Function(List<File> attachments)? onAttach;
  final bool enabled;
  final bool isStreaming;
  final FocusNode? focusNode;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  final List<File> _attachedFiles = [];
  late AnimationController _sendButtonAnimController;
  late Animation<double> _sendButtonScale;
  late AnimationController _micAnimController;
  String _preSpeechText = '';

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _sendButtonAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _sendButtonAnimController, curve: Curves.easeOut),
    );
    _micAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _sendButtonAnimController.dispose();
    _micAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleMicToggle() async {
    final stt = ref.read(sttProvider.notifier);
    final isListening = ref.read(sttProvider).isListening;

    Haptics.vibrate(HapticsType.light);

    if (isListening) {
      await stt.stopListening();
    } else {
      _preSpeechText = _controller.text;
      await stt.startListening(
        onResult: (words) {
          if (words.isNotEmpty) {
            setState(() {
              if (_preSpeechText.isEmpty) {
                _controller.text = words;
              } else {
                _controller.text = '$_preSpeechText $words';
              }
              // Position the cursor at the end of the text
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            });
          }
        },
      );
    }
  }

  Widget _buildMicButton(bool isListening, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _micAnimController,
      builder: (context, child) {
        final pulseValue = isListening ? _micAnimController.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (isListening)
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4 * pulseValue),
                  blurRadius: 8 + (8 * pulseValue),
                  spreadRadius: 1 + (3 * pulseValue),
                ),
            ],
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isListening
                  ? Colors.red
                  : theme.colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: HugeIcon(
                icon: isListening
                    ? HugeIcons.strokeRoundedVoice
                    : HugeIcons.strokeRoundedMic01,
                color: isListening
                    ? (isDark ? Colors.white : Colors.black)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                size: 20,
              ),
              onPressed: _handleMicToggle,
              tooltip: isListening ? l10n.stop_listening_tooltip : l10n.start_listening_tooltip,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAttach() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _attachedFiles.addAll(
          result.files.where((f) => f.path != null).map((f) => File(f.path!)),
        );
      });
      widget.onAttach?.call(_attachedFiles);
    }
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedFiles.isEmpty) return;

    Haptics.vibrate(HapticsType.medium);
    widget.onSend(text, attachments: List.from(_attachedFiles));
    _controller.clear();
    setState(() {
      _attachedFiles.clear();
    });
  }

  void _handleStop() {
    Haptics.vibrate(HapticsType.light);
    widget.onStop();
  }

  Widget _buildActionButton(bool canSend, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final backgroundColor = widget.isStreaming
        ? Colors.red
        : theme.colorScheme.primary;
    final iconColor = widget.isStreaming
        ? Colors.white
        : theme.colorScheme.onPrimary;

    return GestureDetector(
      onTapDown: canSend ? (_) => _sendButtonAnimController.forward() : null,
      onTapUp: canSend ? (_) => _sendButtonAnimController.reverse() : null,
      onTapCancel: canSend ? () => _sendButtonAnimController.reverse() : null,
      child: ScaleTransition(
        scale: _sendButtonScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor.withValues(
              alpha: (canSend || widget.isStreaming) ? 1.0 : 0.2,
            ),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: widget.isStreaming
                  ? HugeIcon(
                      icon: HugeIcons.strokeRoundedStop,
                      key: const ValueKey('stop'),
                      color: iconColor,
                      size: 20,
                    )
                  : HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowUp01,
                      key: ValueKey(canSend),
                      color: iconColor,
                      size: 20,
                    ),
            ),
            onPressed: widget.isStreaming
                ? _handleStop
                : (canSend ? _handleSubmit : null),
            tooltip: widget.isStreaming ? l10n.stop_generation_tooltip : l10n.send_message_tooltip,
          ),
        ),
      ),
    );
  }

  String? _mapSttError(String error) {
    switch (error) {
      case 'error_no_match':
        return 'No speech recognized. Please try speaking again and check your microphone.';
      case 'error_speech_timeout':
        return 'No speech detected. Timed out.';
      case 'error_permission':
        return 'Microphone permission denied.';
      case 'error_busy':
        return 'Speech recognition is busy. Please try again.';
      case 'error_network':
      case 'error_network_timeout':
        return 'Network error. Please check your connection and try again.';
      case 'error_audio':
        return 'Audio recording error. Please check your microphone.';
      default:
        if (error.startsWith('error_')) {
          final cleanName = error.replaceFirst('error_', '').replaceAll('_', ' ');
          return 'Speech recognition error: $cleanName';
        }
        return error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == ConnectionStatus.connected;

    final sttState = ref.watch(sttProvider);
    final isListening = sttState.isListening;

    if (isListening) {
      if (!_micAnimController.isAnimating) {
        _micAnimController.repeat(reverse: true);
      }
    } else {
      if (_micAnimController.isAnimating) {
        _micAnimController.stop();
        _micAnimController.reset();
      }
    }

    ref.listen<String?>(
      sttProvider.select((s) => s.error),
      (previous, next) {
        if (next != null) {
          final message = _mapSttError(next);
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        }
      },
    );

    final canSend =
        widget.enabled &&
        isConnected &&
        (_controller.text.trim().isNotEmpty || _attachedFiles.isNotEmpty) &&
        !widget.isStreaming;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceInput : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _attachedFiles.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      height: 70,
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 8,
                        bottom: 4,
                      ),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _attachedFiles.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final file = _attachedFiles[index];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(
                                    file,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              PositionedDirectional(
                                top: -4,
                                end: -4,
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _attachedFiles.removeAt(index),
                                  ),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
            Row(
              children: [
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedPlusSign,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 22,
                  ),
                  onPressed: isConnected ? _handleAttach : null,
                  tooltip: l10n.attach_images_tooltip,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    onChanged: (text) {
                      setState(() {});
                    },
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: l10n.chat_input_hint,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildMicButton(isListening, theme),
                const SizedBox(width: 8),
                _buildActionButton(canSend, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
