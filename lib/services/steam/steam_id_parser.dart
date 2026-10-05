/// Resultado da leitura do que o usuário digitou para identificar a conta
/// Steam: ou já é um SteamID64, ou é um "ID personalizado" (vanity URL) que
/// precisa ser resolvido pela API.
class SteamIdInput {
  const SteamIdInput.steamId(String this.steamId) : vanity = null;
  const SteamIdInput.vanity(String this.vanity) : steamId = null;

  final String? steamId;
  final String? vanity;
}

/// Aceita os formatos que um usuário costuma ter em mãos:
/// - SteamID64: `76561198000000000`
/// - link do perfil: `https://steamcommunity.com/profiles/76561198000000000`
/// - link personalizado: `https://steamcommunity.com/id/meunick/`
/// - só o ID personalizado: `meunick`
///
/// Lança [FormatException] quando não dá pra reconhecer nada.
SteamIdInput parseSteamIdInput(String raw) {
  final String input = raw.trim();
  if (input.isEmpty) {
    throw const FormatException(
      "Cole o link do seu perfil ou seu ID da Steam.",
    );
  }

  final RegExp steamId64 = RegExp(r"^7656119\d{10}$");
  if (steamId64.hasMatch(input)) return SteamIdInput.steamId(input);

  final RegExpMatch? profileUrl = RegExp(
    r"steamcommunity\.com/profiles/(\d{17})",
  ).firstMatch(input);
  if (profileUrl != null) return SteamIdInput.steamId(profileUrl.group(1)!);

  final RegExpMatch? vanityUrl = RegExp(
    r"steamcommunity\.com/id/([^/?#\s]+)",
  ).firstMatch(input);
  if (vanityUrl != null) return SteamIdInput.vanity(vanityUrl.group(1)!);

  if (RegExp(r"^[A-Za-z0-9_-]{2,32}$").hasMatch(input)) {
    return SteamIdInput.vanity(input);
  }

  throw const FormatException(
    "Não reconheci esse formato. Use o link do perfil (steamcommunity.com/...) ou o SteamID64.",
  );
}
