import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../services/steam/steam_api.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";

/// Conectar a conta Steam: o usuário cola o link do perfil (ou o ID) e o
/// app importa a biblioteca inteira. Volta com a mensagem de sucesso.
class SteamConnectScreen extends StatefulWidget {
  const SteamConnectScreen({super.key});

  @override
  State<SteamConnectScreen> createState() => _SteamConnectScreenState();
}

class _SteamConnectScreenState extends State<SteamConnectScreen> {
  final TextEditingController _input = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _connect([String? value]) async {
    final String input = value ?? _input.text;
    if (input.trim().isEmpty) {
      setState(() => _error = "Cole o link do seu perfil ou seu ID da Steam.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final AppState state = context.read<AppState>();
    final NavigatorState navigator = Navigator.of(context);
    try {
      await state.connectSteam(input);
      final int count = state.library?.games.length ?? 0;
      navigator.pop(
        "Biblioteca importada! $count ${count == 1 ? "jogo" : "jogos"} no seu CritHit.",
      );
    } on SteamException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool demo = context.read<AppState>().isSteamDemo;

    return Scaffold(
      appBar: AppBar(title: const Text("Conectar Steam")),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text("Qual é o seu perfil?", style: textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  "A gente só lê o que é público no seu perfil: jogos, horas e conquistas. Nada de senha.",
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _input,
                  enabled: !_loading,
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _connect(),
                  decoration: InputDecoration(
                    labelText: "Seu perfil da Steam",
                    helperText: "Link do perfil, ID personalizado ou SteamID64",
                    hintText: "steamcommunity.com/id/seunick",
                    prefixIcon: const Icon(Icons.link_rounded),
                    errorText: _error,
                    errorMaxLines: 4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _connect,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _loading ? "Importando..." : "Importar biblioteca",
                  ),
                ),
                if (demo) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _loading ? null : () => _connect("crithit_demo"),
                    child: const Text("Usar perfil de demonstração"),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Modo offline: qualquer perfil carrega a biblioteca de demonstração (digite \"privado\" para ver o erro de perfil privado).",
                    style: textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 28),
                Text("Como achar seu perfil", style: textTheme.titleMedium),
                const SizedBox(height: 10),
                const _Step(
                  number: 1,
                  text:
                      "Na Steam (app ou site), clique no seu nome no topo e depois em \"Perfil\".",
                ),
                const _Step(
                  number: 2,
                  text:
                      "Copie o endereço da página — algo como steamcommunity.com/id/seunick ou steamcommunity.com/profiles/7656119...",
                ),
                const _Step(
                  number: 3,
                  text:
                      "Em \"Editar perfil\" › \"Privacidade\", deixe \"Meu perfil\" e \"Detalhes de jogos\" como Público. Sem isso a Steam não mostra seus jogos.",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Text("$number", style: textTheme.bodySmall),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
