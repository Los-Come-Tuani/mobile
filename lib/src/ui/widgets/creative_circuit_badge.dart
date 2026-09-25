import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/circuit.dart';

/// Distintivo de circuito creativo, para las tarjetas y el encabezado del
/// detalle.
class CreativeCircuitBadge extends StatelessWidget {
  const CreativeCircuitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.creativeCircuit,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance,
            size: 13,
            color: AppColors.onCreativeCircuit,
          ),
          const SizedBox(width: 4),
          Text(
            'Circuito creativo',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onCreativeCircuit,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Explica en el detalle qué tiene de especial un circuito creativo: quién
/// lo creó, cómo se hace (en grupo) y lo que da de más al completarlo.
class CreativeCircuitBanner extends StatelessWidget {
  const CreativeCircuitBanner({super.key, required this.circuit});

  final Circuit circuit;

  @override
  Widget build(BuildContext context) {
    final organizer = circuit.organizer.isEmpty
        ? 'una alcaldía'
        : 'la ${circuit.organizer}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.creativeCircuit.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.creativeCircuit),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.creativeCircuit,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance,
              size: 20,
              color: AppColors.onCreativeCircuit,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Circuito creativo oficial', style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(
                  'Lo creó $organizer. Se hace en grupo: te inscribes en un '
                  'horario publicado por un guía certificado.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _RewardPill(
                      icon: Icons.military_tech,
                      label: '+${Circuit.creativeBonusBadges} insignias extra',
                    ),
                    _RewardPill(
                      icon: Icons.workspace_premium,
                      label: 'Medalla de ${circuit.city}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.creativeCircuit),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.creativeCircuit),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
