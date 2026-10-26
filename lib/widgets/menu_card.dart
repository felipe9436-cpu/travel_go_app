import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compacto = constraints.maxWidth < 200;
              final baixo = constraints.hasBoundedHeight &&
                  constraints.maxHeight < 165;
              final muitoBaixo = constraints.hasBoundedHeight &&
                  constraints.maxHeight < 115;
              final padding = baixo ? 12.0 : 16.0;
              final iconeTamanho = muitoBaixo ? 32.0 : (baixo ? 38.0 : 48.0);

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: iconeTamanho,
                          height: iconeTamanho,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: color.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: muitoBaixo ? 18 : (baixo ? 21 : 24),
                          ),
                        ),
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: AppColors.textMuted,
                          size: compacto ? 16 : 19,
                        ),
                      ],
                    ),
                    SizedBox(height: muitoBaixo ? 5 : (baixo ? 8 : 19)),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: compacto ? 13 : 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: baixo ? 2 : 7),
                    Text(
                      subtitle,
                      maxLines: baixo ? 1 : (compacto ? 2 : 3),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: compacto ? 10 : 11,
                        height: 1.3,
                      ),
                    ),
                    if (!baixo) ...[
                      const SizedBox(height: 15),
                      Container(
                        width: 29,
                        height: 3,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
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
