import 'package:supabase_flutter/supabase_flutter.dart';

/// Centraliza as operações de autenticação do WildLife.
///
/// Requer Supabase.initialize() no main.dart antes de usar o serviço.
class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get usuarioAtual => _client.auth.currentUser;

  Session? get sessaoAtual => _client.auth.currentSession;

  bool get estaLogado => sessaoAtual != null;

  Stream<AuthState> get mudancasAutenticacao =>
      _client.auth.onAuthStateChange;

  /// Entra com e-mail e senha.
  Future<AuthResponse> entrar({
    required String email,
    required String senha,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: senha,
    );
  }

  /// Cria uma conta. Dependendo das configurações do Supabase,
  /// será necessário confirmar o e-mail antes de entrar.
  Future<AuthResponse> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: senha,
      data: {'nome': nome.trim()},
    );
  }

  /// Envia um e-mail de recuperação de senha.
  ///
  /// Configure a URL de redirecionamento no painel do Supabase
  /// antes de usar o fluxo de redefinição no aplicativo.
  Future<void> recuperarSenha({
    required String email,
    String? redirectTo,
  }) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  /// Define a nova senha após o usuário abrir o link de recuperação.
  Future<UserResponse> atualizarSenha(String novaSenha) {
    return _client.auth.updateUser(
      UserAttributes(password: novaSenha),
    );
  }

  /// Inicia OAuth. O provedor precisa estar habilitado no Supabase.
  /// No Android/iOS, configure também o deep link de retorno.
  Future<bool> entrarComGoogle({String? redirectTo}) {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  Future<bool> entrarComFacebook({String? redirectTo}) {
    return _client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: redirectTo,
    );
  }

  Future<bool> entrarComApple({String? redirectTo}) {
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: redirectTo,
    );
  }

  /// Encerra a sessão atual.
  Future<void> sair() => _client.auth.signOut();
}
