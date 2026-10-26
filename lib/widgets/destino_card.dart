import 'package:flutter/material.dart';

import '../models/destino.dart';
import '../theme/app_colors.dart';

class DestinoCard extends StatelessWidget {
  final Destino destino;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorite;

  const DestinoCard({
    super.key,
    required this.destino,
    required this.onTap,
    required this.onFavorite,
    this.isFavorite = false,
  });

  IconData _iconeCategoria() {
    switch (destino.categoria.toLowerCase().trim()) {
      case 'praia':
      case 'praias':
        return Icons.beach_access_rounded;
      case 'natureza':
      case 'aventura':
        return Icons.landscape_rounded;
      case 'gastronomia':
      case 'restaurante':
        return Icons.restaurant_rounded;
      case 'cultura':
      case 'história':
      case 'historico':
      case 'histórico':
        return Icons.account_balance_rounded;
      case 'compras':
        return Icons.shopping_bag_outlined;
      case 'entretenimento':
      case 'lazer':
        return Icons.attractions_rounded;
      case 'hospedagem':
        return Icons.hotel_rounded;
      default:
        return Icons.explore_outlined;
    }
  }

  String _localizacao() {
    final cidade = destino.cidade.trim();
    final pais = destino.pais.trim();
    if (cidade.isEmpty && pais.isEmpty) return 'Localização não informada';
    if (cidade.isEmpty) return pais;
    if (pais.isEmpty) return cidade;
    return '$cidade, $pais';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Cards em grids costumam ter altura fixa. A versão compacta
              // reduz espaçamentos e esconde detalhes secundários.
              final compacto = constraints.hasBoundedHeight &&
                  constraints.maxHeight < 265;
              final muitoCompacto = constraints.hasBoundedHeight &&
                  constraints.maxHeight < 175;
              final padding = muitoCompacto ? 10.0 : compacto ? 12.0 : 17.0;
              final tamanhoIcone = compacto ? 36.0 : 50.0;

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: tamanhoIcone,
                          height: tamanhoIcone,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(compacto ? 11 : 15),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Icon(
                            _iconeCategoria(),
                            color: AppColors.primary,
                            size: compacto ? 20 : 25,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: isFavorite
                              ? 'Remover dos favoritos'
                              : 'Adicionar aos favoritos',
                          onPressed: onFavorite,
                          constraints: BoxConstraints(
                            minWidth: compacto ? 36 : 40,
                            minHeight: compacto ? 36 : 40,
                          ),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: isFavorite
                                ? AppColors.error.withValues(alpha: 0.12)
                                : AppColors.surfaceElevated,
                            foregroundColor: isFavorite
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: compacto ? 19 : 21,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: muitoCompacto ? 6 : compacto ? 9 : 22),
                    Text(
                      destino.categoria.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: compacto ? 4 : 7),
                    Text(
                      destino.nome,
                      maxLines: compacto ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: compacto ? 16 : 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: compacto ? 5 : 11),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _localizacao(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!compacto && destino.avaliacao != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 17, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            destino.avaliacao!
                                .toStringAsFixed(1)
                                .replaceAll('.', ','),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('Avaliação',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                    if (!muitoCompacto) ...[
                      SizedBox(height: compacto ? 8 : 18),
                      Divider(
                        color: AppColors.borderLight.withValues(alpha: 0.75),
                        height: 1,
                      ),
                      SizedBox(height: compacto ? 7 : 13),
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Explorar destino',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
