import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../hypervault/providers/hypervault_providers.dart';
import '../data/hv_admin_service.dart';
import '../data/models/hv_invite.dart';

final hvAdminServiceProvider = Provider<HvAdminService>((ref) {
  return HvAdminService(ref.read(hyperVaultApiClientProvider));
});

/// Invite codes created/edited this session. There's no list endpoint (spec
/// docs/mobile/prd/15-admin.md), so this is the only record the app has —
/// codes minted from another device or the web app never appear here.
final hvAdminInvitesProvider =
    NotifierProvider<HvAdminInvitesNotifier, List<HvInvite>>(
      HvAdminInvitesNotifier.new,
    );

class HvAdminInvitesNotifier extends Notifier<List<HvInvite>> {
  @override
  List<HvInvite> build() => const [];

  void prepend(HvInvite invite) {
    state = [invite, ...state];
  }

  void replace(HvInvite invite) {
    state = [
      for (final i in state)
        if (i.id == invite.id) invite else i,
    ];
  }

  void remove(String id) {
    state = state.where((i) => i.id != id).toList();
  }
}
