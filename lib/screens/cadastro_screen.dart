
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

import '../theme/app_colors.dart';

/// Cadastro de usuários do WildLife com Supabase Auth.
class CadastroScreen extends StatefulWidget {
const CadastroScreen({super.key});

@override
State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
final _formKey = GlobalKey<FormState>();
final _nomeController = TextEditingController();
final _emailController = TextEditingController();
final _senhaController = TextEditingController();
final _confirmacaoController = TextEditingController();
bool _mostrarSenha = false;
bool _mostrarConfirmacao = false;
bool _cadastrando = false;

@override
void dispose() {
_nomeController.dispose();
_emailController.dispose();
_senhaController.dispose();
_confirmacaoController.dispose();
super.dispose();
}

void _avisar(String mensagem) {
ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(SnackBar(content: Text(mensagem)));
}

Future<void> _cadastrar() async {
if (_cadastrando || !_formKey.currentState!.validate()) return;

FocusScope.of(context).unfocus();
setState(() => _cadastrando = true);

try {
final resposta = await AuthService().cadastrar(
nome: _nomeController.text.trim(),
email: _emailController.text.trim(),
senha: _senhaController.text,
);

if (!mounted) return;
if (resposta.user == null) {
_avisar('Não foi possível concluir o cadastro. Tente novamente.');
return;
}

if (resposta.session != null) {
// O AuthGate no main.dart identifica a nova sessão e abre a Home.
return;
}

// Com confirmação de e-mail ativa, normalmente não há sessão imediata.
// A mensagem evita afirmar que um e-mail foi enviado quando o servidor
// pode ocultar a existência de uma conta já cadastrada.
_avisar('Confira seu e-mail para confirmar a conta. Depois, faça login.');
Navigator.of(context).pop();
} on AuthException catch (erro) {
if (!mounted) return;
final mensagem = switch (erro.statusCode) {
'422' => 'Verifique os dados ou tente outro e-mail.',
'429' => 'Muitas tentativas. Aguarde um pouco e tente novamente.',
_ => 'Não foi possível cadastrar: ${erro.message}',
};
_avisar(mensagem);
} catch (_) {
if (!mounted) return;
_avisar('Erro de conexão. Verifique sua internet e tente novamente.');
} finally {
if (mounted) setState(() => _cadastrando = false);
}
}

InputDecoration _decoracao(String dica, IconData icone, {Widget? sufixo}) {
OutlineInputBorder borda(Color cor, [double largura = 1]) => OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(color: cor, width: largura),
);
return InputDecoration(
hintText: dica,
hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
prefixIcon: Icon(icone, color: AppColors.textSecondary, size: 20),
suffixIcon: sufixo,
filled: true,
fillColor: AppColors.surfaceElevated,
contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
enabledBorder: borda(AppColors.borderLight),
focusedBorder: borda(AppColors.primary, 1.5),
errorBorder: borda(AppColors.error),
focusedErrorBorder: borda(AppColors.error, 1.5),
);
}

Widget _rotulo(String texto) => Padding(
padding: const EdgeInsets.only(bottom: 9),
child: Text(
texto,
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 11,
fontWeight: FontWeight.w700,
letterSpacing: 1.1,
),
),
);

Widget _botaoSocial(String nome, Widget simbolo) => OutlinedButton(
onPressed: () => _avisar(
'Cadastro com $nome estará disponível após configurar o Supabase Auth.',
),
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
Text(nome, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
],
),
);

@override
Widget build(BuildContext context) {
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
gradient: RadialGradient(colors: [
AppColors.primary.withValues(alpha: 0.13),
AppColors.primary.withValues(alpha: 0),
]),
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
gradient: RadialGradient(colors: [
AppColors.blue.withValues(alpha: 0.12),
AppColors.blue.withValues(alpha: 0),
]),
),
),
),
),
SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 440),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Align(
alignment: Alignment.centerLeft,
child: IconButton.filledTonal(
tooltip: 'Voltar ao login',
onPressed: _cadastrando ? null : () => Navigator.of(context).pop(),
icon: const Icon(Icons.arrow_back_rounded),
),
),
const SizedBox(height: 8),
Center(
child: Container(
width: 70,
height: 70,
decoration: BoxDecoration(
gradient: AppColors.goldGradient,
borderRadius: BorderRadius.circular(23),
boxShadow: [
BoxShadow(
color: AppColors.primary.withValues(alpha: 0.22),
blurRadius: 30,
offset: const Offset(0, 12),
),
],
),
child: const Icon(
Icons.travel_explore_rounded,
color: AppColors.navy,
size: 38,
),
),
),
const SizedBox(height: 17),
const Text(
'WildLife',
textAlign: TextAlign.center,
style: TextStyle(
color: AppColors.textPrimary,
fontSize: 28,
fontWeight: FontWeight.w900,
letterSpacing: 3,
),
),
const SizedBox(height: 7),
const Text(
'Sua próxima aventura começa aqui.',
textAlign: TextAlign.center,
style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
),
const SizedBox(height: 28),
Container(
padding: const EdgeInsets.fromLTRB(24, 27, 24, 24),
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
'Crie sua conta',
style: TextStyle(
color: AppColors.textPrimary,
fontSize: 23,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
const Text(
'Comece a organizar viagens e descobrir novos destinos.',
style: TextStyle(
color: AppColors.textSecondary,
fontSize: 13,
height: 1.5,
),
),
const SizedBox(height: 25),
_rotulo('NOME COMPLETO'),
TextFormField(
controller: _nomeController,
textCapitalization: TextCapitalization.words,
textInputAction: TextInputAction.next,
autofillHints: const [AutofillHints.name],
style: const TextStyle(color: AppColors.textPrimary),
decoration: _decoracao('Como podemos chamar você?', Icons.person_outline_rounded),
validator: (valor) {
if ((valor ?? '').trim().length < 2) return 'Informe seu nome.';
return null;
},
),
const SizedBox(height: 19),
_rotulo('E-MAIL'),
TextFormField(
controller: _emailController,
keyboardType: TextInputType.emailAddress,
textInputAction: TextInputAction.next,
autofillHints: const [AutofillHints.email],
style: const TextStyle(color: AppColors.textPrimary),
decoration: _decoracao('seuemail@exemplo.com', Icons.mail_outline_rounded),
validator: (valor) {
final email = (valor ?? '').trim();
if (email.isEmpty) return 'Informe seu e-mail.';
if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
return 'Informe um e-mail válido.';
}
return null;
},
),
const SizedBox(height: 19),
_rotulo('SENHA'),
TextFormField(
controller: _senhaController,
obscureText: !_mostrarSenha,
textInputAction: TextInputAction.next,
autofillHints: const [AutofillHints.newPassword],
style: const TextStyle(color: AppColors.textPrimary),
decoration: _decoracao(
'Mínimo de 8 caracteres',
Icons.lock_outline_rounded,
sufixo: IconButton(
tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
icon: Icon(
_mostrarSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined,
color: AppColors.textSecondary,
),
),
),
validator: (valor) {
if ((valor ?? '').length < 8) return 'Use pelo menos 8 caracteres.';
return null;
},
),
const SizedBox(height: 19),
_rotulo('CONFIRMAR SENHA'),
TextFormField(
controller: _confirmacaoController,
obscureText: !_mostrarConfirmacao,
textInputAction: TextInputAction.done,
onFieldSubmitted: (_) {
if (!_cadastrando) _cadastrar();
},
autofillHints: const [AutofillHints.newPassword],
style: const TextStyle(color: AppColors.textPrimary),
decoration: _decoracao(
'Digite a senha novamente',
Icons.verified_user_outlined,
sufixo: IconButton(
tooltip: _mostrarConfirmacao ? 'Ocultar confirmação' : 'Mostrar confirmação',
onPressed: () => setState(() => _mostrarConfirmacao = !_mostrarConfirmacao),
icon: Icon(
_mostrarConfirmacao
? Icons.visibility_off_outlined
    : Icons.visibility_outlined,
color: AppColors.textSecondary,
),
),
),
validator: (valor) {
if ((valor ?? '').isEmpty) return 'Confirme sua senha.';
if (valor != _senhaController.text) return 'As senhas não coincidem.';
return null;
},
),
const SizedBox(height: 26),
SizedBox(
height: 54,
width: double.infinity,
child: DecoratedBox(
decoration: BoxDecoration(
gradient: AppColors.goldGradient,
borderRadius: BorderRadius.circular(15),
),
child: FilledButton(
onPressed: _cadastrando ? null : _cadastrar,
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
if (_cadastrando) ...[
const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
color: AppColors.navy,
),
),
const SizedBox(width: 10),
],
Text(_cadastrando ? 'CADASTRANDO...' : 'CRIAR CONTA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4)),
if (!_cadastrando) ...[
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
const Row(
children: [
Expanded(child: Divider(color: AppColors.borderLight)),
Padding(
padding: EdgeInsets.symmetric(horizontal: 14),
child: Text(
'OU CADASTRE-SE COM',
style: TextStyle(
color: AppColors.textSecondary,
fontSize: 10,
fontWeight: FontWeight.w700,
letterSpacing: 1.3,
),
),
),
Expanded(child: Divider(color: AppColors.borderLight)),
],
),
const SizedBox(height: 18),
Row(
children: [
Expanded(child: _botaoSocial('Google', const Text('G', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.textPrimary)))),
const SizedBox(width: 10),
Expanded(child: _botaoSocial('Facebook', const Text('f', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)))),
const SizedBox(width: 10),
Expanded(child: _botaoSocial('Apple', const Icon(Icons.apple_rounded, size: 24, color: AppColors.textPrimary))),
],
),
const SizedBox(height: 23),
Wrap(
alignment: WrapAlignment.center,
crossAxisAlignment: WrapCrossAlignment.center,
children: [
const Text('Já tem uma conta?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
TextButton(
onPressed: _cadastrando ? null : () => Navigator.of(context).pop(),
child: const Text('Entrar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
),
],
),
const SizedBox(height: 10),
const Center(
child: Text(
'EXPLORE  •  PLANEJE  •  VIAJE',
style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 2.2, fontWeight: FontWeight.w700),
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
}
