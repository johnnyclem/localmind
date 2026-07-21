/// `PATCH /api/dashboard-theme {theme: styleId | null}` response — restyles
/// the signed-in user's own dashboard surfaces, independent of any claimed
/// realm (mobile PRD T-M13-08).
class DashboardThemeResult {
  final String? theme;
  final String? message;

  const DashboardThemeResult({this.theme, this.message});

  factory DashboardThemeResult.fromJson(Map<String, dynamic> json) =>
      DashboardThemeResult(
        theme: json['theme'] as String?,
        message: json['message'] as String?,
      );
}
