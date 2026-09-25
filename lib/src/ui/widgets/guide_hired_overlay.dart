import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/tour_guide.dart';
import 'primary_button.dart';
import 'rating_stars.dart';
import 'remote_image.dart';

/// Aviso de "contratado" cuando el turista completa su equipo: una fila
/// por cada persona (guía y/o traductor).
///
/// Se cierra al tocar "Ir al chat" (o el fondo). El llamador debe esperar
/// el `Future` antes de navegar.
Future<void> showGuideHiredOverlay(
  BuildContext context, {
  required List<TourGuide> people,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Contratado',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _GuideHiredCard(people: people),
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

class _GuideHiredCard extends StatelessWidget {
  const _GuideHiredCard({required this.people});

  final List<TourGuide> people;

  String get _title {
    if (people.length > 1) return '¡Tu equipo está listo!';
    final firstName = people.isEmpty ? '' : people.first.name.split(' ').first;
    return '¡Contrataste a $firstName!';
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
              Text(
                _title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 16),
              for (final person in people) ...[
                _PersonRow(person: person),
                if (person != people.last) const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              Text(
                'Coordina el punto de encuentro por el chat.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Ir al chat',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person});

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
        Flexible(
          child: Column(
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
        ),
      ],
    );
  }
}
