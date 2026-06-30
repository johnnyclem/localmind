import 'package:flutter/material.dart';
import '../../../core/components/app_sizes.dart';
import 'components/sidebar_widget.dart';

class ConversationDrawer extends StatelessWidget {
  const ConversationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.sidebarWidth,
      child: const Drawer(child: SidebarWidget()),
    );
  }
}
