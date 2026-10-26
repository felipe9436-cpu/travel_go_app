import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/checklist_item.dart';
import '../theme/app_colors.dart';
import '../widgets/checklist_tile.dart';

class ChecklistScreen extends StatefulWidget {
  final String? viagemId;

  const ChecklistScreen({super.key, this.viagemId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final List<ChecklistItem> _itens = [];
  final _client = Supabase.instance.client;
  bool _carregando = false;
  bool _salvando = false;
  String? _erroCarregamento;

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  Future<void> _carregarItens() async {
    final viagemId = _viagemId;
    if (viagemId == null) {
      if (mounted) setState(() { _itens.clear(); _carregando = false; });
      return;
    }
    setState(() { _carregando = true; _erroCarregamento = null; });
    try {
      final dados = await _client.from('checklist_itens')
          .select().eq('viagemId', viagemId).order('titulo');
      if (!mounted || _viagemId != viagemId) return;
      setState(() {
        _itens..clear()..addAll(dados.map((e) => ChecklistItem.fromMap(e)));
      });
    } catch (e) {
      if (mounted && _viagemId == viagemId) {
        setState(() => _erroCarregamento = 'Não foi possível carregar o checklist: $e');
      }
    } finally {
      if (mounted && _viagemId == viagemId) setState(() => _carregando = false);
    }
  }

  Future<void> _salvarItem(ChecklistItem item) async {
    await _client.from('checklist_itens').upsert(item.toMap());
  }

  Future<void> _excluirItem(String id) async {
    await _client.from('checklist_itens').delete().eq('id', id);
  }

  Future<void> _alterarTodos({required bool concluido}) async {
    final viagemId = _viagemId;
    if (viagemId == null || _salvando) return;
    setState(() => _salvando = true);
    try {
      await _client.from('checklist_itens')
          .update({'concluido': concluido}).eq('viagemId', viagemId);
      if (mounted && _viagemId == viagemId) await _carregarItens();
    } catch (e) {
      if (mounted) _mostrarMensagem('Erro ao atualizar os itens: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }


  String? get _viagemId => widget.viagemId;
  List<ChecklistItem> get _itensDaViagem => _itens
      .where((item) => item.viagemId == _viagemId && _viagemId != null)
      .toList();

  @override
  void didUpdateWidget(covariant ChecklistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viagemId != widget.viagemId) {
      _categoriaSelecionada = 'Todos';
      _carregarItens();
    }
  }


  static const List<String> _categorias = [
    'Todos',
    'Documentos',
    'Reservas',
    'Mala',
    'Compras',
    'Viagem',
  ];

  String _categoriaSelecionada = 'Todos';
  int _contadorIds = 0;

  int get _totalItens => _itensDaViagem.length;

  int get _concluidos =>
      _itensDaViagem.where((item) => item.concluido).length;

  double get _progresso =>
      _totalItens == 0 ? 0 : _concluidos / _totalItens;

  List<ChecklistItem> get _itensFiltrados {
    final lista = _itensDaViagem.where((item) {
      return _categoriaSelecionada == 'Todos' ||
          item.categoria == _categoriaSelecionada;
    }).toList();

    lista.sort((a, b) {
      if (a.concluido != b.concluido) {
        return a.concluido ? 1 : -1;
      }

      return a.titulo.toLowerCase().compareTo(
        b.titulo.toLowerCase(),
      );
    });

    return lista;
  }

  String _novoId() {
    _contadorIds++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_contadorIds';
  }

  int _indiceItem(String id) {
    return _itens.indexWhere((item) => item.id == id && item.viagemId == _viagemId);
  }

  IconData _iconeCategoria(String categoria) {
    switch (categoria) {
      case 'Documentos':
        return Icons.badge_outlined;
      case 'Reservas':
        return Icons.hotel_outlined;
      case 'Mala':
        return Icons.luggage_outlined;
      case 'Compras':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.travel_explore_outlined;
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final itens = _itensFiltrados;
    final temViagem = _viagemId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Checklist',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Opções do checklist',
            onPressed: temViagem ? _abrirOpcoes : null,
            icon: const Icon(Icons.more_vert),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final margem =
            constraints.maxWidth >= 800 ? 36.0 : 20.0;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                margem,
                20,
                margem,
                110,
              ),
              children: [
                if (!temViagem)
                  _buildSemViagem()
                else ...[
                  Text(
                    'Organize sua viagem',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Adicione suas tarefas e acompanhe '
                        'o que ainda falta preparar.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProgresso(),
                  const SizedBox(height: 28),
                  _buildFiltros(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Itens da viagem',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '$_concluidos/$_totalItens',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Toque em uma tarefa para ver os detalhes '
                        'ou marque o checkbox para concluí-la.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_carregando)
                    const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                  else if (_erroCarregamento != null)
                    Column(children: [Text(_erroCarregamento!), TextButton(onPressed: _carregarItens, child: const Text('Tentar novamente'))])
                  else if (itens.isEmpty)
                      _buildVazio()
                    else
                      ...itens.map(
                            (item) => Padding(
                          key: ValueKey(item.id),
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: ChecklistTile(
                            item: item,
                            onToggle: () => _alternarItem(item),
                            onDelete: () =>
                                _confirmarExclusao(item),
                            onTap: () => _abrirDetalhes(item),
                          ),
                        ),
                      ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: temViagem && _itensDaViagem.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _salvando ? null : () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar item'),
      )
          : null,
    );
  }

  Widget _buildSemViagem() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.travel_explore_outlined,
                color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            const Text('Selecione uma viagem',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'Crie ou selecione uma viagem na tela Início para organizar seu checklist.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgresso() {
    final completo =
        _totalItens > 0 && _concluidos == _totalItens;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  completo
                      ? Icons.check_circle_outline
                      : Icons.checklist_outlined,
                  color: completo
                      ? AppColors.success
                      : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      completo
                          ? 'Tudo pronto!'
                          : 'Progresso da viagem',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$_concluidos de $_totalItens itens concluídos',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(_progresso * 100).round()}%',
                style: TextStyle(
                  color: completo
                      ? AppColors.success
                      : AppColors.primary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: _progresso,
              minHeight: 9,
              backgroundColor: AppColors.border,
              color: completo
                  ? AppColors.success
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_concluidos concluídos',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${_totalItens - _concluidos} restantes',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorias',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 43,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categorias.length,
            separatorBuilder: (context, index) =>
            const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final categoria = _categorias[index];

              return ChoiceChip(
                label: Text(categoria),
                selected:
                _categoriaSelecionada == categoria,
                showCheckmark: false,
                onSelected: (selecionado) {
                  setState(() {
                    _categoriaSelecionada = categoria;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVazio() {
    final vazioGeral = _itensDaViagem.isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 32,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.checklist_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              vazioGeral
                  ? 'Seu checklist está vazio'
                  : 'Nenhum item nesta categoria',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              vazioGeral
                  ? 'Comece adicionando as tarefas '
                  'que precisa preparar para sua viagem.'
                  : 'Selecione outra categoria para '
                  'visualizar seus itens.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (vazioGeral)
              FilledButton.icon(
                onPressed: _salvando ? null : () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Criar primeiro item'),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _categoriaSelecionada = 'Todos';
                  });
                },
                icon: const Icon(Icons.list),
                label: const Text('Ver todos'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _alternarItem(ChecklistItem item) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final atualizado = item.alternarConclusao();
    try {
      await _salvarItem(atualizado);
      if (!mounted) return;
      final indice = _indiceItem(item.id);
      if (indice >= 0) setState(() => _itens[indice] = atualizado);
      if (atualizado.concluido) _mostrarMensagem('${atualizado.titulo} concluído!');
    } catch (e) {
      if (mounted) _mostrarMensagem('Erro ao atualizar item: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _abrirFormulario({
    ChecklistItem? item,
  }) async {
    if (_viagemId == null) return;
    final tituloController = TextEditingController(
      text: item?.titulo ?? '',
    );

    final observacaoController = TextEditingController(
      text: item?.observacao ?? '',
    );

    var categoria = item?.categoria ?? 'Viagem';
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
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        item == null
                            ? 'Adicionar item'
                            : 'Editar item',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Organize as tarefas da sua viagem.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: tituloController,
                        autofocus: true,
                        textCapitalization:
                        TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nome do item *',
                          hintText:
                          'Ex.: Separar documentos',
                          prefixIcon: Icon(
                            Icons.checklist_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: observacaoController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Observação (opcional)',
                          hintText: 'Detalhes da tarefa...',
                          prefixIcon: Icon(
                            Icons.notes_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Categoria',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final opcao
                          in _categorias.skip(1))
                            ChoiceChip(
                              label: Text(opcao),
                              selected: categoria == opcao,
                              showCheckmark: false,
                              onSelected: (selecionado) {
                                atualizarModal(() {
                                  categoria = opcao;
                                });
                              },
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
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _salvando ? null : () async {
                            final titulo = tituloController.text.trim();
                            final observacao = observacaoController.text.trim();
                            if (titulo.isEmpty) {
                              atualizarModal(() => erro = 'Digite o nome do item.');
                              return;
                            }
                            final viagemId = _viagemId;
                            if (viagemId == null) return;
                            final atualizado = ChecklistItem(
                              id: item?.id ?? _novoId(), viagemId: viagemId,
                              titulo: titulo, categoria: categoria,
                              concluido: item?.concluido ?? false,
                              observacao: observacao.isEmpty ? null : observacao,
                            );
                            atualizarModal(() => erro = null);
                            setState(() => _salvando = true);
                            try {
                              await _salvarItem(atualizado);
                              if (!mounted || _viagemId != viagemId) return;
                              setState(() {
                                final indice = _indiceItem(atualizado.id);
                                if (indice >= 0) { _itens[indice] = atualizado; }
                                else { _itens.add(atualizado); }
                                _categoriaSelecionada = 'Todos';
                              });
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            } catch (e) {
                              if (sheetContext.mounted) atualizarModal(() => erro = 'Erro ao salvar: $e');
                            } finally {
                              if (mounted) setState(() => _salvando = false);
                            }
                          },
                          icon: Icon(
                            item == null
                                ? Icons.add
                                : Icons.save_outlined,
                          ),
                          label: Text(
                            item == null
                                ? 'Adicionar item'
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

    tituloController.dispose();
    observacaoController.dispose();
  }

  void _abrirDetalhes(ChecklistItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              22,
              8,
              22,
              26,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconeCategoria(item.categoria),
                      color: item.concluido
                          ? AppColors.success
                          : AppColors.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.titulo,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
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
                const SizedBox(height: 10),
                Text(
                  item.categoria,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.observacao != null &&
                    item.observacao!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    item.observacao!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.concluido
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    color: item.concluido
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                  title: const Text('Status'),
                  subtitle: Text(
                    item.concluido
                        ? 'Concluído'
                        : 'Pendente',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _alternarItem(item);
                    },
                    icon: Icon(
                      item.concluido
                          ? Icons.undo
                          : Icons.check,
                    ),
                    label: Text(
                      item.concluido
                          ? 'Marcar como pendente'
                          : 'Marcar como concluído',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _abrirFormulario(item: item);
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                        ),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _confirmarExclusao(item);
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
        );
      },
    );
  }

  Future<void> _confirmarExclusao(
      ChecklistItem item,
      ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir item?'),
        content: Text(
          'Deseja excluir "${item.titulo}"?',
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
      await _excluirItem(item.id);
      if (!mounted) return;
      setState(() => _itens.removeWhere((e) => e.id == item.id));
      _mostrarMensagem('${item.titulo} removido.');
    } catch (e) {
      if (mounted) _mostrarMensagem('Erro ao excluir: $e');
    }
  }

  void _abrirOpcoes() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  enabled: _itensDaViagem.isNotEmpty,
                  leading: const Icon(
                    Icons.done_all,
                    color: AppColors.success,
                  ),
                  title: const Text(
                    'Marcar tudo como concluído',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _alterarTodos(concluido: true);
                  },
                ),
                ListTile(
                  enabled: _itensDaViagem.isNotEmpty,
                  leading: const Icon(
                    Icons.restart_alt,
                  ),
                  title: const Text(
                    'Desmarcar todos',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _alterarTodos(concluido: false);
                  },
                ),
                ListTile(
                  enabled: _concluidos > 0,
                  leading: const Icon(
                    Icons.delete_sweep_outlined,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Limpar itens concluídos',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmarLimpeza();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmarLimpeza() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Limpar itens concluídos?',
        ),
        content: Text(
          'Serão removidos $_concluidos itens concluídos.',
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
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final viagemId = _viagemId;
      if (viagemId == null) return;
      await _client.from('checklist_itens').delete()
          .eq('viagemId', viagemId).eq('concluido', true);
      if (mounted && _viagemId == viagemId) await _carregarItens();
    } catch (e) {
      if (mounted) _mostrarMensagem('Erro ao limpar checklist: $e');
    }
  }
}

