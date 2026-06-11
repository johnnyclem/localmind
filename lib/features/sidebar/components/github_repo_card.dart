import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';

class GitHubRepoCard extends StatelessWidget {
  const GitHubRepoCard({super.key});

  final String repoUrl = 'https://github.com/abdulmominsakib/localmind';

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(repoUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardBg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final accentColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: _launchUrl,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedGithub,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.open_source,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.star_on_github,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
