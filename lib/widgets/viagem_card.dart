
import 'package:flutter/material.dart';

import '../models/viagem.dart';
import '../theme/app_colors.dart';

class ViagemCard extends StatelessWidget {
  final Viagem viagem;
  final VoidCallback? onTap;

  const ViagemCard({
    super.key,
    required this.viagem,
    this.onTap,
  });

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  String _formatarMoeda(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];

    final buffer = StringBuffer();

    for (int i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(inteiro[i]);
    }

    return 'R\$ ${buffer.toString()},${partes[1]}';
  }

  String _statusViagem() {
    final agora = DateTime.now();

    final hoje = DateTime(
      agora.year,
      agora.month,
      agora.day,
    );

    final inicio = DateTime(
      viagem.dataInicio.year,
      viagem.dataInicio.month,
      viagem.dataInicio.day,
    );

    final fim = DateTime(
      viagem.dataFim.year,
      viagem.dataFim.month,
      viagem.dataFim.day,
    );

    if (hoje.isBefore(inicio)) {
      return 'PRÓXIMA VIAGEM';
    }

    if (hoje.isAfter(fim)) {
      return 'VIAGEM FINALIZADA';
    }

    return 'VIAGEM EM ANDAMENTO';
  }

  IconData _iconeStatus() {
    final status = _statusViagem();

    if (status == 'VIAGEM FINALIZADA') {
      return Icons.check_circle_outline_rounded;
    }

    if (status == 'VIAGEM EM ANDAMENTO') {
      return Icons.explore_rounded;
    }

    return Icons.flight_takeoff_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusViagem();

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do card.
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary
                              .withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.luggage_rounded,
                        color: AppColors.primary,
                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viagem.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Sua experiência de viagem',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (onTap != null)
                      const Icon(
                        Icons.arrow_outward_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                  ],
                ),

                const SizedBox(height: 25),

                // Status da viagem.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.primary
                          .withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconeStatus(),
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Destino principal.
                Text(
                  viagem.destino,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 29,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.date_range_outlined,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatarData(viagem.dataInicio)}'
                            ' — '
                            '${_formatarData(viagem.dataFim)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 23),

                Divider(
                  color: AppColors.borderLight
                      .withValues(alpha: 0.75),
                  height: 1,
                ),

                const SizedBox(height: 18),

                // Informações da viagem.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compacto = constraints.maxWidth < 330;

                    final indicadores = [
                      _BadgeInfo(
                        icon: Icons.calendar_month_outlined,
                        label: 'DURAÇÃO',
                        value:
                        '${viagem.duracaoEmDias} '
                            '${viagem.duracaoEmDias == 1 ? 'dia' : 'dias'}',
                      ),
                      _BadgeInfo(
                        icon: Icons.people_outline_rounded,
                        label: 'VIAJANTES',
                        value:
                        '${viagem.numeroViajantes} '
                            '${viagem.numeroViajantes == 1 ? 'pessoa' : 'pessoas'}',
                      ),
                      _BadgeInfo(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'ORÇAMENTO',
                        value: _formatarMoeda(viagem.orcamento),
                      ),
                    ];

                    if (compacto) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: indicadores[0]),
                              const SizedBox(width: 10),
                              Expanded(child: indicadores[1]),
                            ],
                          ),
                          const SizedBox(height: 10),
                          indicadores[2],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: indicadores[0]),
                        const SizedBox(width: 10),
                        Expanded(child: indicadores[1]),
                        const SizedBox(width: 10),
                        Expanded(child: indicadores[2]),
                      ],
                    );
                  },
                ),

                if (onTap != null) ...[
                  const SizedBox(height: 19),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Ver detalhes da viagem',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BadgeInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.background
            .withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.borderLight
              .withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
