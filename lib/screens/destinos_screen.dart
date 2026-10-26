

import 'package:flutter/material.dart';

import '../models/destino.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/destino_card.dart';

class DestinosScreen extends StatefulWidget {
final String? viagemId;

const DestinosScreen({super.key, this.viagemId});

@override
State<DestinosScreen> createState() => _DestinosScreenState();
}

class _DestinosScreenState extends State<DestinosScreen> {
final List<Destino> _destinos = [];
final StorageService _storage = StorageService();
bool _carregandoDestinos = false;

@override
void initState() {
super.initState();
_carregarDestinos();
}

@override
void didUpdateWidget(covariant DestinosScreen oldWidget) {
super.didUpdateWidget(oldWidget);
if (oldWidget.viagemId != widget.viagemId) {
_carregarDestinos();
}
}

Future<void> _carregarDestinos() async {
final id = widget.viagemId;
setState(() {
_destinos.clear();
_favoritos.clear();
_visitados.clear();
_noRoteiro.clear();
_carregandoDestinos = id != null && id.isNotEmpty;
});
if (id == null || id.isEmpty) return;
try {
final dados = await _storage.getDestinos(id);
if (!mounted || widget.viagemId != id) return;
setState(() {
_destinos..clear()..addAll(dados);
});
} catch (erro) {
if (mounted && widget.viagemId == id) {
_mensagem('Não foi possível carregar destinos: $erro');
}
} finally {
if (mounted && widget.viagemId == id) {
setState(() => _carregandoDestinos = false);
}
}
}

List<Destino> get _destinosDaViagem {
final id = widget.viagemId;
if (id == null || id.isEmpty) return [];
return _destinos.where((destino) => destino.viagemId == id).toList();
}
final Set<String> _favoritos = {};
final Set<String> _visitados = {};
final Set<String> _noRoteiro = {};

final TextEditingController _pesquisaController =
TextEditingController();

String _filtroSelecionado = 'Todos';
String _termoPesquisa = '';
int _proximoId = 0;

static const List<String> _categorias = [
'Todos',
'Ponto turístico',
'Cultura',
'Passeio',
'Natureza',
'Hospedagem',
'Restaurante',
'Transporte',
];

@override
void dispose() {
_pesquisaController.dispose();
super.dispose();
}

List<Destino> get _destinosFiltrados {
final termo = _termoPesquisa.trim().toLowerCase();

return _destinosDaViagem.where((destino) {
final categoriaCorreta =
_filtroSelecionado == 'Todos' ||
destino.categoria == _filtroSelecionado;

final pesquisaCorreta =
termo.isEmpty ||
destino.nome.toLowerCase().contains(termo) ||
destino.cidade.toLowerCase().contains(termo) ||
destino.pais.toLowerCase().contains(termo) ||
destino.categoria.toLowerCase().contains(termo);

return categoriaCorreta && pesquisaCorreta;
}).toList();
}

String _novoId() {
_proximoId++;
return '${DateTime.now().microsecondsSinceEpoch}_$_proximoId';
}

void _mensagem(String texto) {
ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(content: Text(texto)),
);
}

void _limparFiltros() {
_pesquisaController.clear();

setState(() {
_termoPesquisa = '';
_filtroSelecionado = 'Todos';
});
}

void _alternarFavorito(Destino destino) {
setState(() {
if (!_favoritos.add(destino.id)) {
_favoritos.remove(destino.id);
}
});

_mensagem(
_favoritos.contains(destino.id)
? '${destino.nome} adicionado aos favoritos.'
    : '${destino.nome} removido dos favoritos.',
);
}

void _alternarVisitado(Destino destino) {
setState(() {
if (!_visitados.add(destino.id)) {
_visitados.remove(destino.id);
}
});
}

void _alternarRoteiro(Destino destino) {
setState(() {
if (!_noRoteiro.add(destino.id)) {
_noRoteiro.remove(destino.id);
}
});

_mensagem(
_noRoteiro.contains(destino.id)
? '${destino.nome} marcado para o roteiro.'
    : '${destino.nome} removido do roteiro.',
);
}

IconData _iconeCategoria(String categoria) {
switch (categoria) {
case 'Ponto turístico':
return Icons.location_city_outlined;
case 'Cultura':
return Icons.museum_outlined;
case 'Natureza':
return Icons.park_outlined;
case 'Hospedagem':
return Icons.hotel_outlined;
case 'Restaurante':
return Icons.restaurant_outlined;
case 'Transporte':
return Icons.directions_transit_outlined;
default:
return Icons.explore_outlined;
}
}

Color _corCategoria(String categoria) {
switch (categoria) {
case 'Ponto turístico':
return AppColors.primary;
case 'Cultura':
return const Color(0xFF9B8AFB);
case 'Natureza':
return AppColors.success;
case 'Hospedagem':
return AppColors.blue;
case 'Restaurante':
return const Color(0xFFFB923C);
case 'Transporte':
return AppColors.cyan;
default:
return AppColors.primaryLight;
}
}

String _localizacao(Destino destino) {
final partes = [
destino.cidade.trim(),
destino.pais.trim(),
].where((parte) => parte.isNotEmpty).toList();

return partes.isEmpty
? 'Localização não informada'
    : partes.join(', ');
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.background,
appBar: AppBar(
backgroundColor: AppColors.background,
surfaceTintColor: Colors.transparent,
title: const Text(
'Destinos',
style: TextStyle(fontWeight: FontWeight.bold),
),
actions: [
IconButton(
tooltip: 'Pesquisar destinos',
onPressed: _abrirPesquisa,
icon: const Icon(Icons.search),
),
const SizedBox(width: 8),
],
),
body: _carregandoDestinos
? const Center(child: CircularProgressIndicator())
    : LayoutBuilder(
builder: (context, constraints) {
final largura = constraints.maxWidth;
final margem = largura >= 900 ? 36.0 : 20.0;

final colunas = largura >= 1100
? 3
    : largura >= 650
? 2
    : 1;

return CustomScrollView(
slivers: [
SliverPadding(
padding: EdgeInsets.fromLTRB(
margem,
20,
margem,
24,
),
sliver: SliverToBoxAdapter(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
_buildCabecalho(
context,
largura >= 650,
),
const SizedBox(height: 24),
_buildPesquisa(),
const SizedBox(height: 20),
_buildEstatisticas(),
const SizedBox(height: 28),
_buildTituloSecao(),
const SizedBox(height: 14),
_buildFiltros(),
],
),
),
),
_buildListaDestinos(
colunas: colunas,
margem: margem,
),
SliverPadding(
padding: EdgeInsets.fromLTRB(
margem,
24,
margem,
110,
),
sliver: SliverToBoxAdapter(
child: _buildDicaViagem(),
),
),
],
);
},
),
floatingActionButton: widget.viagemId == null || _destinosDaViagem.isEmpty
? null
    : FloatingActionButton.extended(
onPressed: _adicionarDestino,
icon: const Icon(
Icons.add_location_alt_outlined,
),
label: const Text('Adicionar destino'),
),
);
}

Widget _buildCabecalho(
BuildContext context,
bool mostrarBotao,
) {
return Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Explore novos lugares',
style: Theme.of(context)
    .textTheme
    .headlineMedium
    ?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
const Text(
'Reúna os lugares que deseja conhecer '
'e organize suas próximas experiências.',
style: TextStyle(
color: AppColors.textSecondary,
height: 1.5,
),
),
],
),
),
if (mostrarBotao) ...[
const SizedBox(width: 16),
IconButton.filledTonal(
tooltip: 'Novo destino',
onPressed: _adicionarDestino,
icon: const Icon(Icons.add),
),
],
],
);
}

Widget _buildPesquisa() {
return TextField(
controller: _pesquisaController,
onChanged: (valor) {
setState(() => _termoPesquisa = valor);
},
textInputAction: TextInputAction.search,
decoration: InputDecoration(
hintText: 'Buscar lugar, cidade ou categoria...',
prefixIcon: const Icon(Icons.search),
suffixIcon: _termoPesquisa.isNotEmpty
? IconButton(
tooltip: 'Limpar pesquisa',
onPressed: () {
_pesquisaController.clear();
setState(() => _termoPesquisa = '');
},
icon: const Icon(Icons.close),
)
    : null,
),
);
}

Widget _buildEstatisticas() {
return Row(
children: [
Expanded(
child: _StatCard(
icon: Icons.place_outlined,
valor: '${_destinosDaViagem.length}',
titulo: 'Destinos',
cor: AppColors.primary,
),
),
const SizedBox(width: 8),
Expanded(
child: _StatCard(
icon: Icons.favorite_border,
valor: '${_destinosDaViagem.where((d) => _favoritos.contains(d.id)).length}',
titulo: 'Favoritos',
cor: AppColors.error,
),
),
const SizedBox(width: 8),
Expanded(
child: _StatCard(
icon: Icons.check_circle_outline,
valor: '${_destinosDaViagem.where((d) => _visitados.contains(d.id)).length}',
titulo: 'Visitados',
cor: AppColors.success,
),
),
],
);
}

Widget _buildTituloSecao() {
final quantidade = _destinosFiltrados.length;

return Row(
children: [
const Expanded(
child: Text(
'Seus destinos',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
),
Text(
'$quantidade '
'${quantidade == 1 ? 'lugar' : 'lugares'}',
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 13,
),
),
],
);
}

Widget _buildFiltros() {
return SizedBox(
height: 42,
child: ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: _categorias.length,
separatorBuilder: (_, __) =>
const SizedBox(width: 8),
itemBuilder: (context, index) {
final categoria = _categorias[index];

return ChoiceChip(
label: Text(categoria),
selected: _filtroSelecionado == categoria,
showCheckmark: false,
onSelected: (_) {
setState(() {
_filtroSelecionado = categoria;
});
},
);
},
),
);
}

Widget _buildListaDestinos({
required int colunas,
required double margem,
}) {
final destinos = _destinosFiltrados;

if (destinos.isEmpty) {
return SliverPadding(
padding: EdgeInsets.symmetric(
horizontal: margem,
),
sliver: SliverToBoxAdapter(
child: _buildEstadoVazio(),
),
);
}

return SliverPadding(
padding: EdgeInsets.symmetric(
horizontal: margem,
),
sliver: SliverGrid(
delegate: SliverChildBuilderDelegate(
(context, index) {
final destino = destinos[index];

return DestinoCard(
destino: destino,
isFavorite: _favoritos.contains(destino.id),
onTap: () => _abrirDetalhes(destino),
onFavorite: () => _alternarFavorito(destino),
);
},
childCount: destinos.length,
),
gridDelegate:
SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: colunas,
crossAxisSpacing: 16,
mainAxisSpacing: 16,
mainAxisExtent: colunas == 1 ? 185 : 200,
),
),
);
}

Widget _buildEstadoVazio() {
final semCadastro = _destinosDaViagem.isEmpty;
final pesquisando = _termoPesquisa.trim().isNotEmpty;

final String titulo;
final String descricao;
final IconData icone;

if (semCadastro) {
titulo = widget.viagemId == null
? 'Selecione uma viagem primeiro'
    : 'Sua próxima aventura começa aqui';
descricao = widget.viagemId == null
? 'Crie ou selecione uma viagem na tela Início para organizar seus destinos.'
    : 'Adicione seu primeiro destino para começar '
'a organizar os lugares que deseja conhecer.';
icone = Icons.explore_outlined;
} else if (pesquisando) {
titulo = 'Nenhum resultado encontrado';
descricao =
'Tente pesquisar outro nome, cidade ou categoria.';
icone = Icons.search_off_outlined;
} else {
titulo = 'Nenhum destino nesta categoria';
descricao =
'Escolha outra categoria ou visualize '
'todos os seus destinos.';
icone = Icons.location_off_outlined;
}

return Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 32,
),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: AppColors.border),
),
child: Column(
children: [
Container(
width: 68,
height: 68,
decoration: BoxDecoration(
color: AppColors.primary
    .withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(22),
),
child: Icon(
icone,
size: 34,
color: AppColors.primary,
),
),
const SizedBox(height: 18),
Text(
titulo,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
Text(
descricao,
textAlign: TextAlign.center,
style: const TextStyle(
color: AppColors.textSecondary,
height: 1.5,
),
),
const SizedBox(height: 20),
if (semCadastro && widget.viagemId != null)
FilledButton.icon(
onPressed: _adicionarDestino,
icon: const Icon(
Icons.add_location_alt_outlined,
),
label: const Text(
'Adicionar primeiro destino',
),
)
else
OutlinedButton.icon(
onPressed: _limparFiltros,
icon: const Icon(Icons.filter_alt_off),
label: const Text('Limpar filtros'),
),
],
),
);
}

Widget _buildDicaViagem() {
return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: AppColors.border),
),
child: const Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.lightbulb_outline,
color: AppColors.primary,
size: 26,
),
SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Dica de viagem',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
SizedBox(height: 6),
Text(
'Agrupe lugares próximos no mesmo dia '
'para aproveitar melhor o tempo e '
'facilitar os deslocamentos.',
style: TextStyle(
color: AppColors.textSecondary,
height: 1.5,
),
),
],
),
),
],
),
);
}

Future<void> _abrirPesquisa() async {
final destino = await showSearch<Destino?>(
context: context,
delegate: _DestinoSearchDelegate(_destinosDaViagem),
);

if (!mounted || destino == null) return;

_abrirDetalhes(destino);
}

void _abrirDetalhes(Destino destino) {
showModalBottomSheet<void>(
context: context,
isScrollControlled: true,
showDragHandle: true,
backgroundColor: AppColors.surface,
builder: (sheetContext) {
return StatefulBuilder(
builder: (context, atualizarModal) {
final favorito = _favoritos.contains(destino.id);
final visitado = _visitados.contains(destino.id);
final noRoteiro = _noRoteiro.contains(destino.id);
final cor = _corCategoria(destino.categoria);
final icone = _iconeCategoria(destino.categoria);

return SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(
22,
8,
22,
28,
),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 58,
height: 58,
decoration: BoxDecoration(
color: cor.withValues(alpha: 0.13),
borderRadius:
BorderRadius.circular(18),
),
child: Icon(
icone,
color: cor,
size: 30,
),
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
destino.nome,
style: Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 5),
Text(
_localizacao(destino),
style: const TextStyle(
color:
AppColors.textSecondary,
),
),
],
),
),
IconButton(
tooltip: 'Fechar',
onPressed: () =>
Navigator.pop(sheetContext),
icon: const Icon(Icons.close),
),
],
),
const SizedBox(height: 22),
Chip(
avatar: Icon(
icone,
color: cor,
size: 17,
),
label: Text(destino.categoria),
),
const SizedBox(height: 12),
Text(
destino.descricao == null ||
destino.descricao!.trim().isEmpty
? 'Nenhuma descrição foi '
'adicionada para este destino.'
    : destino.descricao!,
style: const TextStyle(
color: AppColors.textSecondary,
height: 1.6,
),
),
const SizedBox(height: 20),
Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: AppColors.background,
borderRadius:
BorderRadius.circular(12),
border: Border.all(
color: AppColors.border,
),
),
child: Row(
children: [
Icon(
visitado
? Icons.check_circle
    : Icons.circle_outlined,
color: visitado
? AppColors.success
    : AppColors.textMuted,
),
const SizedBox(width: 10),
const Expanded(
child: Text(
'Já visitei este lugar',
),
),
Switch(
value: visitado,
onChanged: (_) {
_alternarVisitado(destino);
atualizarModal(() {});
},
),
],
),
),
const SizedBox(height: 20),
SizedBox(
width: double.infinity,
child: FilledButton.icon(
onPressed: () {
_alternarRoteiro(destino);
atualizarModal(() {});
},
icon: Icon(
noRoteiro
? Icons.remove_circle_outline
    : Icons.route_outlined,
),
label: Text(
noRoteiro
? 'Remover da seleção do roteiro'
    : 'Selecionar para o roteiro',
),
),
),
const SizedBox(height: 10),
SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
onPressed: () {
_alternarFavorito(destino);
atualizarModal(() {});
},
icon: Icon(
favorito
? Icons.favorite
    : Icons.favorite_border,
color: favorito
? AppColors.error
    : null,
),
label: Text(
favorito
? 'Remover dos favoritos'
    : 'Salvar nos favoritos',
),
),
),
const SizedBox(height: 8),
SizedBox(
width: double.infinity,
child: TextButton.icon(
onPressed: () {
Navigator.pop(sheetContext);
_confirmarRemocao(destino);
},
icon: const Icon(
Icons.delete_outline,
),
label: const Text(
'Excluir destino',
),
),
),
],
),
),
);
},
);
},
);
}

Future<void> _adicionarDestino() async {
if (widget.viagemId == null || widget.viagemId!.isEmpty) {
_mensagem('Crie ou selecione uma viagem primeiro.');
return;
}

final nomeController = TextEditingController();
final cidadeController = TextEditingController();
final paisController = TextEditingController();
final descricaoController = TextEditingController();

String categoriaSelecionada = 'Passeio';
String? erro;
bool salvando = false;

await showModalBottomSheet<void>(
context: context,
isScrollControlled: true,
showDragHandle: true,
backgroundColor: AppColors.surface,
builder: (sheetContext) {
return StatefulBuilder(
builder: (context, atualizarModal) {
return SafeArea(
child: Padding(
padding: EdgeInsets.fromLTRB(
22,
8,
22,
MediaQuery.viewInsetsOf(context).bottom + 24,
),
child: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Adicionar destino',
style: Theme.of(context)
    .textTheme
    .headlineSmall
    ?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
const Text(
'Cadastre um lugar que deseja conhecer.',
style: TextStyle(
color: AppColors.textSecondary,
),
),
const SizedBox(height: 22),
TextField(
controller: nomeController,
autofocus: true,
textCapitalization:
TextCapitalization.words,
textInputAction: TextInputAction.next,
decoration: const InputDecoration(
labelText: 'Nome do destino *',
hintText: 'Ex.: Parque Ibirapuera',
prefixIcon:
Icon(Icons.place_outlined),
),
onChanged: (_) {
if (erro != null) {
atualizarModal(() => erro = null);
}
},
),
const SizedBox(height: 14),
TextField(
controller: cidadeController,
textCapitalization:
TextCapitalization.words,
textInputAction: TextInputAction.next,
decoration: const InputDecoration(
labelText: 'Cidade',
hintText: 'Ex.: São Paulo',
prefixIcon: Icon(Icons.location_city),
),
),
const SizedBox(height: 14),
TextField(
controller: paisController,
textCapitalization:
TextCapitalization.words,
textInputAction: TextInputAction.next,
decoration: const InputDecoration(
labelText: 'País',
hintText: 'Ex.: Brasil',
prefixIcon: Icon(Icons.public),
),
),
const SizedBox(height: 14),
TextField(
controller: descricaoController,
textCapitalization:
TextCapitalization.sentences,
maxLines: 3,
decoration: const InputDecoration(
labelText: 'Descrição (opcional)',
hintText:
'O que você deseja conhecer?',
prefixIcon:
Icon(Icons.notes_outlined),
alignLabelWithHint: true,
),
),
const SizedBox(height: 20),
const Text(
'Categoria',
style: TextStyle(
fontWeight: FontWeight.w600,
color: AppColors.textSecondary,
),
),
const SizedBox(height: 10),
Wrap(
spacing: 8,
runSpacing: 8,
children: [
for (final categoria
in _categorias.skip(1))
ChoiceChip(
label: Text(categoria),
selected:
categoriaSelecionada ==
categoria,
showCheckmark: false,
onSelected: (_) {
atualizarModal(() {
categoriaSelecionada =
categoria;
});
},
),
],
),
if (erro != null) ...[
const SizedBox(height: 14),
Text(
erro!,
style: const TextStyle(
color: AppColors.error,
),
),
],
const SizedBox(height: 24),
SizedBox(
width: double.infinity,
child: FilledButton.icon(
onPressed: salvando ? null : () async {
final nome = nomeController.text.trim();
final cidade = cidadeController.text.trim();
final pais = paisController.text.trim();

if (nome.isEmpty) {
atualizarModal(() => erro = 'Informe o nome do destino.');
return;
}

final repetido = _destinosDaViagem.any(
(destino) =>
destino.nome.toLowerCase() == nome.toLowerCase() &&
destino.cidade.toLowerCase() == cidade.toLowerCase() &&
destino.pais.toLowerCase() == pais.toLowerCase(),
);
if (repetido) {
atualizarModal(() => erro = 'Este destino já está cadastrado.');
return;
}

final novoDestino = Destino(
id: _novoId(),
viagemId: widget.viagemId!,
nome: nome,
cidade: cidade,
pais: pais,
categoria: categoriaSelecionada,
descricao: descricaoController.text.trim(),
);

atualizarModal(() {
salvando = true;
erro = null;
});
try {
await _storage.salvarDestino(novoDestino);
if (!mounted || !sheetContext.mounted) return;
setState(() {
_destinos.insert(0, novoDestino);
_filtroSelecionado = 'Todos';
_termoPesquisa = '';
_pesquisaController.clear();
});
Navigator.pop(sheetContext);
_mensagem('$nome adicionado aos destinos.');
} catch (e) {
if (sheetContext.mounted) {
atualizarModal(() => erro = 'Erro ao salvar: $e');
}
} finally {
if (sheetContext.mounted) {
atualizarModal(() => salvando = false);
}
}
},
icon: const Icon(
Icons.add_location_alt_outlined,
),
label: const Text('Salvar destino'),
),
),
],
),
),
),
);
},
);
},
);

await Future<void>.delayed(
const Duration(milliseconds: 300),
);

nomeController.dispose();
cidadeController.dispose();
paisController.dispose();
descricaoController.dispose();
}

Future<void> _confirmarRemocao(
Destino destino,
) async {
final confirmar = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('Excluir destino?'),
content: Text(
'Deseja remover "${destino.nome}" da sua lista?',
),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(dialogContext, false),
child: const Text('Cancelar'),
),
FilledButton(
onPressed: () =>
Navigator.pop(dialogContext, true),
child: const Text('Excluir'),
),
],
);
},
);

if (confirmar != true || !mounted) return;

final index = _destinos.indexWhere((d) => d.id == destino.id);
if (index == -1) return;

try {
await _storage.deletarDestino(destino.id);
if (!mounted) return;
setState(() {
_destinos.removeWhere((d) => d.id == destino.id);
_favoritos.remove(destino.id);
_visitados.remove(destino.id);
_noRoteiro.remove(destino.id);
});
_mensagem('${destino.nome} removido do Supabase.');
} catch (erro) {
if (mounted) _mensagem('Não foi possível excluir: $erro');
}
}
}

class _StatCard extends StatelessWidget {
final IconData icon;
final String valor;
final String titulo;
final Color cor;

const _StatCard({
required this.icon,
required this.valor,
required this.titulo,
required this.cor,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 14,
),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: AppColors.border,
),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, color: cor, size: 23),
const SizedBox(height: 9),
Text(
valor,
style: Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 3),
Text(
titulo,
textAlign: TextAlign.center,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 11,
),
),
],
),
);
}
}

class _DestinoSearchDelegate
extends SearchDelegate<Destino?> {
final List<Destino> destinos;

_DestinoSearchDelegate(this.destinos);

@override
String get searchFieldLabel => 'Pesquisar destinos';

@override
List<Widget> buildActions(BuildContext context) {
return [
if (query.isNotEmpty)
IconButton(
tooltip: 'Limpar pesquisa',
onPressed: () => query = '',
icon: const Icon(Icons.clear),
),
];
}

@override
Widget buildLeading(BuildContext context) {
return IconButton(
tooltip: 'Voltar',
onPressed: () => close(context, null),
icon: const Icon(Icons.arrow_back),
);
}

@override
Widget buildResults(BuildContext context) {
return _buildResultados(context);
}

@override
Widget buildSuggestions(BuildContext context) {
return _buildResultados(context);
}

Widget _buildResultados(BuildContext context) {
final termo = query.trim().toLowerCase();

final resultados = destinos.where((destino) {
return destino.nome.toLowerCase().contains(termo) ||
destino.cidade.toLowerCase().contains(termo) ||
destino.pais.toLowerCase().contains(termo) ||
destino.categoria.toLowerCase().contains(termo);
}).toList();

if (resultados.isEmpty) {
return const Center(
child: Padding(
padding: EdgeInsets.all(24),
child: Text(
'Nenhum destino encontrado.\n'
'Experimente outro termo.',
textAlign: TextAlign.center,
style: TextStyle(
color: AppColors.textSecondary,
height: 1.5,
),
),
),
);
}

return ListView.separated(
padding: const EdgeInsets.all(16),
itemCount: resultados.length,
separatorBuilder: (_, __) =>
const SizedBox(height: 8),
itemBuilder: (context, index) {
final destino = resultados[index];

return Card(
margin: EdgeInsets.zero,
child: ListTile(
leading: const CircleAvatar(
backgroundColor: AppColors.surfaceElevated,
child: Icon(
Icons.place_outlined,
color: AppColors.primary,
),
),
title: Text(
destino.nome,
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
subtitle: Text(
[
destino.cidade,
destino.pais,
].where((parte) => parte.isNotEmpty).join(', '),
),
trailing: const Icon(Icons.chevron_right),
onTap: () => close(context, destino),
),
);
},
);
}
}

