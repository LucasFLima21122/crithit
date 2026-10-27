/// Usuário logado no CritHit (espelha `auth.users` + `public.profiles`).
class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    this.email,
    this.steamId,
    this.psnOnlineId,
    this.isGuest = false,
  });

  final String id;
  final String displayName;
  final String? email;

  /// SteamID64 da conta Steam conectada, se houver. Fica salvo no perfil
  /// para a biblioteca ser recarregada sozinha no próximo login.
  final String? steamId;

  /// ID online da conta PSN conectada, se houver. Mesmo papel do [steamId].
  final String? psnOnlineId;

  /// Conta de convidado (login anônimo): pode avaliar, mas não tem e-mail.
  final bool isGuest;

  String get initials {
    final List<String> parts = displayName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty || parts.first.isEmpty) return "?";
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  AppUser copyWith({
    String? steamId,
    bool clearSteamId = false,
    String? psnOnlineId,
    bool clearPsnOnlineId = false,
  }) {
    return AppUser(
      id: id,
      displayName: displayName,
      email: email,
      steamId: clearSteamId ? null : (steamId ?? this.steamId),
      psnOnlineId: clearPsnOnlineId ? null : (psnOnlineId ?? this.psnOnlineId),
      isGuest: isGuest,
    );
  }
}
