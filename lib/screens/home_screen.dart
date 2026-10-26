


import 'package:flutter/material.dart';

import '../models/viagem.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_card.dart';
import '../widgets/viagem_card.dart';

import 'avaliacao_screen.dart';
import 'checklist_screen.dart';
import 'destinos_screen.dart';
import 'gastos_screen.dart';
import 'hospedagem_screen.dart';
import 'roteiro_screen.dart';

class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
bool _saindo = false;
bool _carregandoViagens = true;
final StorageService _storage = StorageService();
int _paginaSelecionada = 0;
int _contadorViagens = 0;
final List<Viagem> _viagens = [];
String? _viagemSelecionadaId;

@override
void initState() {
super.initState();
_carregarViagens();
}

void _mostrarErro(String mensagem) {
if (!mounted) return;
ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(SnackBar(content: Text(mensagem)));
}

Future<void> _carregarViagens() async {
try {
final viagens = await _storage.getViagens();
if (!mounted) return;
setState(() {
_viagens..clear()..addAll(viagens);
if (!_viagens.any((v) => v.id == _viagemSelecionadaId)) {
_viagemSelecionadaId = _viagens.isEmpty ? null : _viagens.first.id;
}
});
} catch (erro) {
_mostrarErro('Erro ao carregar viagens: $erro');
} finally {
if (mounted) setState(() => _carregandoViagens = false);
}
}

Viagem? get _viagemSelecionada {
for (final viagem in _viagens) {
if (viagem.id == _viagemSelecionadaId) return viagem;
}
return null;
}

String _novoId() =>
'${DateTime.now().microsecondsSinceEpoch}_${++_contadorViagens}';

static const _destinosDesktop = <NavigationRailDestination>[
NavigationRailDestination(
icon: Icon(Icons.home_outlined),
selectedIcon: Icon(Icons.home),
label: Text('Início'),
),
NavigationRailDestination(
icon: Icon(Icons.place_outlined),
selectedIcon: Icon(Icons.place),
label: Text('Destinos'),
),
NavigationRailDestination(
icon: Icon(Icons.route_outlined),
selectedIcon: Icon(Icons.route),
label: Text('Roteiro'),
),
NavigationRailDestination(
icon: Icon(Icons.hotel_outlined),
selectedIcon: Icon(Icons.hotel),
label: Text('Hospedagem'),
),
NavigationRailDestination(
icon: Icon(Icons.account_balance_wallet_outlined),
selectedIcon: Icon(Icons.account_balance_wallet),
label: Text('Gastos'),
),
NavigationRailDestination(
icon: Icon(Icons.checklist_outlined),
selectedIcon: Icon(Icons.checklist),
label: Text('Checklist'),
),
NavigationRailDestination(
icon: Icon(Icons.star_outline),
selectedIcon: Icon(Icons.star),
label: Text('Avaliações'),
),
];

void _selecionarPagina(int index) {
if (index < 0 || index >= 7) return;
setState(() => _paginaSelecionada = index);
}

Future<void> _atualizarOrcamento(double valor) async {
final selecionada = _viagemSelecionada;
if (selecionada == null) return;
final atualizada = selecionada.copyWith(orcamento: valor);
try {
await _storage.salvarViagem(atualizada);
if (!mounted) return;
setState(() {
final indice = _viagens.indexWhere((v) => v.id == selecionada.id);
if (indice >= 0) _viagens[indice] = atualizada;
});
} catch (erro) {
_mostrarErro('Não foi possível atualizar o orçamento: $erro');
}
}

void _selecionarViagem(Viagem viagem) {
setState(() => _viagemSelecionadaId = viagem.id);
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Viagem "${viagem.nome}" selecionada.')),
);
}

double _lerValor(String texto) {
var valor = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
if (valor.contains(',')) {
valor = valor.replaceAll('.', '').replaceAll(',', '.');
}
return double.tryParse(valor) ?? 0;
}

String _dataCurta(DateTime data) {
final dia = data.day.toString().padLeft(2, '0');
final mes = data.month.toString().padLeft(2, '0');
return '$dia/$mes/${data.year}';
}

Future<void> _abrirFormularioViagem({Viagem? viagem}) async {
final nome = TextEditingController(text: viagem?.nome ?? '');
final destino = TextEditingController(text: viagem?.destino ?? '');
final viajantes = TextEditingController(
text: '${viagem?.numeroViajantes ?? 1}',
);
final orcamento = TextEditingController(
text: viagem == null ? '' : viagem.orcamento.toStringAsFixed(2),
);

DateTimeRange? periodo = viagem == null
? null
    : DateTimeRange(start: viagem.dataInicio, end: viagem.dataFim);
String? erro;
bool salvando = false;

await showModalBottomSheet<void>(
context: context,
isScrollControlled: true,
showDragHandle: true,
backgroundColor: AppColors.surface,
builder: (sheetContext) => StatefulBuilder(
builder: (modalContext, atualizar) => SafeArea(
child: SingleChildScrollView(
padding: EdgeInsets.fromLTRB(
22,
8,
22,
MediaQuery.viewInsetsOf(modalContext).bottom + 26,
),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
viagem == null ? 'Nova viagem' : 'Editar viagem',
style: Theme.of(modalContext).textTheme.headlineSmall
    ?.copyWith(fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
const Text(
'Organize sua próxima experiência.',
style: TextStyle(color: AppColors.textSecondary),
),
const SizedBox(height: 22),
TextField(
controller: nome,
textCapitalization: TextCapitalization.words,
decoration: const InputDecoration(
labelText: 'Nome da viagem *',
prefixIcon: Icon(Icons.luggage_outlined),
hintText: 'Ex.: Férias de julho',
),
),
const SizedBox(height: 12),
TextField(
controller: destino,
textCapitalization: TextCapitalization.words,
decoration: const InputDecoration(
labelText: 'Destino principal *',
prefixIcon: Icon(Icons.place_outlined),
hintText: 'Ex.: Rio de Janeiro',
),
),
const SizedBox(height: 12),
OutlinedButton.icon(
onPressed: () async {
final datas = await showDateRangePicker(
context: modalContext,
firstDate: DateTime(2020),
lastDate: DateTime(2100),
initialDateRange: periodo,
helpText: 'Datas da viagem',
saveText: 'CONFIRMAR',
);
if (datas != null && modalContext.mounted) {
atualizar(() => periodo = datas);
}
},
icon: const Icon(Icons.date_range_outlined),
label: Text(
periodo == null
? 'Selecionar datas *'
    : '${_dataCurta(periodo!.start)} — ${_dataCurta(periodo!.end)}',
),
),
const SizedBox(height: 12),
TextField(
controller: viajantes,
keyboardType: TextInputType.number,
decoration: const InputDecoration(
labelText: 'Número de viajantes',
prefixIcon: Icon(Icons.people_outline),
),
),
const SizedBox(height: 12),
TextField(
controller: orcamento,
keyboardType:
const TextInputType.numberWithOptions(decimal: true),
decoration: const InputDecoration(
labelText: 'Orçamento total (R\$)',
prefixIcon: Icon(Icons.payments_outlined),
),
),
if (erro != null) ...[
const SizedBox(height: 12),
Text(erro!, style: const TextStyle(color: AppColors.error)),
],
const SizedBox(height: 24),
SizedBox(
width: double.infinity,
child: FilledButton.icon(
onPressed: salvando ? null : () async {
final nomeValor = nome.text.trim();
final destinoValor = destino.text.trim();
final pessoas = int.tryParse(viajantes.text.trim());
if (nomeValor.isEmpty || destinoValor.isEmpty) {
atualizar(() =>
erro = 'Preencha o nome e o destino da viagem.');
return;
}
if (periodo == null) {
atualizar(() => erro = 'Selecione as datas da viagem.');
return;
}
if (pessoas == null || pessoas < 1) {
atualizar(() => erro = 'Informe ao menos um viajante.');
return;
}

final atualizada = Viagem(
id: viagem?.id ?? _novoId(),
nome: nomeValor,
destino: destinoValor,
dataInicio: periodo!.start,
dataFim: periodo!.end,
numeroViajantes: pessoas,
orcamento: _lerValor(orcamento.text),
imagemUrl: viagem?.imagemUrl,
);

atualizar(() {
salvando = true;
erro = null;
});
try {
await _storage.salvarViagem(atualizada);
if (!mounted || !sheetContext.mounted) return;
setState(() {
final indice = _viagens.indexWhere((item) => item.id == atualizada.id);
if (indice < 0) {
_viagens.insert(0, atualizada);
} else {
_viagens[indice] = atualizada;
}
_viagemSelecionadaId = atualizada.id;
});
Navigator.pop(sheetContext);
} catch (falha) {
if (sheetContext.mounted) {
atualizar(() => erro = 'Não foi possível salvar: $falha');
}
} finally {
if (sheetContext.mounted) atualizar(() => salvando = false);
}
},
icon: Icon(
viagem == null ? Icons.add : Icons.save_outlined,
),
label: Text(
viagem == null ? 'Criar viagem' : 'Salvar alterações',
),
),
),
],
),
),
),
),
);

await Future<void>.delayed(const Duration(milliseconds: 350));
nome.dispose();
destino.dispose();
viajantes.dispose();
orcamento.dispose();
}

Future<void> _confirmarExclusaoViagem(Viagem viagem) async {
final confirmar = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Excluir viagem?'),
content: Text('Deseja excluir "${viagem.nome}" da sua lista?'),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Cancelar'),
),
FilledButton(
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text('Excluir'),
),
],
),
);

if (confirmar != true || !mounted) return;
try {
await _storage.deletarViagem(viagem.id);
if (!mounted) return;
setState(() {
_viagens.removeWhere((item) => item.id == viagem.id);
if (_viagemSelecionadaId == viagem.id) {
_viagemSelecionadaId = _viagens.isEmpty ? null : _viagens.first.id;
}
});
} catch (erro) {
_mostrarErro('Não foi possível excluir a viagem: $erro');
}
}

Future<void> _sairDaConta() async {
if (_saindo) return;
debugPrint('LOGOUT: botão foi pressionado!');

final confirmar = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Sair do WildLife?'),
content: const Text(
'Você precisará entrar novamente para acessar sua conta.',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Cancelar'),
),
FilledButton.icon(
onPressed: () => Navigator.pop(dialogContext, true),
icon: const Icon(Icons.logout),
label: const Text('Sair'),
),
],
),
);

debugPrint('LOGOUT: confirmação recebida: $confirmar');
if (confirmar != true || !mounted) return;

setState(() => _saindo = true);
try {
debugPrint('LOGOUT: iniciando saída...');
await AuthService().sair();
debugPrint('LOGOUT: Supabase encerrou a sessão!');
// O AuthGate no main.dart deve exibir LoginScreen após o signedOut.
} catch (erro, stackTrace) {
debugPrint('LOGOUT: ERRO -> $erro');
debugPrintStack(stackTrace: stackTrace);
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao sair: $erro')),
);
} finally {
if (mounted) setState(() => _saindo = false);
}
}

void _abrirMais() {
showModalBottomSheet<void>(
context: context,
showDragHandle: true,
backgroundColor: AppColors.surface,
builder: (sheetContext) => SafeArea(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const ListTile(
title: Text(
'Mais opções',
style: TextStyle(fontWeight: FontWeight.bold),
),
),
ListTile(
leading: const Icon(Icons.hotel_outlined),
title: const Text('Hospedagem'),
onTap: () {
Navigator.pop(sheetContext);
_selecionarPagina(3);
},
),
ListTile(
leading: const Icon(Icons.checklist_outlined),
title: const Text('Checklist'),
onTap: () {
Navigator.pop(sheetContext);
_selecionarPagina(5);
},
),
ListTile(
leading: const Icon(Icons.star_outline),
title: const Text('Avaliações'),
onTap: () {
Navigator.pop(sheetContext);
_selecionarPagina(6);
},
),
const SizedBox(height: 12),
],
),
),
);
}

@override
Widget build(BuildContext context) {
final paginas = <Widget>[
_DashboardPage(
viagens: _viagens,
carregandoViagens: _carregandoViagens,
viagemSelecionada: _viagemSelecionada,
onSelecionarPagina: _selecionarPagina,
onCriarViagem: () => _abrirFormularioViagem(),
onSair: _sairDaConta,
saindo: _saindo,
onEditarViagem: (viagem) => _abrirFormularioViagem(viagem: viagem),
onExcluirViagem: _confirmarExclusaoViagem,
onSelecionarViagem: _selecionarViagem,
),
DestinosScreen(
key: const ValueKey('destinos'),
viagemId: _viagemSelecionada?.id,
),
RoteiroScreen(
key: const ValueKey('roteiro'),
viagem: _viagemSelecionada,
),
HospedagemScreen(
viagemId: _viagemSelecionada?.id,
),
GastosScreen(
viagem: _viagemSelecionada,
onOrcamentoAlterado: _atualizarOrcamento,
),
ChecklistScreen(
viagemId: _viagemSelecionada?.id,
),
AvaliacaoScreen(
viagemId: _viagemSelecionada?.id,
),
];

final largura = MediaQuery.sizeOf(context).width;
final desktop = largura >= 800;

if (desktop) {
return Scaffold(
backgroundColor: AppColors.background,
body: Row(
children: [
NavigationRail(
selectedIndex: _paginaSelecionada,
onDestinationSelected: _selecionarPagina,
labelType: NavigationRailLabelType.all,
destinations: _destinosDesktop,
),
const VerticalDivider(width: 1, color: AppColors.border),
Expanded(
child: IndexedStack(
index: _paginaSelecionada,
children: paginas,
),
),
],
),
);
}

const indicesPrincipais = [0, 1, 2, 4];
final indiceBarra = indicesPrincipais.contains(_paginaSelecionada)
? indicesPrincipais.indexOf(_paginaSelecionada)
    : 4;

return Scaffold(
backgroundColor: AppColors.background,
body: IndexedStack(
index: _paginaSelecionada,
children: paginas,
),
bottomNavigationBar: NavigationBar(
selectedIndex: indiceBarra,
onDestinationSelected: (indice) {
if (indice == 4) {
_abrirMais();
} else {
_selecionarPagina(indicesPrincipais[indice]);
}
},
destinations: const [
NavigationDestination(
icon: Icon(Icons.home_outlined),
selectedIcon: Icon(Icons.home),
label: 'Início',
),
NavigationDestination(
icon: Icon(Icons.place_outlined),
selectedIcon: Icon(Icons.place),
label: 'Destinos',
),
NavigationDestination(
icon: Icon(Icons.route_outlined),
selectedIcon: Icon(Icons.route),
label: 'Roteiro',
),
NavigationDestination(
icon: Icon(Icons.account_balance_wallet_outlined),
selectedIcon: Icon(Icons.account_balance_wallet),
label: 'Gastos',
),
NavigationDestination(
icon: Icon(Icons.grid_view_outlined),
selectedIcon: Icon(Icons.grid_view),
label: 'Mais',
),
],
),
);
}
}

class _DashboardPage extends StatelessWidget {
final List<Viagem> viagens;
final bool carregandoViagens;
final Viagem? viagemSelecionada;
final ValueChanged<int> onSelecionarPagina;
final VoidCallback onCriarViagem;
final VoidCallback onSair;
final bool saindo;
final ValueChanged<Viagem> onEditarViagem;
final ValueChanged<Viagem> onExcluirViagem;
final ValueChanged<Viagem> onSelecionarViagem;

const _DashboardPage({
required this.viagens,
required this.carregandoViagens,
required this.viagemSelecionada,
required this.onSelecionarPagina,
required this.onCriarViagem,
required this.onSair,
required this.saindo,
required this.onEditarViagem,
required this.onExcluirViagem,
required this.onSelecionarViagem,
});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.background,
appBar: AppBar(
backgroundColor: AppColors.background,
surfaceTintColor: Colors.transparent,
title: const Text(
'WildLife',
style: TextStyle(
color: AppColors.primary,
fontWeight: FontWeight.w900,
letterSpacing: 1.5,
),
),
actions: [
IconButton(
tooltip: 'Nova viagem',
onPressed: onCriarViagem,
icon: const Icon(Icons.add_circle_outline),
),
IconButton(
tooltip: 'Sair da conta',
onPressed: saindo ? null : onSair,
icon: saindo
? const SizedBox(
width: 20, height: 20,
child: CircularProgressIndicator(strokeWidth: 2),
)
    : const Icon(Icons.logout_rounded),
),
const SizedBox(width: 8),
],
),
body: LayoutBuilder(
builder: (context, constraints) {
final margem = constraints.maxWidth >= 900 ? 36.0 : 20.0;
return ListView(
padding: EdgeInsets.fromLTRB(margem, 24, margem, 110),
children: [
Text(
'Sua próxima aventura começa aqui',
style: Theme.of(context).textTheme.headlineMedium?.copyWith(
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 8),
const Text(
'Planeje destinos, roteiros e despesas em um só lugar.',
style: TextStyle(
color: AppColors.textSecondary,
height: 1.5,
),
),
const SizedBox(height: 26),
_buildViagens(context),
const SizedBox(height: 30),
const Text(
'Organize sua viagem',
style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
),
const SizedBox(height: 14),
_buildAcessos(constraints.maxWidth),
const SizedBox(height: 28),
_buildDica(),
],
);
},
),
floatingActionButton: viagens.isEmpty
? null
    : FloatingActionButton.extended(
onPressed: onCriarViagem,
icon: const Icon(Icons.add),
label: const Text('Nova viagem'),
),
);
}

Widget _buildViagens(BuildContext context) {
if (carregandoViagens) {
return const Center(child: Padding(
padding: EdgeInsets.all(32),
child: CircularProgressIndicator(),
));
}
if (viagens.isEmpty) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
decoration: BoxDecoration(
gradient: AppColors.heroGradient,
borderRadius: BorderRadius.circular(22),
border: Border.all(color: AppColors.border),
),
child: Column(
children: [
const Icon(
Icons.flight_takeoff,
size: 48,
color: AppColors.primary,
),
const SizedBox(height: 16),
const Text(
'Sua viagem começa aqui',
textAlign: TextAlign.center,
style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
),
const SizedBox(height: 8),
const Text(
'Crie sua primeira viagem para organizar cada detalhe.',
textAlign: TextAlign.center,
style: TextStyle(
color: AppColors.textSecondary,
height: 1.5,
),
),
const SizedBox(height: 22),
FilledButton.icon(
onPressed: onCriarViagem,
icon: const Icon(Icons.add),
label: const Text('Criar primeira viagem'),
),
],
),
);
}

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (viagemSelecionada != null) ...[
Container(
width: double.infinity,
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: AppColors.surfaceElevated,
borderRadius: BorderRadius.circular(14),
border: Border.all(color: AppColors.primary),
),
child: Row(
children: [
const Icon(Icons.check_circle, color: AppColors.primary),
const SizedBox(width: 10),
Expanded(
child: Text(
'Viagem ativa: ${viagemSelecionada!.nome}',
style: const TextStyle(fontWeight: FontWeight.bold),
),
),
],
),
),
const SizedBox(height: 18),
],
const Text(
'Minhas viagens',
style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
),
const SizedBox(height: 12),
for (final viagem in viagens) ...[
ViagemCard(
viagem: viagem,
onTap: () => onSelecionarViagem(viagem),
),
const SizedBox(height: 6),
Row(
mainAxisAlignment: MainAxisAlignment.end,
children: [
TextButton.icon(
onPressed: () => onSelecionarViagem(viagem),
icon: const Icon(Icons.check_circle_outline, size: 18),
label: const Text('Selecionar'),
),
TextButton.icon(
onPressed: () => onEditarViagem(viagem),
icon: const Icon(Icons.edit_outlined, size: 18),
label: const Text('Editar'),
),
IconButton(
tooltip: 'Excluir viagem',
onPressed: () => onExcluirViagem(viagem),
icon: const Icon(Icons.delete_outline),
),
],
),
const SizedBox(height: 12),
],
],
);
}

Widget _buildAcessos(double largura) {
final acessos = <_Acesso>[
const _Acesso('Destinos', 'Lugares para conhecer',
Icons.place_outlined, AppColors.primary, 1),
const _Acesso('Roteiro', 'Planeje cada dia',
Icons.route_outlined, AppColors.cyan, 2),
const _Acesso('Hospedagem', 'Suas reservas',
Icons.hotel_outlined, AppColors.blue, 3),
const _Acesso('Gastos', 'Controle o orçamento',
Icons.account_balance_wallet_outlined, AppColors.success, 4),
const _Acesso('Checklist', 'Não esqueça de nada',
Icons.checklist_outlined, AppColors.warning, 5),
const _Acesso('Avaliações', 'Registre experiências',
Icons.star_outline, AppColors.primaryLight, 6),
];

final colunas = largura >= 1050 ? 3 : largura >= 600 ? 2 : 1;

return GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: acessos.length,
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: colunas,
crossAxisSpacing: 12,
mainAxisSpacing: 12,
mainAxisExtent: 125,
),
itemBuilder: (context, indice) {
final acesso = acessos[indice];
return MenuCard(
title: acesso.titulo,
subtitle: acesso.descricao,
icon: acesso.icone,
color: acesso.cor,
onTap: () => onSelecionarPagina(acesso.pagina),
);
},
);
}

Widget _buildDica() {
return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: AppColors.border),
),
child: const Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(Icons.lightbulb_outline, color: AppColors.primary),
SizedBox(width: 12),
Expanded(
child: Text(
'Dica: selecione uma viagem antes de cadastrar destinos '
'ou montar o roteiro. Assim, tudo fica organizado '
'na viagem correta.',
style: TextStyle(
color: AppColors.textSecondary,
height: 1.5,
),
),
),
],
),
);
}
}

class _Acesso {
final String titulo;
final String descricao;
final IconData icone;
final Color cor;
final int pagina;

const _Acesso(
this.titulo,
this.descricao,
this.icone,
this.cor,
this.pagina,
);
}


