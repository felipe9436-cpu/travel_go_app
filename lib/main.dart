import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/redefinir_senha_screen.dart';
import 'theme/app_theme.dart';

// Controla a recuperação de senha, mesmo se o link abrir o app fechado.
final ValueNotifier<bool> recuperacaoSenhaAtiva = ValueNotifier<bool>(false);
final GlobalKey<NavigatorState> wildlifeNavigatorKey = GlobalKey<NavigatorState>();
StreamSubscription<AuthState>? _recuperacaoSubscription;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://blexgukorfdjgzkducnt.supabase.co';
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );

    // Registra o listener ANTES de construir a interface para não perder
    // o retorno do link de recuperação durante a abertura do aplicativo.
    _recuperacaoSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
          (estado) {
        if (estado.event == AuthChangeEvent.passwordRecovery) {
          recuperacaoSenhaAtiva.value = true;

          // Fecha outras telas abertas (como "Esqueceu a senha?").
          WidgetsBinding.instance.addPostFrameCallback((_) {
            wildlifeNavigatorKey.currentState?.popUntil((rota) => rota.isFirst);
          });
        } else if (estado.event == AuthChangeEvent.signedOut) {
          recuperacaoSenhaAtiva.value = false;
        }
      },
      onError: (Object erro, StackTrace stackTrace) {
        debugPrint('Erro ao receber link de recuperação: $erro');
      },
    );
  }

  runApp(WildLifeApp(supabaseConfigurado: supabasePublishableKey.isNotEmpty));
}

class WildLifeApp extends StatelessWidget {
  const WildLifeApp({super.key, required this.supabaseConfigurado});

  final bool supabaseConfigurado;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: wildlifeNavigatorKey,
      title: 'WildLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: supabaseConfigurado
          ? const AuthGate()
          : const _SupabaseNaoConfiguradoScreen(),
    );
  }
}

/// Mantém a navegação sincronizada com a sessão do Supabase.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final GoTrueClient _auth;
  StreamSubscription<AuthState>? _authSubscription;
  Session? _sessao;

  @override
  void initState() {
    super.initState();
    _auth = Supabase.instance.client.auth;
    _sessao = _auth.currentSession;

    _authSubscription = _auth.onAuthStateChange.listen((estado) {
      if (!mounted) return;
      setState(() {
        _sessao = estado.event == AuthChangeEvent.signedOut
            ? null
            : estado.session;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: recuperacaoSenhaAtiva,
      builder: (context, recuperando, _) {
        if (recuperando) {
          return const RedefinirSenhaScreen(key: ValueKey('redefinir-senha'));
        }
        if (_sessao != null) {
          return const HomeScreen(key: ValueKey('home-autenticada'));
        }
        return const LoginScreen(key: ValueKey('login-desconectado'));
      },
    );
  }
}

/// Mostra um aviso se a chave pública não foi informada no Run Configuration.
class _SupabaseNaoConfiguradoScreen extends StatelessWidget {
  const _SupabaseNaoConfiguradoScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key_off_outlined, size: 46),
                SizedBox(height: 18),
                Text(
                  'Configure o Supabase para entrar no WildLife',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Adicione SUPABASE_PUBLISHABLE_KEY às configurações de execução '
                      'do Android Studio usando --dart-define. Depois reinicie o aplicativo.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
