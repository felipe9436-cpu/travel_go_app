
import 'package:flutter/material.dart';

import '../models/gasto.dart';
import '../theme/app_colors.dart';

class GastoCard extends StatelessWidget {
  final Gasto gasto;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GastoCard({
    super.key,
    required this.gasto,
    required this.onTap,
    required this.onDelete,
  });

  String _formatarMoeda(double valor) {
    final negativo = valor < 0;
    final partes = valor.abs().toStringAsFixed(2).split('.');
    final inteiro = partes[0];

    final buffer = StringBuffer();

    for (int i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(inteiro[i]);
    }

    final sinal = negativo ? '-' : '';

    return '${sinal}R\$ ${buffer.toString()},${partes[1]}';
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  IconData _iconeCategoria(String categoria) {
    switch (categoria.toLowerCase().trim()) {
      case 'hospedagem':
        return Icons.hotel_outlined;

      case 'alimentação':
      case 'alimentacao':
        return Icons.restaurant_outlined;

      case 'passeio':
      case 'passeios':
      case 'lazer':
        return Icons.local_activity_outlined;

      case 'transporte':
        return Icons.directions_car_outlined;

      case 'compras':
        return Icons.shopping_bag_outlined;

      case 'passagem':
      case 'passagens':
        return Icons.flight_outlined;

      case 'outros':
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _corCategoria(String categoria) {
    switch (categoria.toLowerCase().trim()) {
      case 'hospedagem':
        return AppColors.blue;

      case 'alimentação':
      case 'alimentacao':
        return AppColors.success;

      case 'passeio':
      case 'passeios':
      case 'lazer':
        return AppColors.primary;

      case 'transporte':
        return const Color(0xFFB39DDB);

      case 'compras':
        return AppColors.cyan;

      case 'passagem':
      case 'passagens':
        return AppColors.warning;

      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corCategoria(gasto.categoria);
    final icone = _iconeCategoria(gasto.categoria);

    return Dismissible(
      key: ValueKey('gasto_${gasto.id}'),
      direction: DismissDirection.endToStart,

      // Solicita a exclusão, mas deixa a tela
      // responsável pela confirmação e remoção.
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
                fontWeight: FontWeight.w700,
                fontSize: 12,
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderLight,
          ),
          boxShadow: [
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
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compacto = constraints.maxWidth < 310;

                  if (compacto) {
                    return _conteudoCompacto(
                      cor: cor,
                      icone: icone,
                    );
                  }

                  return _conteudoHorizontal(
                    cor: cor,
                    icone: icone,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconeGasto({
    required Color cor,
    required IconData icone,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: cor.withValues(alpha: 0.18),
        ),
      ),
      child: Icon(
        icone,
        color: cor,
        size: 24,
      ),
    );
  }

  Widget _informacoesGasto(Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          gasto.descricao,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 7,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              gasto.categoria,
              style: TextStyle(
                color: cor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              '•',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            Text(
              _formatarData(gasto.data),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),

        if (gasto.observacao != null &&
            gasto.observacao!.trim().isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            gasto.observacao!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _conteudoHorizontal({
    required Color cor,
    required IconData icone,
  }) {
    return Row(
      children: [
        _iconeGasto(cor: cor, icone: icone),

        const SizedBox(width: 13),

        Expanded(
          child: _informacoesGasto(cor),
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatarMoeda(gasto.valor),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 19,
            ),
          ],
        ),
      ],
    );
  }

  Widget _conteudoCompacto({
    required Color cor,
    required IconData icone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconeGasto(cor: cor, icone: icone),
            const SizedBox(width: 12),
            Expanded(
              child: _informacoesGasto(cor),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Divider(
          height: 1,
          color: AppColors.borderLight
              .withValues(alpha: 0.75),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Valor registrado',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Flexible(
              child: Text(
                _formatarMoeda(gasto.valor),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
