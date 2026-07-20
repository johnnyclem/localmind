import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../../../core/providers/hypervault_providers.dart';
import '../../data/models/claimed_domain.dart';
import '../../providers/domains_providers.dart';
import 'theme_picker_sheet.dart';

enum _AvailabilityStatus { idle, checking, available, unavailable }

/// T-M13-03..07: subdomain name input with client-side validation, debounced
/// live availability, claim, and the freshly-claimed realm with a restyle
/// action.
class ClaimDomainCard extends ConsumerStatefulWidget {
  const ClaimDomainCard({super.key});

  @override
  ConsumerState<ClaimDomainCard> createState() => _ClaimDomainCardState();
}

class _ClaimDomainCardState extends ConsumerState<ClaimDomainCard> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _requestToken = 0;

  _AvailabilityStatus _status = _AvailabilityStatus.idle;
  String? _unavailableReason;
  String? _clientError;
  bool _claiming = false;
  String? _claimError;
  String? _justClaimedDomain;

  // Client-side subdomain rules (mobile PRD T-M13-03): lowercase letters,
  // digits and hyphens, 1-63 chars, no leading/trailing hyphen.
  static final _validNamePattern = RegExp(
    r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
  );

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String name) {
    if (name.isEmpty) return null;
    if (name.length > 63) return 'Must be 63 characters or fewer.';
    if (!_validNamePattern.hasMatch(name)) {
      return 'Lowercase letters, numbers, and hyphens only — no leading or trailing hyphen.';
    }
    return null;
  }

  void _onChanged(String raw) {
    final lower = raw.toLowerCase();
    if (lower != raw) {
      _controller.value = _controller.value.copyWith(
        text: lower,
        selection: TextSelection.collapsed(offset: lower.length),
      );
    }
    final error = _validate(lower);
    setState(() {
      _clientError = error;
      _claimError = null;
      _status = _AvailabilityStatus.idle;
      _unavailableReason = null;
    });

    _debounce?.cancel();
    if (error != null || lower.isEmpty) return;
    final base = ref.read(selectedBaseDomainProvider);
    if (base == null) return;
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _checkAvailability(lower, base),
    );
  }

  Future<void> _checkAvailability(String name, String base) async {
    final token = ++_requestToken;
    setState(() => _status = _AvailabilityStatus.checking);
    try {
      final api = ref.read(domainsApiServiceProvider);
      final result = await api.checkAvailability(name: name, base: base);
      if (!mounted || token != _requestToken) return;
      setState(() {
        _status = result.available
            ? _AvailabilityStatus.available
            : _AvailabilityStatus.unavailable;
        _unavailableReason = result.reason;
      });
    } catch (_) {
      // A non-OK availability response (rate limit/hiccup) stays quiet —
      // claim still validates server-side (mobile PRD T-M13-04).
      if (!mounted || token != _requestToken) return;
      setState(() => _status = _AvailabilityStatus.idle);
    }
  }

  Future<void> _claim() async {
    final base = ref.read(selectedBaseDomainProvider);
    final name = _controller.text.trim();
    if (base == null || name.isEmpty) return;

    setState(() {
      _claiming = true;
      _claimError = null;
    });
    try {
      final claimed = await ref
          .read(claimedDomainsProvider.notifier)
          .claim(desiredName: name, baseDomain: base);
      if (!mounted) return;
      setState(() {
        _justClaimedDomain = claimed.domain;
        _claiming = false;
        _controller.clear();
        _status = _AvailabilityStatus.idle;
      });
    } on HyperVaultApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _claiming = false;
        _claimError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _claiming = false;
        _claimError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = ref.watch(selectedBaseDomainProvider);
    final name = _controller.text.trim();
    final canClaim =
        !_claiming &&
        base != null &&
        _clientError == null &&
        name.isNotEmpty &&
        _status == _AvailabilityStatus.available;

    ClaimedDomain? justClaimed;
    if (_justClaimedDomain != null) {
      final list = ref.watch(claimedDomainsProvider);
      for (final d in list) {
        if (d.domain == _justClaimedDomain) {
          justClaimed = d;
          break;
        }
      }
    }

    return ShadCard(
      title: const Text('Claim a realm'),
      description: Text(
        base == null
            ? 'Pick a domain above to get started.'
            : 'Claiming on $base',
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShadInput(
              controller: _controller,
              enabled: base != null && !_claiming,
              placeholder: const Text('yourname'),
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              onChanged: _onChanged,
              trailing: _buildStatusIcon(theme),
            ),
            if (name.isNotEmpty && base != null) ...[
              const SizedBox(height: 6),
              Text(
                '$name.$base',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_clientError != null) ...[
              const SizedBox(height: 6),
              Text(
                _clientError!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ] else if (_status == _AvailabilityStatus.unavailable) ...[
              const SizedBox(height: 6),
              Text(
                _unavailableReason ?? 'That name is taken.',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ],
            if (_claimError != null) ...[
              const SizedBox(height: 8),
              Text(
                _claimError!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            ShadButton(
              width: double.infinity,
              enabled: canClaim,
              leading: _claiming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedGlobe,
                      size: 18,
                    ),
              onPressed: canClaim ? _claim : null,
              child: Text(_claiming ? 'Claiming…' : 'Claim'),
            ),
            if (justClaimed != null) ...[
              const SizedBox(height: 16),
              const ShadSeparator.horizontal(),
              const SizedBox(height: 16),
              _ClaimedRealmTile(claimed: justClaimed),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildStatusIcon(ThemeData theme) {
    switch (_status) {
      case _AvailabilityStatus.idle:
        return null;
      case _AvailabilityStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(4),
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _AvailabilityStatus.available:
        return const HugeIcon(
          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
          size: 18,
          color: Colors.green,
        );
      case _AvailabilityStatus.unavailable:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedCancelCircle,
          size: 18,
          color: theme.colorScheme.error,
        );
    }
  }
}

class _ClaimedRealmTile extends ConsumerWidget {
  final ClaimedDomain claimed;

  const _ClaimedRealmTile({required this.claimed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uri = Uri.tryParse(claimed.url);
    final themes = ref.watch(capabilitiesProvider).value?.themes ?? const [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCrown,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  claimed.domain,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (claimed.message != null) ...[
            const SizedBox(height: 4),
            Text(
              claimed.message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowUpRight01,
                    size: 16,
                  ),
                  onPressed: uri == null
                      ? null
                      : () => launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        ),
                  child: const Text('Visit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShadButton.secondary(
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPaintBoard,
                    size: 16,
                  ),
                  onPressed: () =>
                      showRealmThemePickerSheet(context, ref, claimed, themes),
                  child: const Text('Restyle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
