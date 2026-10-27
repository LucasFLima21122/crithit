import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/library.dart";
import "../services/psn/psn_api.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../widgets/common.dart";
import "../widgets/platform_style.dart";

/// Conectar a conta PlayStation: o usuário digita o ID online da PSN e o
/// app importa jogos, troféus e platinas. Volta com a mensagem de sucesso.
class PsnConnectScreen extends StatefulWidget {
  const PsnConnectScreen({super.key});

  @override
  State<PsnConnectScreen> createState() => _PsnConnectScreenState();
}

class _PsnConnectScreenState extends State<PsnConnectScreen> {
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
      setState(() => _error = "Digite seu ID online da PSN.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final AppState state = context.read<AppState>();
    final NavigatorState navigator = Navigator.of(context);
    try {
      await state.connectPsn(input);
      final int count = state.psnLibrary?.games.length ?? 0;
      final int platinums = state.psnLibrary?.platinumCount ?? 0;
      navigator.pop(
        "Conta PSN importada! $count ${count == 1 ? "jogo" : "jogos"} e $platinums ${platinums == 1 ? "platina" : "platinas"} no seu CritHit.",
      );
    } on PsnException catch (error) {
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
    final bool demo = context.read<AppState>().isPsnDemo;

    return Scaffold(
      appBar: AppBar(title: const Text("Conectar PSN")),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Icon(
                      GamePlatform.psn.icon,
                      color: GamePlatform.psn.color,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Qual é o seu ID online?",
                        style: textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "A gente só lê o que é público na sua conta: jogos, troféus e tempo de jogo. Nada de senha.",
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
                    labelText: "ID online da PSN",
                    helperText:
                        "O nome que aparece no seu perfil do PlayStation",
                    hintText: "ex.: CritHit_Player",
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
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
                    _loading ? "Importando..." : "Importar conta PSN",
                  ),
                ),
                if (demo) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _loading ? null : () => _connect("crithit_demo"),
                    child: const Text("Usar conta de demonstração"),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Modo offline: qualquer ID carrega a conta de demonstração (digite \"privado\" para ver o erro de privacidade).",
                    style: textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 28),
                const SectionHeader(
                  title: "Antes de importar",
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
                ),
                const StepItem(
                  number: 1,
                  text:
                      "Seu ID online está no topo do perfil, no console ou no app PlayStation (é o nome com que seus amigos te acham).",
                ),
                const StepItem(
                  number: 2,
                  text:
                      "No PS5: Configurações › Usuários e contas › Privacidade › Ver e personalizar. Deixe \"Troféus\" e \"Jogos\" como Qualquer pessoa.",
                ),
                const StepItem(
                  number: 3,
                  text:
                      "Pronto: os jogos de PS4 e PS5 entram com tempo de jogo, e todos os jogos com troféu (inclusive PS3 e Vita) entram com progresso e platinas.",
                ),
                const SizedBox(height: 8),
                HudPanel(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "A Sony não tem uma API pública. O CritHit consulta a mesma API do app oficial do PlayStation, pelo servidor, e só enxerga o que a sua privacidade deixa qualquer pessoa ver.",
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
