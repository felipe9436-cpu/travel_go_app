import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';

/// Exibida quando o Supabase confirma o link de recuperação.
class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _salvando = false;
  bool _concluida = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _salvarNovaSenha() async {
    if (_salvando || !_formKey.currentState!.validate()) return;
    if (Supabase.instance.client.auth.currentSession == null) {
      _avisar('Este link não é mais válido. Solicite outro e-mail de recuperação.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _senhaController.text),
      );
      if (!mounted) return;
      setState(() => _concluida = true);
    } on AuthException catch (erro) {
      if (mounted) _avisar('Não foi possível alterar a senha: ${erro.message}');
    } catch (_) {
      if (mounted) _avisar('Falha de conexão. Tente novamente.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _voltarAoLogin() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      // O AuthGate no main.dart recebe signedOut e mostra o LoginScreen.
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (erro) {
      if (mounted) _avisar('Não foi possível sair: ${erro.message}');
    } catch (_) {
      if (mounted) _avisar('Falha ao sair. Tente novamente.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  InputDecoration _campo(String dica, IconData icone) {
    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icone, color: AppColors.textSecondary),
      suffixIcon: IconButton(
        tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
        onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
        icon: Icon(
          _mostrarSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
        ),
      ),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Icon(
                      _concluida ? Icons.verified_rounded : Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 43,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'WildLife',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _concluida ? 'Senha atualizada!' : 'Criar nova senha',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _concluida
                        ? 'Tudo certo. Agora você pode entrar com a senha que acabou de criar.'
                        : 'Escolha uma senha nova para voltar a planejar suas viagens.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _concluida
                        ? _botao(
                      titulo: 'VOLTAR AO LOGIN',
                      icone: Icons.arrow_back_rounded,
                      acao: _salvando ? null : _voltarAoLogin,
                    )
                        : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'NOVA SENHA',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _senhaController,
                            obscureText: !_mostrarSenha,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: _campo('Mínimo de 8 caracteres', Icons.lock_outline_rounded),
                            validator: (valor) {
                              if (valor == null || valor.length < 8) return 'Use pelo menos 8 caracteres.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'CONFIRMAR SENHA',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _confirmarController,
                            obscureText: !_mostrarSenha,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: _campo('Repita a nova senha', Icons.verified_user_outlined),
                            validator: (valor) {
                              if (valor != _senhaController.text) return 'As senhas não coincidem.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _botao(
                            titulo: _salvando ? 'SALVANDO...' : 'SALVAR NOVA SENHA',
                            icone: Icons.check_rounded,
                            acao: _salvando ? null : _salvarNovaSenha,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botao({
    required String titulo,
    required IconData icone,
    required VoidCallback? acao,
  }) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(15),
        ),
        child: FilledButton.icon(
          onPressed: acao,
          icon: _salvando
              ? const SizedBox(
            height: 19,
            width: 19,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
          )
              : Icon(icone, size: 19),
          label: Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.navy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
    );
  }
}
