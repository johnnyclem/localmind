import 'package:flutter/widgets.dart';
import 'package:localmind/features/personas/data/models/persona.dart';
import 'package:localmind/features/personas/views/components/create_persona_screen_content.dart';

class CreatePersonaScreen extends StatelessWidget {
  const CreatePersonaScreen({super.key, this.editPersona});

  final Persona? editPersona;

  @override
  Widget build(BuildContext context) {
    return CreatePersonaScreenContent(editPersona: editPersona);
  }
}
