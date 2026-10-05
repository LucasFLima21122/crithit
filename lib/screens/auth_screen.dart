import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../services/app_services.dart";
import "../services/auth_service.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";

/// Login e cadastro na mesma tela (alterna entre os dois modos).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.startWithSignUp = false});

  final bool startWithSignUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  late bool _signUp = widget.startWithSignUp;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final AppState state = context.read<AppState>();
    final NavigatorState navigator = Navigator.of(context);
    try {
      if (_signUp) {
        await state.signUp(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
      } else {
        await state.signIn(_email.text.trim(), _password.text);
      }
      // Logou: volta pra raiz, onde o AuthGate já mostra o app.
      navigator.popUntil((route) => route.isFirst);
    } on AuthFailure catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? "";
    if (email.isEmpty) return "Informe seu e-mail.";
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email)) {
      return "Esse e-mail não parece válido.";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? "").length < 6) return "Mínimo de 6 caracteres.";
    return null;
  }

  String? _validateName(String? value) {
    final String name = value?.trim() ?? "";
    if (name.length < 2) return "Como você quer aparecer nas reviews?";
    if (name.length > 30) return "Máximo de 30 caracteres.";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _signUp ? "Criar conta" : "Bem-vindo de volta",
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _signUp
                          ? "Leva 10 segundos. Depois é só sair dando nota."
                          : "Entre pra continuar suas críticas.",
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_signUp) ...[
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: _validateName,
                        decoration: const InputDecoration(
                          labelText: "Nome de exibição",
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: "E-mail",
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: "Senha",
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? "Mostrar senha"
                              : "Esconder senha",
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_signUp ? "Criar conta" : "Entrar"),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                              _signUp = !_signUp;
                              _error = null;
                            }),
                      child: Text(
                        _signUp
                            ? "Já tenho conta — entrar"
                            : "Ainda não tenho conta — criar",
                      ),
                    ),
                    if (context.read<AppState>().mode ==
                        BackendMode.offline) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Modo offline: qualquer e-mail válido e senha com 6+ caracteres funcionam.",
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
