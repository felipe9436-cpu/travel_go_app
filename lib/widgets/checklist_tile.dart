
import 'package:flutter/material.dart';

import '../models/checklist_item.dart';
import '../theme/app_colors.dart';

class ChecklistTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ChecklistTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  IconData _iconeCategoria(String categoria) {
    switch (categoria.toLowerCase().trim()) {
      case 'documentos':
        return Icons.badge_outlined;

      case 'reservas':
      case 'reserva':
        return Icons.confirmation_number_outlined;

      case 'mala':
      case 'bagagem':
        return Icons.luggage_outlined;

      case 'compras':
        return Icons.shopping_bag_outlined;

      case 'viagem':
      case 'transporte':
        return Icons.flight_takeoff_rounded;

      case 'saúde':
      case 'saude':
        return Icons.medical_services_outlined;

      default:
        return Icons.checklist_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final concluido = item.concluido;
    final possuiObservacao =
        item.observacao != null &&
            item.observacao!.trim().isNotEmpty;

    return Dismissible(
      key: ValueKey('checklist_${item.id}'),
      direction: DismissDirection.endToStart,

      // A tela continua responsável pela
      // confirmação e exclusão do item.
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },

      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
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
          color: concluido
              ? AppColors.surfaceElevated
              .withValues(alpha: 0.65)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: concluido
                ? AppColors.success
                .withValues(alpha: 0.22)
                : AppColors.borderLight,
          ),
          boxShadow: [
            if (!concluido)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 13,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox.
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: Checkbox(
                      value: concluido,
                      onChanged: (_) => onToggle(),
                      activeColor: AppColors.primary,
                      checkColor: AppColors.background,
                      side: BorderSide(
                        color: concluido
                            ? AppColors.primary
                            : AppColors.textMuted,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(6),
                      ),
                    ),
                  ),

                  const SizedBox(width: 9),

                  // Informações da tarefa.
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.titulo,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: concluido
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            decoration: concluido
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor:
                            AppColors.textMuted,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Categoria.
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          crossAxisAlignment:
                          WrapCrossAlignment.center,
                          children: [
                            Icon(
                              _iconeCategoria(item.categoria),
                              color: AppColors.primary,
                              size: 14,
                            ),
                            Text(
                              item.categoria,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        if (possuiObservacao) ...[
                          const SizedBox(height: 7),
                          Text(
                            item.observacao!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Indicador de status.
                  Icon(
                    concluido
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: concluido
                        ? AppColors.success
                        : AppColors.textMuted,
                    size: 19,
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
