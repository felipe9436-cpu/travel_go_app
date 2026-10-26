import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/viagem.dart';
import '../models/roteiro.dart';
import '../services/storage_service.dart';

class RoteiroScreen extends StatefulWidget {
  final Viagem? viagem;

  const RoteiroScreen({super.key, required this.viagem});

  @override
  State<RoteiroScreen> createState() => _RoteiroScreenState();
}

class _RoteiroScreenState extends State<RoteiroScreen> {
  // Cada viagem mantém suas próprias atividades enquanto o app está aberto.
  final StorageService _storage = StorageService();
  final Map<String, Map<DateTime, List<_Atividade>>> _atividadesPorViagem = {};
  bool _carregando = false;
  String? _erroCarregamento;

  Future<void> _carregarRoteiro() async {
    final viagemId = widget.viagem?.id;
    if (viagemId == null) return;
    setState(() { _carregando = true; _erroCarregamento = null; });
    try {
      final itens = await _storage.getRoteiro(viagemId);
      if (!mounted || widget.viagem?.id != viagemId) return;
      final agrupados = <DateTime, List<_Atividade>>{};
      for (final item in itens) {
        final dia = _normalizar(item.data);
        agrupados.putIfAbsent(dia, () => []).add(_Atividade.fromRoteiro(item));
      }
      setState(() { _atividadesPorViagem[viagemId] = agrupados; });
    } catch (erro) {
      if (mounted && widget.viagem?.id == viagemId) {
        setState(() { _erroCarregamento = 'Não foi possível carregar o roteiro: $erro'; });
      }
    } finally {
      if (mounted && widget.viagem?.id == viagemId) {
        setState(() { _carregando = false; });
      }
    }
  }

  void _avisarErro(Object erro) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao salvar no Supabase: $erro')),
    );
  }

  Map<DateTime, List<_Atividade>> get _atividades {
    final id = widget.viagem?.id;
    if (id == null) return <DateTime, List<_Atividade>>{};
    return _atividadesPorViagem.putIfAbsent(id, () => {});
  }

  List<DateTime> get _dias {
    final viagem = widget.viagem;
    if (viagem == null) return [];
    final inicio = _normalizar(viagem.dataInicio);
    final fim = _normalizar(viagem.dataFim);
    final quantidade = fim.difference(inicio).inDays + 1;
    if (quantidade <= 0 || quantidade > 365) return [];
    return List.generate(quantidade, (i) => DateTime(inicio.year, inicio.month, inicio.day + i));
  }

  @override
  void initState() {
    super.initState();
    _sincronizarDia();
    _carregarRoteiro();
  }

  @override
  void didUpdateWidget(covariant RoteiroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viagem?.id != widget.viagem?.id ||
        oldWidget.viagem?.dataInicio != widget.viagem?.dataInicio ||
        oldWidget.viagem?.dataFim != widget.viagem?.dataFim) {
      _sincronizarDia();
      _carregarRoteiro();
    }
  }

  void _sincronizarDia() {
    final dias = _dias;
    _diaSelecionado = dias.isEmpty ? null : dias.first;
  }

  DateTime? _diaSelecionado;
  String _ordenacao = 'Horário';

  static const _categorias = [
    'Passeio',
    'Cultura',
    'Alimentação',
    'Compras',
    'Transporte',
    'Outros',
  ];

  DateTime _normalizar(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  List<_Atividade> get _atividadesDoDia {
    final dia = _diaSelecionado;
    if (dia == null) return [];

    final lista = List<_Atividade>.from(
      _atividades[dia] ?? [],
    );

    if (_ordenacao == 'Categoria') {
      lista.sort(
            (a, b) => a.categoria.compareTo(b.categoria),
      );
    } else {
      lista.sort(
            (a, b) => a.minutos.compareTo(b.minutos),
      );
    }

    return lista;
  }

  int get _totalAtividades => _atividades.values.fold(
    0,
        (total, lista) => total + lista.length,
  );

  int get _totalLocais {
    final locais = <String>{};

    for (final lista in _atividades.values) {
      for (final atividade in lista) {
        if (atividade.local.trim().isNotEmpty) {
          locais.add(
            atividade.local.trim().toLowerCase(),
          );
        }
      }
    }

    return locais.length;
  }

  String _formatarData(DateTime data) {
    const meses = [
      'JAN', 'FEV', 'MAR', 'ABR',
      'MAI', 'JUN', 'JUL', 'AGO',
      'SET', 'OUT', 'NOV', 'DEZ',
    ];

    return '${data.day} ${meses[data.month - 1]}';
  }

  String _diaSemana(DateTime data) {
    const semanas = [
      'SEG', 'TER', 'QUA', 'QUI',
      'SEX', 'SÁB', 'DOM',
    ];

    return semanas[data.weekday - 1];
  }

  String _horario(TimeOfDay horario) {
    final horas = horario.hour.toString().padLeft(2, '0');
    final minutos =
    horario.minute.toString().padLeft(2, '0');

    return '$horas:$minutos';
  }

  IconData _iconeCategoria(String categoria) {
    switch (categoria) {
      case 'Cultura':
        return Icons.museum_outlined;
      case 'Alimentação':
        return Icons.restaurant_outlined;
      case 'Compras':
        return Icons.shopping_bag_outlined;
      case 'Transporte':
        return Icons.directions_bus_outlined;
      case 'Outros':
        return Icons.more_horiz;
      default:
        return Icons.explore_outlined;
    }
  }

  Color _corCategoria(String categoria) {
    switch (categoria) {
      case 'Cultura':
        return AppColors.primary;
      case 'Alimentação':
        return AppColors.success;
      case 'Compras':
        return Color(0xFFAA8CFF);
      case 'Transporte':
        return AppColors.blue;
      case 'Outros':
        return AppColors.textSecondary;
      default:
        return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final possuiDias = _dias.isNotEmpty;
    final possuiViagem = widget.viagem != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Roteiro',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Opções do roteiro',
            onPressed: _mostrarOpcoes,
            icon: Icon(Icons.more_horiz),
          ),
          SizedBox(width: 8),
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
                Text(
                  'Planeje seus dias',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Organize atividades, horários e lugares '
                      'em uma linha do tempo.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24),
                if (possuiViagem) ...[
                  Chip(
                    avatar: Icon(Icons.luggage_outlined, size: 17),
                    label: Text('Viagem: ${widget.viagem!.nome}'),
                  ),
                  SizedBox(height: 16),
                ],
                if (_carregando) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                if (_erroCarregamento != null) ...[
                  Text(_erroCarregamento!, style: TextStyle(color: AppColors.error)),
                  TextButton(onPressed: _carregarRoteiro, child: const Text('Tentar novamente')),
                ],
                _buildResumoGeral(),
                SizedBox(height: 28),
                if (!possuiDias)
                  _buildEstadoInicial()
                else ...[
                  _buildSeletorDias(),
                  SizedBox(height: 28),
                  _buildCabecalhoDia(),
                  SizedBox(height: 16),
                  if (_atividadesDoDia.isEmpty)
                    _buildDiaVazio()
                  else
                    ..._atividadesDoDia.map(
                      _buildCardAtividade,
                    ),
                  SizedBox(height: 20),
                  _buildResumoDia(),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: possuiDias
          ? FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: Icon(Icons.add),
        label: Text('Adicionar atividade'),
      )
          : null,
    );
  }

  Widget _buildResumoGeral() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route_outlined,
                  color: AppColors.primary,
                  size: 27,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Planejamento da viagem',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Indicador(
                    valor: '${_dias.length}',
                    titulo: 'Dias',
                    icone: Icons.calendar_month_outlined,
                  ),
                ),
                Expanded(
                  child: _Indicador(
                    valor: '$_totalAtividades',
                    titulo: 'Atividades',
                    icone: Icons.event_note_outlined,
                  ),
                ),
                Expanded(
                  child: _Indicador(
                    valor: '$_totalLocais',
                    titulo: 'Locais',
                    icone: Icons.place_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoInicial() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 36,
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              widget.viagem == null ? 'Selecione uma viagem' : 'Confira as datas da viagem',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              widget.viagem == null
                  ? 'Crie ou selecione uma viagem na tela Início para montar o roteiro.'
                  : 'Ajuste o período da viagem na tela Início para planejar suas atividades.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            FilledButton.icon(
              onPressed: null,
              icon: Icon(Icons.date_range),
              label: Text('Datas definidas na Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeletorDias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dias da viagem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: null,
              icon: Icon(
                Icons.edit_calendar_outlined,
                size: 18,
              ),
              label: Text('Editar na Home'),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dias.length,
            separatorBuilder: (context, index) =>
                SizedBox(width: 10),
            itemBuilder: (context, index) {
              final dia = _dias[index];
              final selecionado =
                  _diaSelecionado == dia;

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    _diaSelecionado = dia;
                  });
                },
                child: AnimatedContainer(
                  duration:
                  Duration(milliseconds: 200),
                  width: 78,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius:
                    BorderRadius.circular(18),
                    border: Border.all(
                      color: selecionado
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Text(
                        _diaSemana(dia),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: selecionado
                              ? Colors.black
                              : AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: selecionado
                              ? Colors.black
                              : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        _formatarData(dia),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selecionado
                              ? Colors.black87
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCabecalhoDia() {
    final indice = _dias.indexOf(_diaSelecionado!) + 1;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Dia $indice',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${_atividadesDoDia.length} '
                    '${_atividadesDoDia.length == 1 ? 'atividade' : 'atividades'}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Ordenar atividades',
          icon: Icon(Icons.sort),
          initialValue: _ordenacao,
          onSelected: (valor) {
            setState(() {
              _ordenacao = valor;
            });
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'Horário',
              child: Text('Por horário'),
            ),
            PopupMenuItem(
              value: 'Categoria',
              child: Text('Por categoria'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiaVazio() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 32,
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              color: AppColors.primary,
              size: 46,
            ),
            SizedBox(height: 16),
            Text(
              'Dia livre',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Você ainda não adicionou '
                  'atividades para este dia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: Icon(Icons.add),
              label: Text('Adicionar atividade'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAtividade(_Atividade atividade) {
    final cor = _corCategoria(atividade.categoria);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Text(
                _horario(atividade.horario),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(top: 25),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius:
                BorderRadius.circular(18),
                onTap: () =>
                    _abrirDetalhes(atividade),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconeCategoria(
                            atividade.categoria,
                          ),
                          color: cor,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              atividade.categoria
                                  .toUpperCase(),
                              style: TextStyle(
                                color: cor,
                                fontSize: 10,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              atividade.titulo,
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            if (atividade.local
                                .isNotEmpty) ...[
                              SizedBox(height: 5),
                              Text(
                                atividade.local,
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors
                                      .textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
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

  Widget _buildResumoDia() {
    final atividades = _atividadesDoDia;
    final locais = atividades
        .map((atividade) =>
        atividade.local.trim().toLowerCase())
        .where((local) => local.isNotEmpty)
        .toSet()
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do dia',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Indicador(
                    valor: '${atividades.length}',
                    titulo: 'Atividades',
                    icone: Icons.event_note_outlined,
                  ),
                ),
                Expanded(
                  child: _Indicador(
                    valor: '$locais',
                    titulo: 'Locais',
                    icone: Icons.place_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormulario({
    _Atividade? atividade,
  }) async {
    final dia = _diaSelecionado;
    if (dia == null) return;

    final tituloController = TextEditingController(
      text: atividade?.titulo ?? '',
    );

    final localController = TextEditingController(
      text: atividade?.local ?? '',
    );

    var horarioSelecionado =
        atividade?.horario ??
            TimeOfDay(hour: 10, minute: 0);

    var categoriaSelecionada =
        atividade?.categoria ?? 'Passeio';

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
                  MediaQuery.viewInsetsOf(context)
                      .bottom +
                      24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        atividade == null
                            ? 'Nova atividade'
                            : 'Editar atividade',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Dia ${_dias.indexOf(dia) + 1} '
                            '• ${_formatarData(dia)}',
                        style: TextStyle(
                          color:
                          AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 22),
                      TextField(
                        controller: tituloController,
                        textCapitalization:
                        TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Atividade *',
                          prefixIcon:
                          Icon(Icons.event_outlined),
                          hintText:
                          'Ex.: Visitar um museu',
                        ),
                        onChanged: (_) {
                          if (erro != null) {
                            atualizarModal(() {
                              erro = null;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 14),
                      TextField(
                        controller: localController,
                        textCapitalization:
                        TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Local (opcional)',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Horário',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final horario =
                            await showTimePicker(
                              context: context,
                              initialTime:
                              horarioSelecionado,
                            );

                            if (horario != null) {
                              atualizarModal(() {
                                horarioSelecionado =
                                    horario;
                              });
                            }
                          },
                          icon: Icon(
                            Icons.schedule_outlined,
                          ),
                          label: Text(
                            _horario(
                              horarioSelecionado,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Categoria',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final categoria
                          in _categorias)
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
                        SizedBox(height: 12),
                        Text(
                          erro!,
                          style: TextStyle(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final titulo = tituloController.text.trim();
                            if (titulo.isEmpty) {
                              atualizarModal(() { erro = 'Informe o nome da atividade.'; });
                              return;
                            }
                            final viagemId = widget.viagem?.id;
                            if (viagemId == null) return;
                            final nova = _Atividade(
                              id: atividade?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                              titulo: titulo,
                              local: localController.text.trim(),
                              categoria: categoriaSelecionada,
                              horario: horarioSelecionado,
                              data: dia,
                            );
                            try {
                              await _storage.salvarRoteiro(nova.toRoteiro(viagemId));
                              if (!mounted || !sheetContext.mounted || widget.viagem?.id != viagemId) return;
                              setState(() {
                                final lista = _atividades.putIfAbsent(dia, () => []);
                                if (atividade == null) {
                                  lista.add(nova);
                                } else {
                                  final indice = lista.indexWhere((a) => a.id == atividade.id);
                                  if (indice >= 0) lista[indice] = nova;
                                }
                              });
                              Navigator.pop(sheetContext);
                            } catch (e) {
                              if (sheetContext.mounted) atualizarModal(() { erro = 'Erro ao salvar: $e'; });
                            }
                          },
                          icon: Icon(
                            atividade == null
                                ? Icons.add
                                : Icons.save_outlined,
                          ),
                          label: Text(
                            atividade == null
                                ? 'Adicionar ao roteiro'
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

    // Aguarda a animação de fechamento.
    await Future<void>.delayed(
      Duration(milliseconds: 300),
    );

    tituloController.dispose();
    localController.dispose();
  }

  void _abrirDetalhes(_Atividade atividade) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              8,
              22,
              24,
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
                        atividade.categoria,
                      ),
                      color: _corCategoria(
                        atividade.categoria,
                      ),
                      size: 30,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        atividade.titulo,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                _linhaDetalhe(
                  Icons.schedule_outlined,
                  'Horário',
                  _horario(atividade.horario),
                ),
                _linhaDetalhe(
                  Icons.category_outlined,
                  'Categoria',
                  atividade.categoria,
                ),
                _linhaDetalhe(
                  Icons.place_outlined,
                  'Local',
                  atividade.local.isEmpty
                      ? 'Não informado'
                      : atividade.local,
                ),
                SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _abrirFormulario(
                            atividade: atividade,
                          );
                        },
                        icon: Icon(
                          Icons.edit_outlined,
                        ),
                        label: Text('Editar'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _excluirAtividade(atividade);
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        label: Text(
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

  Widget _linhaDetalhe(
      IconData icone,
      String titulo,
      String valor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(
            icone,
            color: AppColors.primary,
            size: 21,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  valor,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirAtividade(
      _Atividade atividade,
      ) async {
    final dia = _diaSelecionado;
    if (dia == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Excluir atividade?'),
        content: Text(
          'Deseja excluir "${atividade.titulo}"?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _storage.deletarRoteiro(atividade.id);
      if (!mounted) return;
      setState(() { _atividades[dia]?.removeWhere((a) => a.id == atividade.id); });
    } catch (erro) { _avisarErro(erro); }
  }

  void _mostrarOpcoes() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Opções do roteiro',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.calendar_month_outlined,
                ),
                title: Text('Datas definidas na Home'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edite as datas da viagem na Home.')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                ),
                title: Text('Limpar roteiro'),
                enabled: _totalAtividades > 0,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmarLimpeza();
                },
              ),
              SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmarLimpeza() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Limpar roteiro?'),
        content: Text('Todas as atividades desta viagem serão removidas. As datas serão mantidas.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final itens = _atividades.values.expand((lista) => lista).toList();
    try {
      for (final item in itens) {
        await _storage.deletarRoteiro(item.id);
      }
      if (!mounted) return;
      setState(() {
        _atividades.clear();
        _diaSelecionado = _dias.isEmpty ? null : _dias.first;
        _ordenacao = 'Horário';
      });
    } catch (erro) {
      _avisarErro(erro);
      await _carregarRoteiro();
    }
  }
}

class _Atividade {
  final String id;
  final DateTime data;
  final String titulo;
  final String local;
  final String categoria;
  final TimeOfDay horario;

  _Atividade({
    required this.id,
    required this.data,
    required this.titulo,
    required this.local,
    required this.categoria,
    required this.horario,
  });

  factory _Atividade.fromRoteiro(Roteiro item) {
    final partes = (item.horario ?? '10:00').split(':');
    final hora = int.tryParse(partes.first) ?? 10;
    final minuto = partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0;
    return _Atividade(
      id: item.id,
      data: item.data,
      titulo: item.titulo,
      local: item.local ?? '',
      categoria: item.categoria,
      horario: TimeOfDay(hour: hora.clamp(0, 23), minute: minuto.clamp(0, 59)),
    );
  }

  Roteiro toRoteiro(String viagemId) => Roteiro(
    id: id,
    viagemId: viagemId,
    data: data,
    titulo: titulo,
    local: local.isEmpty ? null : local,
    categoria: categoria,
    horario: '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}',
  );

  int get minutos => horario.hour * 60 + horario.minute;
}

class _Indicador extends StatelessWidget {
  final String valor;
  final String titulo;
  final IconData icone;

  const _Indicador({
    required this.valor,
    required this.titulo,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icone,
          color: AppColors.primary,
          size: 23,
        ),
        SizedBox(height: 8),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
