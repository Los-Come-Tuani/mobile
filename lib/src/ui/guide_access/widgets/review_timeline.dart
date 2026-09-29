import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_access_request.dart';

/// Los pasos de la revisión de una solicitud de guía: cuáles terminaron y
/// cuándo, cuál se revisa ahora y qué falta. Se pinta como la línea de un
/// viaje en curso: verde lo listo, terracota lo de ahora.
class ReviewTimeline extends StatelessWidget {
  const ReviewTimeline({super.key, required this.review, this.contactEmail});

  final GuideReview review;

  /// A donde llega el resultado; se nombra en el último paso.
  final String? contactEmail;

  @override
  Widget build(BuildContext context) {
    const steps = GuideReviewStep.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final step in steps)
          _StepRow(
            number: step.index + 1,
            total: steps.length,
            title: _titleOf(step),
            detail: _detailOf(step),
            finishedAt: review.finishedAt(step),
            isCurrent: step == review.current,
            isLast: step == steps.last,
          ),
      ],
    );
  }

  static String _titleOf(GuideReviewStep step) => switch (step) {
    GuideReviewStep.submitted => 'Solicitud enviada',
    GuideReviewStep.documents => 'Revisión de documentos',
    GuideReviewStep.experience => 'Revisión de experiencia',
    GuideReviewStep.decision => 'Decisión final',
  };

  String? _detailOf(GuideReviewStep step) => switch (step) {
    GuideReviewStep.submitted => null,
    GuideReviewStep.documents => 'Documento de identidad y credencial INTUR',
    GuideReviewStep.experience => 'Cobertura, idiomas y trayectoria',
    GuideReviewStep.decision =>
      contactEmail == null
          ? 'Te escribiremos el resultado por correo'
          : 'Te escribiremos el resultado a $contactEmail',
  };
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.total,
    required this.title,
    required this.detail,
    required this.finishedAt,
    required this.isCurrent,
    required this.isLast,
  });

  final int number;
  final int total;
  final String title;
  final String? detail;
  final DateTime? finishedAt;
  final bool isCurrent;
  final bool isLast;

  bool get _isDone => finishedAt != null;

  /// "Listo · 6:20 p.m." (con el día si no fue hoy) o "Revisando ahora".
  String? get _status {
    final finishedAt = this.finishedAt;
    if (finishedAt == null) return isCurrent ? 'Revisando ahora' : null;
    return Formatters.facts([
      'Listo',
      if (!DateUtils.isSameDay(finishedAt, DateTime.now()))
        Formatters.relativeDay(finishedAt),
      Formatters.clock(finishedAt),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    final status = _status;
    final isStarted = _isDone || isCurrent;

    return Semantics(
      label: [
        'Paso $number de $total',
        title,
        ?detail,
        status ?? 'Pendiente',
      ].join('. '),
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _Marker(number: number, isDone: _isDone, isCurrent: isCurrent),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _isDone
                          ? AppColors.accentSecondaryGreen
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isStarted
                            ? AppColors.primaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: AppTextStyles.bodySmall.copyWith(
                          height: 20 / 14,
                        ),
                      ),
                    ],
                    if (status != null) ...[
                      const SizedBox(height: 6),
                      _Status(text: status, isDone: _isDone),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Check verde si el paso terminó; si no, su número: en terracota el que se
/// revisa ahora y vacío lo que falta.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.number,
    required this.isDone,
    required this.isCurrent,
  });

  final int number;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = !isDone && !isCurrent;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? AppColors.accentSecondaryGreen
            : isCurrent
            ? AppColors.primary30
            : AppColors.fieldFill,
        border: isUpcoming
            ? Border.all(color: AppColors.outline, width: 1.5)
            : null,
      ),
      child: isDone
          ? const Icon(Icons.check, size: 16, color: AppColors.white)
          // El número no puede crecer más que el círculo que lo contiene.
          : MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Text(
                '$number',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? AppColors.white : AppColors.secondaryText,
                ),
              ),
            ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.text, required this.isDone});

  final String text;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isDone) ...[
          const Icon(
            Icons.hourglass_top_rounded,
            size: 14,
            color: AppColors.primary30,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isDone
                  ? AppColors.accentSecondaryGreen
                  : AppColors.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}
