import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/core/theme/colors.dart';
import 'package:localmind/features/conversations/providers/conversation_providers.dart'
    as conv;
import 'package:localmind/features/personas/data/models/persona.dart';
import 'package:localmind/features/personas/providers/personas_providers.dart';
import 'package:localmind/l10n/app_localizations.dart';

enum PersonaPickerMode { conversation, preselection }

void showPersonaPickerSheet(
  BuildContext context, {
  PersonaPickerMode mode = PersonaPickerMode.conversation,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => PersonaPickerSheet(mode: mode),
  );
}

class PersonaPickerSheet extends ConsumerWidget {
  const PersonaPickerSheet({super.key, required this.mode});

  final PersonaPickerMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personasAsync = ref.watch(personasNotifierProvider);
    final activeConv = ref.watch(conv.activeConversationProvider);
    final selectedPersona = ref.watch(selectedPersonaProvider);

    final currentPersonaId = mode == PersonaPickerMode.preselection
        ? selectedPersona?.id
        : activeConv?.personaId;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.select_persona,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: personasAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMutedText
                          : AppColors.lightMutedText,
                    ),
                  ),
                ),
                data: (personas) {
                  if (personas.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.no_personas_found,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMutedText
                              : AppColors.lightMutedText,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: personas.length,
                    itemBuilder: (context, index) {
                      final persona = personas[index];
                      return _PersonaTile(
                        persona: persona,
                        isSelected: persona.id == currentPersonaId,
                        isDark: isDark,
                        onTap: () => _selectPersona(
                          context,
                          ref,
                          persona,
                          activeConv?.id,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPersona(
    BuildContext context,
    WidgetRef ref,
    Persona persona,
    String? conversationId,
  ) {
    if (mode == PersonaPickerMode.preselection || conversationId == null) {
      ref.read(selectedPersonaProvider.notifier).select(persona);
    } else {
      ref.read(conv.conversationsProvider.notifier).updatePersona(
            conversationId,
            persona.id,
            persona.systemPrompt,
          );
    }
    Navigator.pop(context);
  }
}

class _PersonaTile extends StatelessWidget {
  const _PersonaTile({
    required this.persona,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final Persona persona;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return ListTile(
      leading: Text(persona.emoji, style: const TextStyle(fontSize: 22)),
      title: Text(
        persona.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: persona.description != null
          ? Text(
              persona.description!,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkMutedText
                    : AppColors.lightMutedText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isSelected ? Icon(Icons.check_circle, color: accent) : null,
      onTap: onTap,
    );
  }
}
