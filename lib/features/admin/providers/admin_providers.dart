import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/providers/hypervault_providers.dart';
import '../data/admin_api_service.dart';
import '../data/models/admin_account.dart';
import '../data/models/admin_invite.dart';
import '../data/models/admin_waitlist_entry.dart';

/// Thrown by the list notifiers below when a direct-Supabase read fails
/// (RLS denial, missing table, network hiccup, ...). Kept distinct from
/// [HyperVaultApiException] (which only ever comes from the real REST
/// mutation endpoints) so the UI can show one consistent "couldn't load"
/// message for the read path regardless of the underlying Postgrest error.
class AdminLoadException implements Exception {
  final String message;
  const AdminLoadException([
    this.message =
        "Couldn't load — you may not have admin access, or this data isn't available yet.",
  ]);

  @override
  String toString() => message;
}

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService(ref.watch(hypervaultClientProvider));
});

/// `invite_codes` (mobile PRD M15, T-M15-02/03/04).
///
/// **Data path:** there is no `GET /api/admin/invites` list route, so this
/// reads the table directly via `Supabase.instance.client` — an interim
/// approach documented in the PRD, gated only by whatever RLS policy (if
/// any) exists on `invite_codes`. A non-admin (or any user, until a proper
/// admin-read RLS policy ships) will see this fail closed into
/// [AdminLoadException] rather than a false "no invites yet".
class AdminInvitesNotifier extends AsyncNotifier<List<AdminInvite>> {
  @override
  Future<List<AdminInvite>> build() => _fetch();

  Future<List<AdminInvite>> _fetch() async {
    try {
      final rows = await sb.Supabase.instance.client
          .from('invite_codes')
          .select()
          .order('created_at', ascending: false);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(AdminInvite.fromJson)
          .toList();
    } catch (e) {
      throw const AdminLoadException();
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  /// `POST /api/admin/invites {maxUses?, note?}`. Prepends the returned
  /// invite to the list.
  Future<void> create({int? maxUses, String? note}) async {
    final api = ref.read(adminApiServiceProvider);
    final json = await api.createInvite(maxUses: maxUses, note: note);
    final invite = AdminInvite.fromJson(
      json['invite'] as Map<String, dynamic>,
    );
    final previous = state.value ?? const [];
    state = AsyncData([invite, ...previous]);
  }

  /// `PATCH /api/admin/invites/[id] {disabled}`, optimistic with rollback.
  Future<void> setDisabled(String id, bool disabled) async {
    final previous = state.value ?? const [];
    final idx = previous.indexWhere((i) => i.id == id);
    if (idx == -1) return;

    final optimistic = [...previous];
    optimistic[idx] = optimistic[idx].copyWith(disabled: disabled);
    state = AsyncData(optimistic);

    try {
      final api = ref.read(adminApiServiceProvider);
      final json = await api.setInviteDisabled(id, disabled);
      final updated = AdminInvite.fromJson(
        json['invite'] as Map<String, dynamic>,
      );
      final latest = [...(state.value ?? optimistic)];
      final latestIdx = latest.indexWhere((i) => i.id == id);
      if (latestIdx != -1) {
        latest[latestIdx] = updated;
        state = AsyncData(latest);
      }
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// `DELETE /api/admin/invites/[id]`, optimistic with rollback.
  Future<void> delete(String id) async {
    final previous = state.value ?? const [];
    state = AsyncData(previous.where((i) => i.id != id).toList());
    try {
      final api = ref.read(adminApiServiceProvider);
      await api.deleteInvite(id);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final adminInvitesProvider =
    AsyncNotifierProvider<AdminInvitesNotifier, List<AdminInvite>>(
      AdminInvitesNotifier.new,
    );

/// `waitlist` (mobile PRD M15, T-M15-02/05). Same direct-Supabase-read
/// caveat as [AdminInvitesNotifier] applies.
class AdminWaitlistNotifier extends AsyncNotifier<List<AdminWaitlistEntry>> {
  @override
  Future<List<AdminWaitlistEntry>> build() => _fetch();

  Future<List<AdminWaitlistEntry>> _fetch() async {
    try {
      final rows = await sb.Supabase.instance.client
          .from('waitlist')
          .select()
          .order('created_at', ascending: false);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(AdminWaitlistEntry.fromJson)
          .toList();
    } catch (e) {
      throw const AdminLoadException();
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  /// `DELETE /api/admin/waitlist/[id]`, optimistic with rollback.
  Future<void> remove(String userId) async {
    final previous = state.value ?? const [];
    state = AsyncData(previous.where((w) => w.userId != userId).toList());
    try {
      final api = ref.read(adminApiServiceProvider);
      await api.deleteWaitlistEntry(userId);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final adminWaitlistProvider =
    AsyncNotifierProvider<AdminWaitlistNotifier, List<AdminWaitlistEntry>>(
      AdminWaitlistNotifier.new,
    );

/// `profiles` joined (client-side) with `account_access` (mobile PRD M15,
/// T-M15-02/06/07). There's no FK between the two tables, so — mirroring the
/// web admin page's server component — they're fetched as two separate
/// queries and merged by id rather than via a Postgrest embed.
class AdminAccountsNotifier extends AsyncNotifier<List<AdminAccount>> {
  @override
  Future<List<AdminAccount>> build() => _fetch();

  Future<List<AdminAccount>> _fetch() async {
    try {
      final client = sb.Supabase.instance.client;
      final results = await Future.wait([
        client
            .from('profiles')
            .select('id, email, display_name, plan, vanity_subdomain, created_at')
            .order('created_at', ascending: false),
        client.from('account_access').select('user_id, source'),
      ]);
      final profileRows = (results[0] as List).cast<Map<String, dynamic>>();
      final accessRows = (results[1] as List).cast<Map<String, dynamic>>();
      final accessByUser = <String, String>{
        for (final row in accessRows)
          row['user_id'] as String: row['source'] as String? ?? 'admin',
      };
      return profileRows
          .map(
            (row) => AdminAccount.fromJson(
              row,
              accessSource: accessByUser[row['id']],
            ),
          )
          .toList();
    } catch (e) {
      throw const AdminLoadException();
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  /// `PATCH /api/admin/accounts/[id] {plan}`, optimistic with rollback.
  Future<void> setPlan(String id, String plan) async {
    final previous = state.value ?? const [];
    final idx = previous.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final optimistic = [...previous];
    optimistic[idx] = optimistic[idx].copyWith(plan: plan);
    state = AsyncData(optimistic);

    try {
      final api = ref.read(adminApiServiceProvider);
      await api.updateAccount(id, plan: plan);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// `PATCH /api/admin/accounts/[id] {approved}`, optimistic with rollback.
  /// Revoking your own access is disallowed server-side; callers should
  /// disable the affordance client-side too (never call with your own id
  /// and `approved: false`).
  Future<void> setApproved(String id, bool approved) async {
    final previous = state.value ?? const [];
    final idx = previous.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final optimistic = [...previous];
    optimistic[idx] = optimistic[idx].copyWith(
      accessSource: approved ? 'admin' : null,
    );
    state = AsyncData(optimistic);

    try {
      final api = ref.read(adminApiServiceProvider);
      await api.updateAccount(id, approved: approved);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// `DELETE /api/admin/accounts/[id]`, optimistic with rollback. Callers
  /// must guard against self-deletion (see [AdminAccount.id] vs the current
  /// user's id) — the server also rejects it, but the affordance should
  /// already be disabled.
  Future<void> delete(String id) async {
    final previous = state.value ?? const [];
    state = AsyncData(previous.where((a) => a.id != id).toList());
    try {
      final api = ref.read(adminApiServiceProvider);
      await api.deleteAccount(id);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final adminAccountsProvider =
    AsyncNotifierProvider<AdminAccountsNotifier, List<AdminAccount>>(
      AdminAccountsNotifier.new,
    );
