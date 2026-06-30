import 'package:flutter/widgets.dart';
import 'package:localmind/features/servers/data/models/server.dart';
import 'package:localmind/features/servers/views/components/add_server_screen_content.dart';

class AddServerScreen extends StatelessWidget {
  const AddServerScreen({super.key, this.editServer});

  final Server? editServer;

  @override
  Widget build(BuildContext context) {
    return AddServerScreenContent(editServer: editServer);
  }
}
