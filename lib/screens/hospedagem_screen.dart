
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/hospedagem.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HospedagemScreen extends StatefulWidget {
final String? viagemId;

const HospedagemScreen({super.key, this.viagemId});

@override
State<HospedagemScreen> createState() => _HospedagemScreenState();
}

class _HospedagemScreenState extends State<HospedagemScreen> {
final List<_Hospedagem> _hospedagens = [];
final _client = Supabase.instance.client;
bool _carregando = false;
bool _salvando = false;
String? _erroCarregamento;

@override
void initState() {
super.initState();
_carregarHospedagens();
}

Future<void> _carregarHospedagens() async {
final viagemId = widget.viagemId;
if (viagemId == null) {
if (mounted) setState(() { _hospedagens.clear(); _erroCarregamento = null; });
return;
}
setState(() { _carregando = true; _erroCarregamento = null; });
try {
final rows = await _client.from('hospedagens').select()
    .eq('viagemId', viagemId).order('checkIn');
if (!mounted || widget.viagemId != viagemId) return;
setState(() {
_hospedagens
..clear()
..addAll(rows.map((row) => _Hospedagem.fromModel(Hospedagem.fromMap(row))));
});
} catch (e) {
if (mounted && widget.viagemId == viagemId) {
setState(() => _erroCarregamento = 'Não foi possível carregar as hospedagens: $e');
}
} finally {
if (mounted && widget.viagemId == viagemId) setState(() => _carregando = false);
}
}

void _avisarErro(Object e) {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao salvar no Supabase: $e')),
);
}


List<_Hospedagem> get _hospedagensDaViagem {
final id = widget.viagemId;
if (id == null) return [];
return _hospedagens.where((h) => h.viagemId == id).toList();
}

@override
void didUpdateWidget(covariant HospedagemScreen oldWidget) {
super.didUpdateWidget(oldWidget);
if (oldWidget.viagemId != widget.viagemId) {
_busca = '';
_ordenacao = 'Check-in';
_hospedagens.clear();
_carregarHospedagens();
}
}

String _busca = '';
String _ordenacao = 'Check-in';

int get _totalNoites => _hospedagensDaViagem.fold(
0,
(total, h) => total + h.noites,
);

double get _valorTotal => _hospedagensDaViagem.fold(
0.0,
(total, h) => total + (h.valor ?? 0),
);

List<_Hospedagem> get _listaFiltrada {
final termo = _busca.trim().toLowerCase();

final lista = _hospedagensDaViagem.where((h) {
return h.nome.toLowerCase().contains(termo) ||
h.cidade.toLowerCase().contains(termo) ||
h.endereco.toLowerCase().contains(termo);
}).toList();

switch (_ordenacao) {
case 'Valor':
lista.sort(
(a, b) => (b.valor ?? 0).compareTo(a.valor ?? 0),
);
break;
case 'Nome':
lista.sort((a, b) => a.nome.compareTo(b.nome));
break;
default:
lista.sort((a, b) {
if (a.checkIn == null) return 1;
if (b.checkIn == null) return -1;
return a.checkIn!.compareTo(b.checkIn!);
});
}

return lista;
}

String _moeda(double valor) {
final partes = valor.toStringAsFixed(2).split('.');
final inteiro = partes[0];
final buffer = StringBuffer();

for (var i = 0; i < inteiro.length; i++) {
if (i > 0 && (inteiro.length - i) % 3 == 0) {
buffer.write('.');
}
buffer.write(inteiro[i]);
}

return 'R\$ ${buffer.toString()},${partes[1]}';
}

String _data(DateTime? data) {
if (data == null) return 'A definir';

const meses = [
'Jan', 'Fev', 'Mar', 'Abr',
'Mai', 'Jun', 'Jul', 'Ago',
'Set', 'Out', 'Nov', 'Dez',
];

return '${data.day} ${meses[data.month - 1]} ${data.year}';
}

double? _lerValor(String texto) {
var valor = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');

if (valor.isEmpty) return null;

if (valor.contains(',')) {
valor = valor.replaceAll('.', '').replaceAll(',', '.');
}

return double.tryParse(valor);
}

@override
Widget build(BuildContext context) {
final temHospedagens = _hospedagensDaViagem.isNotEmpty;

return Scaffold(
backgroundColor: AppColors.background,
appBar: AppBar(
title: const Text(
'Hospedagem',
style: TextStyle(fontWeight: FontWeight.w900),
),
backgroundColor: AppColors.background,
surfaceTintColor: Colors.transparent,
actions: [
if (temHospedagens)
IconButton(
tooltip: 'Pesquisar hospedagem',
onPressed: _abrirPesquisa,
icon: const Icon(Icons.search),
),
const SizedBox(width: 8),
],
),
body: SafeArea(
child: ListView(
padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
children: [
Text(
'Onde você vai ficar?',
style: Theme.of(context)
    .textTheme
    .headlineMedium
    ?.copyWith(fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
const Text(
'Organize suas reservas e tenha todos os '
'detalhes da hospedagem em um só lugar.',
style: TextStyle(
color: AppColors.textSecondary,
height: 1.5,
),
),
const SizedBox(height: 24),
if (widget.viagemId == null) ...[
_buildSemViagem(),
] else ...[
_buildResumo(),
const SizedBox(height: 28),
_buildTituloReservas(),
const SizedBox(height: 16),
if (_carregando)
const Center(child: CircularProgressIndicator())
else if (_erroCarregamento != null)
Column(children: [
Text(_erroCarregamento!, style: const TextStyle(color: AppColors.error)),
TextButton(onPressed: _carregarHospedagens, child: const Text('Tentar novamente')),
])
else if (!temHospedagens)
_buildEstadoVazio()
else if (_listaFiltrada.isEmpty)
_buildSemResultados()
else
..._listaFiltrada.map(_buildHospedagemCard),
const SizedBox(height: 26),
_buildDica(),
],
],
),
),
floatingActionButton: temHospedagens
? FloatingActionButton.extended(
onPressed: () => _abrirFormulario(),
icon: const Icon(Icons.add),
label: const Text('Adicionar hospedagem'),
)
    : null,
);
}

Widget _buildSemViagem() {
return Card(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
child: Column(
children: [
const Icon(Icons.luggage_outlined, size: 48, color: AppColors.primary),
const SizedBox(height: 16),
const Text('Selecione uma viagem',
style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
const SizedBox(height: 8),
const Text(
'Crie ou selecione uma viagem na tela Início para organizar suas reservas.',
textAlign: TextAlign.center,
style: TextStyle(color: AppColors.textSecondary, height: 1.5),
),
],
),
),
);
}

Widget _buildResumo() {
return Card(
clipBehavior: Clip.antiAlias,
child: Container(
decoration: const BoxDecoration(
gradient: AppColors.heroGradient,
),
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Row(
children: [
Icon(
Icons.hotel_rounded,
color: AppColors.primary,
size: 28,
),
SizedBox(width: 12),
Expanded(
child: Text(
'Sua hospedagem',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w800,
),
),
),
],
),
const SizedBox(height: 8),
Text(
'${_hospedagensDaViagem.length} reservas • $_totalNoites noites',
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 12,
),
),
const SizedBox(height: 18),
const Divider(color: AppColors.border),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: _ResumoItem(
icone: Icons.nights_stay_outlined,
valor: '$_totalNoites',
titulo: 'Noites',
),
),
Expanded(
child: _ResumoItem(
icone: Icons.hotel_outlined,
valor: '${_hospedagensDaViagem.length}',
titulo: 'Reservas',
),
),
Expanded(
child: _ResumoItem(
icone: Icons.payments_outlined,
valor: _moeda(_valorTotal),
titulo: 'Total',
),
),
],
),
],
),
),
);
}

Widget _buildTituloReservas() {
return Row(
children: [
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Minhas reservas',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.w800,
),
),
SizedBox(height: 4),
Text(
'Suas hospedagens durante a viagem',
style: TextStyle(
color: AppColors.textSecondary,
fontSize: 13,
),
),
],
),
),
if (_hospedagensDaViagem.isNotEmpty)
PopupMenuButton<String>(
tooltip: 'Ordenar',
initialValue: _ordenacao,
icon: const Icon(Icons.sort),
onSelected: (valor) {
setState(() => _ordenacao = valor);
},
itemBuilder: (_) => const [
PopupMenuItem(
value: 'Check-in',
child: Text('Por check-in'),
),
PopupMenuItem(
value: 'Valor',
child: Text('Por valor'),
),
PopupMenuItem(
value: 'Nome',
child: Text('Por nome'),
),
],
),
],
);
}

Widget _buildEstadoVazio() {
return Card(
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 24,
vertical: 34,
),
child: Column(
children: [
Container(
width: 72,
height: 72,
decoration: BoxDecoration(
color: AppColors.primary.withValues(alpha: 0.12),
shape: BoxShape.circle,
),
child: const Icon(
Icons.hotel_outlined,
color: AppColors.primary,
size: 35,
),
),
const SizedBox(height: 20),
const Text(
'Nenhuma hospedagem',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 10),
const Text(
'Cadastre sua primeira reserva para '
'organizar onde você vai ficar.',
textAlign: TextAlign.center,
style: TextStyle(
color: AppColors.textSecondary,
height: 1.5,
),
),
const SizedBox(height: 22),
FilledButton.icon(
onPressed: () => _abrirFormulario(),
icon: const Icon(Icons.add),
label: const Text('Adicionar hospedagem'),
),
],
),
),
);
}

Widget _buildSemResultados() {
return const Card(
child: Padding(
padding: EdgeInsets.all(30),
child: Column(
children: [
Icon(
Icons.search_off_outlined,
color: AppColors.primary,
size: 42,
),
SizedBox(height: 12),
Text('Nenhuma hospedagem encontrada.'),
],
),
),
);
}

Widget _buildHospedagemCard(_Hospedagem h) {
return Padding(
padding: const EdgeInsets.only(bottom: 14),
child: Card(
clipBehavior: Clip.antiAlias,
child: InkWell(
onTap: () => _abrirDetalhes(h),
child: Padding(
padding: const EdgeInsets.all(17),
child: Column(
children: [
Row(
children: [
Container(
width: 52,
height: 52,
decoration: BoxDecoration(
color: AppColors.primary
    .withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(15),
),
child: const Icon(
Icons.hotel_rounded,
color: AppColors.primary,
size: 27,
),
),
const SizedBox(width: 13),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
h.nome,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 5),
Text(
h.cidade,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 12,
),
),
],
),
),
const Icon(
Icons.chevron_right,
color: AppColors.textMuted,
),
],
),
const SizedBox(height: 16),
const Divider(color: AppColors.border),
const SizedBox(height: 15),
Row(
children: [
Expanded(
child: _InfoItem(
titulo: 'Check-in',
valor: _data(h.checkIn),
icone: Icons.login_outlined,
),
),
Expanded(
child: _InfoItem(
titulo: 'Check-out',
valor: _data(h.checkOut),
icone: Icons.logout_outlined,
),
),
],
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: _InfoItem(
titulo: 'Noites',
valor: '${h.noites}',
icone: Icons.nights_stay_outlined,
),
),
Expanded(
child: _InfoItem(
titulo: 'Valor',
valor: h.valor == null
? 'Não informado'
    : _moeda(h.valor!),
icone: Icons.payments_outlined,
),
),
],
),
],
),
),
),
),
);
}

Widget _buildDica() {
return Card(
child: Padding(
padding: const EdgeInsets.all(20),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Icon(
Icons.info_outline,
color: AppColors.blue,
size: 26,
),
const SizedBox(width: 14),
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Dica',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.w800,
),
),
SizedBox(height: 6),
Text(
'Guarde o endereço e as datas da '
'reserva para encontrar tudo rapidamente '
'durante a viagem.',
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
),
);
}

Future<void> _abrirFormulario({
_Hospedagem? hospedagem,
}) async {
final viagemId = widget.viagemId;
if (viagemId == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Selecione uma viagem na tela Início.')),
);
return;
}
final nome = TextEditingController(
text: hospedagem?.nome ?? '',
);
final cidade = TextEditingController(
text: hospedagem?.cidade ?? '',
);
final endereco = TextEditingController(
text: hospedagem?.endereco ?? '',
);
final valor = TextEditingController(
text: hospedagem?.valor == null
? ''
    : hospedagem!.valor!.toStringAsFixed(2)
    .replaceAll('.', ','),
);

DateTime? checkIn = hospedagem?.checkIn;
DateTime? checkOut = hospedagem?.checkOut;
String? erro;

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
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
hospedagem == null
? 'Nova hospedagem'
    : 'Editar hospedagem',
style: Theme.of(context)
    .textTheme
    .headlineSmall,
),
const SizedBox(height: 22),
TextField(
controller: nome,
textCapitalization:
TextCapitalization.words,
decoration: const InputDecoration(
labelText: 'Nome da hospedagem *',
prefixIcon: Icon(Icons.hotel_outlined),
),
),
const SizedBox(height: 14),
TextField(
controller: cidade,
textCapitalization:
TextCapitalization.words,
decoration: const InputDecoration(
labelText: 'Cidade / País *',
prefixIcon: Icon(Icons.public),
),
),
const SizedBox(height: 14),
TextField(
controller: endereco,
textCapitalization:
TextCapitalization.words,
decoration: const InputDecoration(
labelText: 'Endereço',
prefixIcon:
Icon(Icons.location_on_outlined),
),
),
const SizedBox(height: 14),
TextField(
controller: valor,
keyboardType:
const TextInputType.numberWithOptions(
decimal: true,
),
decoration: const InputDecoration(
labelText: 'Valor total da reserva',
prefixIcon:
Icon(Icons.payments_outlined),
prefixText: 'R\$ ',
),
),
const SizedBox(height: 20),
const Text(
'Datas da reserva',
style: TextStyle(
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 10),
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () async {
final data = await showDatePicker(
context: context,
initialDate:
checkIn ?? DateTime.now(),
firstDate: DateTime(2020),
lastDate: DateTime(2100),
);
if (data != null) {
atualizarModal(() {
checkIn = data;
});
}
},
child: Text(
checkIn == null
? 'Check-in'
    : _data(checkIn),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
),
),
const SizedBox(width: 10),
Expanded(
child: OutlinedButton(
onPressed: () async {
final data = await showDatePicker(
context: context,
initialDate:
checkOut ??
checkIn ??
DateTime.now(),
firstDate: DateTime(2020),
lastDate: DateTime(2100),
);
if (data != null) {
atualizarModal(() {
checkOut = data;
});
}
},
child: Text(
checkOut == null
? 'Check-out'
    : _data(checkOut),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
),
),
],
),
if (erro != null) ...[
const SizedBox(height: 12),
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
onPressed: () async {
if (_salvando) return;
if (nome.text.trim().isEmpty ||
cidade.text.trim().isEmpty) {
atualizarModal(() {
erro =
'Preencha o nome e a cidade.';
});
return;
}

if (checkIn == null || checkOut == null) {
atualizarModal(() => erro = 'Informe o check-in e o check-out.');
return;
}
if (!checkOut!.isAfter(checkIn!)) {
atualizarModal(() {
erro =
'O check-out deve ser após o check-in.';
});
return;
}

final textoValor = valor.text.trim();
final valorNumerico =
_lerValor(textoValor);

if (valorNumerico == null ||
!valorNumerico.isFinite || valorNumerico < 0) {
atualizarModal(() {
erro =
'Informe um valor válido.';
});
return;
}

final novo = _Hospedagem(
viagemId: viagemId,
id: hospedagem?.id ??
DateTime.now()
    .microsecondsSinceEpoch
    .toString(),
nome: nome.text.trim(),
cidade: cidade.text.trim(),
endereco: endereco.text.trim(),
checkIn: checkIn,
checkOut: checkOut,
valor: valorNumerico,
);

if (widget.viagemId != viagemId) return;
atualizarModal(() { _salvando = true; erro = null; });
try {
await _client.from('hospedagens').upsert(
novo.toModel().toMap(),
);
if (!mounted || widget.viagemId != viagemId) return;
setState(() {
final indice = _hospedagens.indexWhere((h) => h.id == novo.id);
if (indice < 0) {
_hospedagens.add(novo);
} else {
_hospedagens[indice] = novo;
}
});
if (sheetContext.mounted) Navigator.pop(sheetContext);
} catch (e) {
if (sheetContext.mounted) {
atualizarModal(() => erro = 'Não foi possível salvar: $e');
}
} finally {
_salvando = false;
}
},
icon: Icon(
hospedagem == null
? Icons.add
    : Icons.save_outlined,
),
label: Text(
hospedagem == null
? 'Adicionar hospedagem'
    : 'Salvar alterações',
),
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

nome.dispose();
cidade.dispose();
endereco.dispose();
valor.dispose();
}

void _abrirDetalhes(_Hospedagem h) {
showModalBottomSheet<void>(
context: context,
showDragHandle: true,
backgroundColor: AppColors.surface,
isScrollControlled: true,
builder: (sheetContext) {
return SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
child: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Icon(
Icons.hotel_rounded,
color: AppColors.primary,
size: 32,
),
const SizedBox(width: 12),
Expanded(
child: Text(
h.nome,
style: Theme.of(context)
    .textTheme
    .titleLarge,
),
),
IconButton(
onPressed: () =>
Navigator.pop(sheetContext),
icon: const Icon(Icons.close),
),
],
),
const SizedBox(height: 20),
_detalhe('Cidade', h.cidade),
_detalhe(
'Endereço',
h.endereco.isEmpty
? 'Não informado'
    : h.endereco,
),
_detalhe('Check-in', _data(h.checkIn)),
_detalhe('Check-out', _data(h.checkOut)),
_detalhe('Noites', '${h.noites}'),
_detalhe(
'Valor total',
h.valor == null
? 'Não informado'
    : _moeda(h.valor!),
),
const SizedBox(height: 20),
Row(
children: [
Expanded(
child: OutlinedButton.icon(
onPressed: () {
Navigator.pop(sheetContext);
_abrirFormulario(hospedagem: h);
},
icon: const Icon(Icons.edit_outlined),
label: const Text('Editar'),
),
),
const SizedBox(width: 10),
Expanded(
child: TextButton.icon(
onPressed: () {
Navigator.pop(sheetContext);
_confirmarExclusao(h);
},
icon: const Icon(
Icons.delete_outline,
color: AppColors.error,
),
label: const Text(
'Excluir',
style: TextStyle(
color: AppColors.error,
),
),
),
),
],
),
],
),
),
),
);
},
);
}

Widget _detalhe(String titulo, String valor) {
return Padding(
padding: const EdgeInsets.only(bottom: 12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
titulo,
style: const TextStyle(
color: AppColors.textMuted,
fontSize: 12,
),
),
const SizedBox(height: 4),
Text(
valor,
style: const TextStyle(
fontWeight: FontWeight.w600,
),
),
],
),
);
}

Future<void> _confirmarExclusao(_Hospedagem h) async {
final confirmar = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Excluir hospedagem?'),
content: Text(
'Deseja remover "${h.nome}" das suas reservas?',
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
),
);

if (confirmar != true || !mounted) return;

try {
await _client.from('hospedagens').delete().eq('id', h.id)
    .eq('viagemId', h.viagemId);
if (!mounted) return;
setState(() {
_hospedagens.removeWhere((item) => item.id == h.id && item.viagemId == h.viagemId);
});
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('${h.nome} removido.')),
);
} catch (e) {
_avisarErro(e);
}
}

Future<void> _abrirPesquisa() async {
final controller = TextEditingController(text: _busca);

await showDialog<void>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Pesquisar hospedagem'),
content: TextField(
controller: controller,
autofocus: true,
decoration: const InputDecoration(
hintText: 'Nome, cidade ou endereço',
prefixIcon: Icon(Icons.search),
),
onSubmitted: (texto) {
setState(() => _busca = texto);
Navigator.pop(dialogContext);
},
),
actions: [
TextButton(
onPressed: () {
setState(() => _busca = '');
Navigator.pop(dialogContext);
},
child: const Text('Limpar'),
),
FilledButton(
onPressed: () {
setState(() {
_busca = controller.text;
});
Navigator.pop(dialogContext);
},
child: const Text('Pesquisar'),
),
],
),
);

controller.dispose();
}
}

class _Hospedagem {
final String id;
final String viagemId;
final String nome;
final String cidade;
final String endereco;
final DateTime? checkIn;
final DateTime? checkOut;
final double? valor;

const _Hospedagem({
required this.id,
required this.viagemId,
required this.nome,
required this.cidade,
required this.endereco,
required this.checkIn,
required this.checkOut,
required this.valor,
});

factory _Hospedagem.fromModel(Hospedagem h) => _Hospedagem(
id: h.id, viagemId: h.viagemId, nome: h.nome,
cidade: h.endereco.contains(' • ') ? h.endereco.split(' • ').first : '',
endereco: h.endereco.contains(' • ') ? h.endereco.split(' • ').skip(1).join(' • ') : h.endereco, checkIn: h.checkIn,
checkOut: h.checkOut, valor: h.valorTotal,
);

Hospedagem toModel() => Hospedagem(
id: id, viagemId: viagemId, nome: nome,
endereco: cidade.isEmpty ? endereco : (endereco.isEmpty ? cidade : '$cidade • $endereco'),
checkIn: checkIn!, checkOut: checkOut!,
valorTotal: valor!,
);

int get noites {
if (checkIn == null || checkOut == null) return 0;

final diferenca =
checkOut!.difference(checkIn!).inDays;

return diferenca > 0 ? diferenca : 0;
}
}

class _ResumoItem extends StatelessWidget {
final IconData icone;
final String valor;
final String titulo;

const _ResumoItem({
required this.icone,
required this.valor,
required this.titulo,
});

@override
Widget build(BuildContext context) {
return Column(
children: [
Icon(
icone,
color: AppColors.primary,
size: 22,
),
const SizedBox(height: 8),
Text(
valor,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 4),
Text(
titulo,
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 11,
),
),
],
);
}
}

class _InfoItem extends StatelessWidget {
final String titulo;
final String valor;
final IconData icone;

const _InfoItem({
required this.titulo,
required this.valor,
required this.icone,
});

@override
Widget build(BuildContext context) {
return Column(
children: [
Icon(
icone,
color: AppColors.primary,
size: 19,
),
const SizedBox(height: 7),
Text(
titulo,
style: const TextStyle(
color: AppColors.textMuted,
fontSize: 11,
),
),
const SizedBox(height: 4),
Text(
valor,
maxLines: 2,
overflow: TextOverflow.ellipsis,
textAlign: TextAlign.center,
style: const TextStyle(
fontWeight: FontWeight.w700,
fontSize: 11,
),
),
],
);
}
}

