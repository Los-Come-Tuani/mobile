import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Tarjeta blanca con borde que agrupa los bloques de la pantalla de agendar.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Fila editable de "Detalles de la reserva": icono, etiqueta, valor y chevron.
class BookingFieldRow extends StatelessWidget {
  const BookingFieldRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary30),
                const SizedBox(width: 12),
                Text(label, style: AppTextStyles.body),
                const Spacer(),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 14,
            endIndent: 14,
            color: AppColors.divider,
          ),
      ],
    );
  }
}

/// Bloque informativo del recorrido: icono + título en color de marca y texto.
class TourInfoBlock extends StatelessWidget {
  const TourInfoBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.infoLabel),
                  const SizedBox(height: 2),
                  Text(text, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.secondaryText,
              ),
          ],
        ),
      ),
    );
  }
}
