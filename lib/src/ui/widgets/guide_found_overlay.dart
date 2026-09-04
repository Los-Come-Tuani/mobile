import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/tour_guide.dart';
import 'primary_button.dart';
import 'rating_stars.dart';
import 'remote_image.dart';

/// Alerta de "encontrado" al emparejar una solicitud en vivo: una tarjeta
/// por cada persona (guía y/o traductor).
///
/// Se cierra al tocar "Ver perfil" (o el fondo). El llamador debe esperar
/// el `Future` antes de navegar.
Future<void> showGuideFoundOverlay(
  BuildContext context, {
  required List<TourGuide> participants,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Encontrado',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _GuideFoundCard(participants: participants),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scale = CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      );
      return Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class _GuideFoundCard extends StatelessWidget {
  const _GuideFoundCard({required this.participants});

  final List<TourGuide> participants;

  String get _title {
    if (participants.length < 2) return '¡Encontrado!';
    return '¡Encontramos a los dos!';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radius * 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_title, style: AppTextStyles.headline),
              const SizedBox(height: 16),
              for (final person in participants) ...[
                _ParticipantRow(person: person),
                if (person != participants.last) const SizedBox(height: 12),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Ver perfil',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.person});

  final TourGuide person;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: RemoteImage(url: person.photoUrl, height: 56, width: 56),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(person.name, style: AppTextStyles.title),
            const SizedBox(height: 2),
            RatingStars(
              rating: person.rating,
              reviewsCount: person.reviewsCount,
              starSize: 13,
            ),
          ],
        ),
      ],
    );
  }
}
