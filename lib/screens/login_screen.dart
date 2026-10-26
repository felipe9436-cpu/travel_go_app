import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import 'cadastro_screen.dart';
import 'recuperar_senha_screen.dart';

/// Tela de entrada do WildLife com autenticação Supabase.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _mostrarSenha = false;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _entrar() async {
    if (_carregando || !_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      final resposta = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );
      if (!mounted) return;
      if (resposta.session == null) {
        _avisar('Não foi possível iniciar a sessão. Verifique seu e-mail.');
        return;
      }
// O AuthGate em main.dart observa a sessão e exibe a Home.
// Não abra uma nova rota aqui: isso impediria o retorno ao Login no logout.
      debugPrint('LOGIN: sessão criada; aguardando AuthGate.');
    } on AuthException catch (erro) {
      if (mounted) _avisar(erro.message);
    } catch (_) {
      if (mounted) _avisar('Não foi possível entrar. Confira sua conexão e tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _entrarSocial(OAuthProvider provedor) async {
    if (_carregando) return;
    setState(() => _carregando = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(provedor);
// O provedor abre o navegador. O retorno ao app requer deep links
// e um listener de sessão configurados no aplicativo.
    } on AuthException catch (erro) {
      if (mounted) _avisar(erro.message);
    } catch (_) {
      if (mounted) _avisar('Não foi possível abrir o provedor de login.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _botaoSocial(String provedor, Widget simbolo, OAuthProvider tipo) {
    return OutlinedButton(
      onPressed: _carregando ? null : () => _entrarSocial(tipo),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          simbolo,
          const SizedBox(height: 6),
          Text(provedor, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const dourado = AppColors.primary;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -130,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      dourado.withValues(alpha: 0.13),
                      dourado.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -170,
            left: -150,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.12),
                      AppColors.blue.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: dourado.withValues(alpha: 0.22),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.travel_explore_rounded,
                            color: AppColors.navy,
                            size: 39,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'WildLife',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Sua próxima aventura começa aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 35),
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 26,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bem-vindo de volta',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Entre para continuar planejando suas viagens.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                'E-MAIL',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 9),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: _campoDecoracao(
                                  'seuemail@exemplo.com',
                                  Icons.mail_outline_rounded,
                                ),
                                validator: (valor) {
                                  final email = valor?.trim() ?? '';
                                  if (email.isEmpty) return 'Informe seu e-mail.';
                                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                                    return 'Informe um e-mail válido.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 21),
                              const Text(
                                'SENHA',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 9),
                              TextFormField(
                                controller: _senhaController,
                                obscureText: !_mostrarSenha,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _entrar(),
                                autofillHints: const [AutofillHints.password],
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: _campoDecoracao(
                                  'Digite sua senha',
                                  Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
                                    onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                                    icon: Icon(
                                      _mostrarSenha
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                validator: (valor) {
                                  if (valor == null || valor.isEmpty) {
                                    return 'Informe sua senha.';
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const RecuperarSenhaScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'Esqueceu a senha?',
                                    style: TextStyle(color: dourado, fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                height: 54,
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.goldGradient,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: FilledButton(
                                    onPressed: _carregando ? null : _entrar,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: AppColors.navy,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_carregando)
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                                          )
                                        else ...[
                                          const Text(
                                            'ENTRAR',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.4,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.arrow_forward_rounded, size: 19),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.borderLight)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OU CONTINUE COM',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.borderLight)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _botaoSocial(
                              'Google',
                              const Text('G', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                              OAuthProvider.google,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _botaoSocial(
                              'Facebook',
                              const Text('f', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                              OAuthProvider.facebook,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _botaoSocial(
                              'Apple',
                              const Icon(Icons.apple_rounded, size: 24, color: AppColors.textPrimary),
                              OAuthProvider.apple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Ainda não tem uma conta?',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const CadastroScreen()),
                            ),
                            child: const Text(
                              'Criar conta',
                              style: TextStyle(
                                color: dourado,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'EXPLORE  •  PLANEJE  •  VIAJE',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _campoDecoracao(String dica, IconData icone) {
    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icone, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
