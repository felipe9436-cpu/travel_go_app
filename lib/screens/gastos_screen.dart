import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/gasto.dart';
import '../models/viagem.dart';
import '../theme/app_colors.dart';

/// Versão simplificada para isolar erros de montagem de widgets.
/// Mantém leitura, cadastro, edição, exclusão e orçamento no Supabase.
class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key, this.viagem, this.onOrcamentoAlterado});

  final Viagem? viagem;
  final ValueChanged<double>? onOrcamentoAlterado;

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final _supabase = Supabase.instance.client;
  List<Gasto> _gastos = [];
  bool _carregando = false;
  String? _erro;
  int _versaoConsulta = 0;

  String? get _viagemId => widget.viagem?.id;
  double get _orcamento => widget.viagem?.orcamento ?? 0;
  double get _total => _gastos.fold<double>(0, (s, g) => s + g.valor);

  static const _categorias = [
    'Alimentação', 'Transporte', 'Hospedagem',
    'Passeio', 'Compras', 'Outros',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregar();
    });
  }

  @override
  void didUpdateWidget(covariant GastosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viagem?.id != widget.viagem?.id) {
      _versaoConsulta++;
      _gastos = [];
      _erro = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _carregar();
      });
    }
  }

  Future<void> _carregar() async {
    final id = _viagemId;
    final versao = ++_versaoConsulta;
    if (id == null) {
      if (mounted) setState(() { _gastos = []; _carregando = false; _erro = null; });
      return;
    }
    setState(() { _carregando = true; _erro = null; });
    try {
      final linhas = await _supabase
          .from('gastos')
          .select()
          .eq('viagemId', id)
          .order('data', ascending: false);
      if (!mounted || versao != _versaoConsulta || id != _viagemId) return;
      setState(() => _gastos = linhas.map((e) => Gasto.fromMap(e)).toList());
    } catch (e) {
      if (!mounted || versao != _versaoConsulta || id != _viagemId) return;
      setState(() => _erro = 'Não foi possível carregar os gastos: $e');
    } finally {
      if (mounted && versao == _versaoConsulta && id == _viagemId) {
        setState(() => _carregando = false);
      }
    }
  }

  void _aviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _dinheiro(double valor) =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  double? _numero(String texto) {
    var s = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }

  Future<void> _formulario({Gasto? existente}) async {
    final viagemId = _viagemId;
    if (viagemId == null) return;
    final descricao = TextEditingController(text: existente?.descricao ?? '');
    final valor = TextEditingController(
      text: existente == null ? '' : existente.valor.toStringAsFixed(2),
    );
    String categoria = existente?.categoria ?? _categorias.first;
    DateTime data = existente?.data ?? DateTime.now();
    bool salvando = false;
    String? erro;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, atualizar) => AlertDialog(
          title: Text(existente == null ? 'Novo gasto' : 'Editar gasto'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: descricao,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categoria,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: salvando ? null : (c) {
                  if (c != null) atualizar(() => categoria = c);
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text('${data.day}/${data.month}/${data.year}'),
                onPressed: salvando ? null : () async {
                  final novaData = await showDatePicker(
                    context: dialogContext,
                    initialDate: data,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (novaData != null && dialogContext.mounted) {
                    atualizar(() => data = novaData);
                  }
                },
              ),
              if (erro != null) Text(erro!, style: const TextStyle(color: Colors.red)),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: salvando ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando ? null : () async {
                final quantia = _numero(valor.text);
                if (descricao.text.trim().isEmpty || quantia == null ||
                    !quantia.isFinite || quantia <= 0) {
                  atualizar(() => erro = 'Informe uma descrição e um valor válido.');
                  return;
                }
                atualizar(() { salvando = true; erro = null; });
                final gasto = Gasto(
                  id: existente?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                  viagemId: viagemId,
                  descricao: descricao.text.trim(),
                  valor: quantia,
                  categoria: categoria,
                  data: data,
                  observacao: existente?.observacao,
                );
                try {
                  await _supabase.from('gastos').upsert(gasto.toMap());
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted && _viagemId == viagemId) await _carregar();
                } catch (e) {
                  if (dialogContext.mounted) atualizar(() => erro = 'Erro ao salvar: $e');
                } finally {
                  if (dialogContext.mounted) atualizar(() => salvando = false);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    // Aguarda a animação de fechamento antes de liberar os controllers.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    descricao.dispose();
    valor.dispose();
  }

  Future<void> _excluir(Gasto gasto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir gasto?'),
        content: Text('Excluir "${gasto.descricao}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await _supabase.from('gastos').delete()
          .eq('id', gasto.id).eq('viagemId', gasto.viagemId);
      if (mounted) await _carregar();
    } catch (e) {
      _aviso('Erro ao excluir: $e');
    }
  }

  Future<void> _editarOrcamento() async {
    if (_viagemId == null || widget.onOrcamentoAlterado == null) return;
    final controller = TextEditingController(text: _orcamento.toStringAsFixed(2));
    final valor = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Orçamento da viagem'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Valor em R\$'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final numero = _numero(controller.text);
              if (numero == null || !numero.isFinite || numero <= 0) return;
              Navigator.pop(ctx, numero);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
    if (valor != null && mounted) widget.onOrcamentoAlterado?.call(valor);
  }

  @override
  Widget build(BuildContext context) {
    final id = _viagemId;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gastos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: id == null ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Editar orçamento',
            onPressed: id == null ? null : _editarOrcamento,
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
      body: id == null
          ? const Center(child: Text('Selecione uma viagem no Início.'))
          : _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erro!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: _carregar, child: const Text('Tentar novamente')),
        ]),
      ))
          : RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total de despesas'),
                const SizedBox(height: 8),
                Text(_dinheiro(_total), style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 14),
                Text('Orçamento: ${_dinheiro(_orcamento)}'),
                Text('Restante: ${_dinheiro(_orcamento - _total)}'),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _orcamento <= 0 ? 0 : (_total / _orcamento).clamp(0.0, 1.0),
                ),
              ]),
            )),
            const SizedBox(height: 18),
            Text('Despesas (${_gastos.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (_gastos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 35),
                child: Center(child: Text('Nenhum gasto registrado.')),
              ),
            for (final gasto in _gastos)
              Card(child: ListTile(
                title: Text(gasto.descricao),
                subtitle: Text('${gasto.categoria} • ${gasto.data.day}/${gasto.data.month}/${gasto.data.year}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_dinheiro(gasto.valor)),
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _formulario(existente: gasto),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _excluir(gasto),
                  ),
                ]),
              )),
          ],
        ),
      ),
      floatingActionButton: id == null
          ? null
          : FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar gasto'),
      ),
    );
  }
}
