import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/redefinir_senha_screen.dart';

/// Adicione esta chave ao MaterialApp(navigatorKey: ...).
final GlobalKey<NavigatorState> wildlifeNavigatorKey = GlobalKey<NavigatorState>();

/// Inicie depois de Supabase.initialize(), antes de runApp().
/// O Supabase Flutter processa o link; este listener abre a tela apropriada.
class RecuperacaoSenhaListener {
  static StreamSubscription<AuthState>? _subscription;
  static bool _telaAberta = false;

  static void iniciar() {
    if (_subscription != null) return;
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
          (data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          _abrirTela();
        }
      },
      onError: (Object erro, StackTrace stackTrace) {
        debugPrint('Erro ao acompanhar recuperação de senha: $erro');
      },
    );
  }

  static void _abrirTela() {
    if (_telaAberta) return;
    _telaAberta = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = wildlifeNavigatorKey.currentState;
      if (navigator == null) {
        _telaAberta = false;
        debugPrint('Navigator ainda não está pronto para a recuperação.');
        return;
      }
      navigator
          .push<void>(MaterialPageRoute<void>(
        builder: (_) => const RedefinirSenhaScreen(),
      ))
          .whenComplete(() => _telaAberta = false);
    });
  }

  static Future<void> encerrar() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
