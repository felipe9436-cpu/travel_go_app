import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/avaliacao.dart';
import '../theme/app_colors.dart';
import '../widgets/avaliacao_card.dart';

class AvaliacaoScreen extends StatefulWidget {
  const AvaliacaoScreen({super.key, this.viagemId});

  final String? viagemId;

  @override
  State<AvaliacaoScreen> createState() => _AvaliacaoScreenState();
}

class _AvaliacaoScreenState extends State<AvaliacaoScreen> {
  final _supabase = Supabase.instance.client;
  final List<Avaliacao> _todasAvaliacoes = [];
  bool _carregando = false;
  String? _erroCarregamento;
  int _versaoBusca = 0;

  @override
  void initState() {
    super.initState();
    _carregarAvaliacoes();
  }

  Future<void> _carregarAvaliacoes() async {
    final viagemId = widget.viagemId;
    final versao = ++_versaoBusca;
    setState(() {
      _todasAvaliacoes.clear();
      _erroCarregamento = null;
      _carregando = viagemId != null;
    });
    if (viagemId == null) return;
    try {
      final dados = await _supabase.from('avaliacoes').select()
          .eq('viagemId', viagemId).order('data', ascending: false);
      if (!mounted || versao != _versaoBusca) return;
      setState(() {
        _todasAvaliacoes.addAll(dados.map((map) => Avaliacao.fromMap(map)));
        _carregando = false;
      });
    } catch (e) {
      if (!mounted || versao != _versaoBusca) return;
      setState(() {
        _carregando = false;
        _erroCarregamento = 'Não foi possível carregar as avaliações: $e';
      });
    }
  }

  Future<void> _salvarAvaliacao(Avaliacao avaliacao) async {
    await _supabase.from('avaliacoes').upsert(avaliacao.toMap());
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<Avaliacao> get _avaliacoes => _todasAvaliacoes
      .where((item) => item.viagemId == widget.viagemId)
      .toList();

  @override
  void didUpdateWidget(covariant AvaliacaoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viagemId != widget.viagemId) {
      _categoriaSelecionada = 'Todas';
      _carregarAvaliacoes();
    }
  }

  static const List<String> _categorias = [
    'Todas',
    'Destino',
    'Hospedagem',
    'Restaurante',
    'Passeio',
    'Transporte',
  ];

  String _categoriaSelecionada = 'Todas';
  String _ordenacao = 'recentes';
  int _proximoId = 0;

  double get _mediaAvaliacoes {
    if (_avaliacoes.isEmpty) return 0;

    final soma = _avaliacoes.fold<double>(
      0.0,
          (total, avaliacao) => total + avaliacao.nota,
    );

    return soma / _avaliacoes.length;
  }

  List<Avaliacao> get _avaliacoesFiltradas {
    final lista = _avaliacoes.where((avaliacao) {
      return _categoriaSelecionada == 'Todas' ||
          avaliacao.categoria == _categoriaSelecionada;
    }).toList();

    switch (_ordenacao) {
      case 'maior':
        lista.sort((a, b) {
          final resultado = b.nota.compareTo(a.nota);
          return resultado != 0
              ? resultado
              : b.data.compareTo(a.data);
        });
        break;

      case 'menor':
        lista.sort((a, b) {
          final resultado = a.nota.compareTo(b.nota);
          return resultado != 0
              ? resultado
              : b.data.compareTo(a.data);
        });
        break;

      default:
        lista.sort((a, b) => b.data.compareTo(a.data));
    }

    return lista;
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  IconData _iconeCategoria(String categoria) {
    switch (categoria) {
      case 'Destino':
        return Icons.travel_explore_outlined;
      case 'Hospedagem':
        return Icons.hotel_outlined;
      case 'Restaurante':
        return Icons.restaurant_outlined;
      case 'Passeio':
        return Icons.local_activity_outlined;
      case 'Transporte':
        return Icons.directions_car_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  String _novoId() {
    _proximoId++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_proximoId';
  }

  int _indiceAvaliacao(String id) {
    return _todasAvaliacoes.indexWhere(
          (avaliacao) => avaliacao.id == id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avaliacoes = _avaliacoesFiltradas;
    final temViagem = widget.viagemId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Avaliações',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (widget.viagemId != null && _avaliacoes.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Ordenar avaliações',
              initialValue: _ordenacao,
              onSelected: (valor) {
                setState(() {
                  _ordenacao = valor;
                });
              },
              icon: const Icon(Icons.sort),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'recentes',
                  child: Text('Mais recentes'),
                ),
                PopupMenuItem(
                  value: 'maior',
                  child: Text('Maior nota'),
                ),
                PopupMenuItem(
                  value: 'menor',
                  child: Text('Menor nota'),
                ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: temViagem && _carregando
          ? const Center(child: CircularProgressIndicator())
          : temViagem && _erroCarregamento != null
          ? Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erroCarregamento!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: _carregarAvaliacoes, child: const Text('Tentar novamente')),
        ]),
      ))
          : !temViagem
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.travel_explore_outlined,
                  size: 48, color: AppColors.primary),
              SizedBox(height: 16),
              Text('Selecione uma viagem',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Crie ou selecione uma viagem no Início para registrar suas avaliações.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      )
          : SafeArea(
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
                Text(
                  'Suas experiências',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Registre suas opiniões sobre os '
                      'lugares e serviços da viagem.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildResumo(),
                const SizedBox(height: 28),
                _buildCategorias(),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Suas avaliações',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${avaliacoes.length} itens',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (avaliacoes.isEmpty)
                  _buildEstadoVazio()
                else
                  ...avaliacoes.map(
                        (avaliacao) => Padding(
                      key: ValueKey(avaliacao.id),
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: AvaliacaoCard(
                        avaliacao: avaliacao,
                        onTap: () => _mostrarDetalhes(avaliacao),
                        onDelete: () =>
                            _confirmarExclusao(avaliacao),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: temViagem && _avaliacoes.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova avaliação'),
      )
          : null,
    );
  }

  Widget _buildResumo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Média das notas',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _avaliacoes.isEmpty
                      ? '—'
                      : _mediaAvaliacoes.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'De 5 estrelas',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 78,
            color: AppColors.border,
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Registradas',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_avaliacoes.length}',
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Avaliações',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorias() {
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

  Widget _buildEstadoVazio() {
    final vazioGeral = _avaliacoes.isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 32,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              vazioGeral
                  ? 'Nenhuma avaliação por aqui'
                  : 'Nenhuma avaliação nesta categoria',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              vazioGeral
                  ? 'Registre sua primeira experiência '
                  'para começar a avaliar sua viagem.'
                  : 'Selecione outra categoria para '
                  'visualizar suas avaliações.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (vazioGeral)
              FilledButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Criar avaliação'),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _categoriaSelecionada = 'Todas';
                  });
                },
                icon: const Icon(Icons.list),
                label: const Text('Ver todas'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormulario({
    Avaliacao? avaliacao,
  }) async {
    if (widget.viagemId == null) return;
    final nomeController = TextEditingController(
      text: avaliacao?.nome ?? '',
    );

    final comentarioController = TextEditingController(
      text: avaliacao?.comentario ?? '',
    );

    var categoria = avaliacao?.categoria ?? 'Destino';
    double nota = avaliacao?.nota ?? 5.0;
    var data = avaliacao?.data ?? DateTime.now();
    String? erro;
    var salvandoModal = false;

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
                        avaliacao == null
                            ? 'Nova avaliação'
                            : 'Editar avaliação',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Registre sua experiência '
                            'com um local ou serviço.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: nomeController,
                        autofocus: true,
                        textCapitalization:
                        TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText:
                          'Nome do local ou serviço *',
                          hintText:
                          'Ex.: Museu, hotel ou restaurante',
                          prefixIcon: Icon(
                            Icons.place_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: categoria,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(
                            Icons.category_outlined,
                          ),
                        ),
                        items: _categorias
                            .skip(1)
                            .map(
                              (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                            .toList(),
                        onChanged: (valor) {
                          if (valor != null) {
                            atualizarModal(() {
                              categoria = valor;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Sua nota',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 2,
                        children: [
                          for (var i = 1; i <= 5; i++)
                            IconButton(
                              tooltip: '$i estrelas',
                              onPressed: () {
                                atualizarModal(() {
                                  nota = i.toDouble();                                });
                              },
                              iconSize: 35,
                              icon: Icon(
                                i <= nota
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: comentarioController,
                        textCapitalization:
                        TextCapitalization.sentences,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText:
                          'Comentário (opcional)',
                          hintText:
                          'Conte como foi sua experiência',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selecionada =
                          await showDatePicker(
                            context: context,
                            initialDate: data,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (selecionada != null &&
                              sheetContext.mounted) {
                            atualizarModal(() {
                              data = selecionada;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                        ),
                        label: Text(
                          'Data: ${_formatarData(data)}',
                        ),
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
                          onPressed: salvandoModal ? null : () async {
                            final nome = nomeController.text.trim();
                            if (nome.isEmpty) {
                              atualizarModal(() => erro = 'Informe o nome do local ou serviço.');
                              return;
                            }
                            final comentario = comentarioController.text.trim();
                            final nova = Avaliacao(
                              id: avaliacao?.id ?? _novoId(),
                              viagemId: widget.viagemId!,
                              nome: nome,
                              categoria: categoria,
                              nota: nota,
                              comentario: comentario.isEmpty ? null : comentario,
                              data: data,
                            );
                            atualizarModal(() {
                              salvandoModal = true;
                              erro = null;
                            });
                            try {
                              await _salvarAvaliacao(nova);
                              if (!mounted || !sheetContext.mounted ||
                                  widget.viagemId != nova.viagemId) return;
                              setState(() {
                                final indice = _indiceAvaliacao(nova.id);
                                if (indice < 0) {
                                  _todasAvaliacoes.add(nova);
                                } else {
                                  _todasAvaliacoes[indice] = nova;
                                }
                                _categoriaSelecionada = 'Todas';
                              });
                              Navigator.pop(sheetContext);
                            } catch (e) {
                              if (sheetContext.mounted) {
                                atualizarModal(() => erro = 'Erro ao salvar avaliação: $e');
                              }
                            } finally {
                              if (sheetContext.mounted) {
                                atualizarModal(() => salvandoModal = false);
                              }
                            }
                          },
                          icon: Icon(
                            avaliacao == null
                                ? Icons.add
                                : Icons.save_outlined,
                          ),
                          label: Text(
                            avaliacao == null
                                ? 'Salvar avaliação'
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

    nomeController.dispose();
    comentarioController.dispose();
  }

  void _mostrarDetalhes(Avaliacao avaliacao) {
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
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconeCategoria(
                        avaliacao.categoria,
                      ),
                      color: AppColors.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        avaliacao.nome,
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
                const SizedBox(height: 12),
                Text(
                  '${avaliacao.categoria} • '
                      '${_formatarData(avaliacao.data)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                _buildEstrelas(
                  avaliacao.nota,
                  tamanho: 28,
                ),
                const SizedBox(height: 20),
                Text(
                  avaliacao.comentario == null ||
                      avaliacao.comentario!.isEmpty
                      ? 'Nenhum comentário registrado.'
                      : avaliacao.comentario!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _abrirFormulario(
                            avaliacao: avaliacao,
                          );
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
                          _confirmarExclusao(avaliacao);
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

  Widget _buildEstrelas(
      double nota, {
        double tamanho = 24,
      }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= nota
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: AppColors.primary,
            size: tamanho,
          ),
        const SizedBox(width: 8),
        Text(
          '${nota.toStringAsFixed(1)}/5',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarExclusao(
      Avaliacao avaliacao,
      ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir avaliação?'),
        content: Text(
          'Deseja excluir a avaliação de '
              '"${avaliacao.nome}"?',
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
      await _supabase.from('avaliacoes').delete()
          .eq('id', avaliacao.id).eq('viagemId', avaliacao.viagemId);
      if (!mounted) return;
      setState(() => _todasAvaliacoes.removeWhere((a) => a.id == avaliacao.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avaliação de "${avaliacao.nome}" removida.')),
      );
    } catch (e) {
      _mostrarErro('Não foi possível excluir a avaliação: $e');
    }
  }
}
