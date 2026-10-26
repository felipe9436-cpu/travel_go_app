
import 'package:flutter/material.dart';

import '../models/avaliacao.dart';
import '../theme/app_colors.dart';

class AvaliacaoCard extends StatelessWidget {
  final Avaliacao avaliacao;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AvaliacaoCard({
    super.key,
    required this.avaliacao,
    required this.onTap,
    required this.onDelete,
  });

  IconData _iconeCategoria() {
    switch (avaliacao.categoria.toLowerCase().trim()) {
      case 'hospedagem':
      case 'hotel':
        return Icons.hotel_outlined;

      case 'restaurante':
      case 'gastronomia':
      case 'alimentação':
        return Icons.restaurant_outlined;

      case 'passeio':
      case 'atração':
      case 'atracao':
        return Icons.attractions_outlined;

      case 'transporte':
        return Icons.directions_car_outlined;

      case 'destino':
      case 'cidade':
        return Icons.location_city_outlined;

      default:
        return Icons.rate_review_outlined;
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  Widget _estrelas() {
    final nota = avaliacao.nota.clamp(0.0, 5.0).toDouble();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final preenchimento = (nota - index).clamp(0.0, 1.0);

        if (preenchimento >= 1) {
          return const Icon(
            Icons.star_rounded,
            color: AppColors.primary,
            size: 17,
          );
        }

        if (preenchimento >= 0.5) {
          return const Icon(
            Icons.star_half_rounded,
            color: AppColors.primary,
            size: 17,
          );
        }

        return const Icon(
          Icons.star_outline_rounded,
          color: AppColors.textMuted,
          size: 17,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final possuiComentario =
        avaliacao.comentario != null &&
            avaliacao.comentario!.trim().isNotEmpty;

    return Dismissible(
      key: ValueKey('avaliacao_${avaliacao.id}'),
      direction: DismissDirection.endToStart,

      // A tela decide se a avaliação será excluída.
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },

      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Excluir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),

      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho da avaliação.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 47,
                        height: 47,
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 0.11),
                          borderRadius:
                          BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary
                                .withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          _iconeCategoria(),
                          color: AppColors.primary,
                          size: 23,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              avaliacao.nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              avaliacao.categoria,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 0.10),
                          borderRadius:
                          BorderRadius.circular(11),
                        ),
                        child: Text(
                          avaliacao.nota
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Estrelas e data.
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment:
                    WrapCrossAlignment.center,
                    children: [
                      _estrelas(),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatarData(avaliacao.data),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Comentário opcional.
                  if (possuiComentario) ...[
                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated
                            .withValues(alpha: 0.65),
                        borderRadius:
                        BorderRadius.circular(13),
                        border: Border.all(
                          color: AppColors.border
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        avaliacao.comentario!,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Divider(
                    height: 1,
                    color: AppColors.borderLight
                        .withValues(alpha: 0.75),
                  ),

                  const SizedBox(height: 12),

                  // Ação principal.
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ver avaliação',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 17,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
