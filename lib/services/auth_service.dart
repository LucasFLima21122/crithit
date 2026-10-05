import "package:supabase_flutter/supabase_flutter.dart";

import "../models/app_user.dart";

/// Erro de autenticação com mensagem já pronta para mostrar ao usuário.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Contrato de autenticação. As telas não sabem se estão falando com o
/// Supabase ou com a versão offline — só com esta interface.
abstract class AuthService {
  /// Sessão já existente ao abrir o app (ou `null` se ninguém logado).
  Future<AppUser?> restoreSession();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  /// Entra sem cadastro (login anônimo).
  Future<AppUser> signInAsGuest();

  Future<void> signOut();

  /// Salva (ou remove, com `null`) a conta Steam ligada ao perfil.
  Future<void> updateSteamId(String userId, String? steamId);
}

/// Autenticação em memória, usada no modo offline. Aceita qualquer e-mail
/// válido e senha com 6+ caracteres — o objetivo é demonstrar o fluxo.
class LocalAuthService implements AuthService {
  AppUser? _current;

  @override
  Future<AppUser?> restoreSession() async => _current;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final String name = email.split("@").first;
    return _current = AppUser(
      id: "local-user",
      email: email,
      displayName: name.isEmpty ? "Jogador" : name,
    );
  }

  @override
  Future<AppUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _current = AppUser(
      id: "local-user",
      email: email,
      displayName: displayName,
    );
  }

  @override
  Future<AppUser> signInAsGuest() async {
    return _current = const AppUser(
      id: "local-user",
      displayName: "Convidado",
      isGuest: true,
    );
  }

  @override
  Future<void> signOut() async => _current = null;

  @override
  Future<void> updateSteamId(String userId, String? steamId) async {
    final AppUser? current = _current;
    if (current == null) return;
    _current = steamId == null
        ? current.copyWith(clearSteamId: true)
        : current.copyWith(steamId: steamId);
  }
}

/// Autenticação real via Supabase Auth (e-mail/senha + login anônimo),
/// com os dados de perfil na tabela `public.profiles`.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  Future<AppUser?> restoreSession() async {
    final User? user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _loadProfile(user);
    } on Exception {
      // Sessão salva mas inválida (ex.: usuário apagado no painel).
      await _client.auth.signOut();
      return null;
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final AuthResponse response = await _guard(
      () => _client.auth.signInWithPassword(email: email, password: password),
    );
    return _loadProfile(response.user!);
  }

  @override
  Future<AppUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final AuthResponse response = await _guard(
      () => _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{"display_name": displayName},
      ),
    );
    if (response.session == null) {
      throw const AuthFailure(
        "Conta criada! Confirme o link que enviamos pro seu e-mail e depois entre.",
      );
    }
    return _loadProfile(response.user!);
  }

  @override
  Future<AppUser> signInAsGuest() async {
    final AuthResponse response = await _guard(
      () => _client.auth.signInAnonymously(
        data: <String, dynamic>{"display_name": "Convidado"},
      ),
    );
    return _loadProfile(response.user!);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> updateSteamId(String userId, String? steamId) async {
    await _client
        .from("profiles")
        .update(<String, dynamic>{"steam_id": steamId})
        .eq("id", userId);
  }

  Future<AppUser> _loadProfile(User user) async {
    Map<String, dynamic>? row = await _client
        .from("profiles")
        .select()
        .eq("id", user.id)
        .maybeSingle();

    // O perfil é criado por trigger no banco; se por algum motivo ele não
    // existir (ex.: usuário criado antes da migration), criamos aqui.
    row ??= await _client
        .from("profiles")
        .insert(<String, dynamic>{
          "id": user.id,
          "display_name":
              (user.userMetadata?["display_name"] as String?) ??
              user.email?.split("@").first ??
              "Jogador",
        })
        .select()
        .single();

    return AppUser(
      id: user.id,
      email: user.email,
      displayName: row["display_name"] as String,
      steamId: row["steam_id"] as String?,
      isGuest: user.isAnonymous,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (error) {
      throw AuthFailure(_translate(error));
    } on Exception {
      throw const AuthFailure(
        "Sem conexão com o servidor. Confere a internet e tenta de novo?",
      );
    }
  }

  String _translate(AuthException error) {
    final String message = error.message.toLowerCase();
    if (message.contains("invalid login credentials")) {
      return "E-mail ou senha incorretos.";
    }
    if (message.contains("email not confirmed")) {
      return "Confirme seu e-mail antes de entrar (olha a caixa de spam).";
    }
    if (message.contains("already registered") ||
        message.contains("already been registered")) {
      return "Esse e-mail já tem conta. Que tal entrar?";
    }
    if (message.contains("anonymous sign-ins are disabled")) {
      return "O modo convidado está desligado no servidor.";
    }
    if (message.contains("password")) {
      return "A senha precisa ter pelo menos 6 caracteres.";
    }
    if (message.contains("rate limit")) {
      return "Muitas tentativas seguidas. Espera um minutinho e tenta de novo.";
    }
    return "Deu ruim aqui do nosso lado. Tenta de novo?";
  }
}
