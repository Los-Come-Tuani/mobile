import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// Pide cuántas estrellas y un comentario para el turista [touristName] por
/// el viaje [tripLabel]. `null` si el guía cierra sin enviar.
Future<({int stars, String comment})?> showRateTouristSheet(
  BuildContext context, {
  required String touristName,
  required String tripLabel,
}) => _showRateSheet(
  context,
  touristName: touristName,
  tripLabel: tripLabel,
  texts: null,
);

/// Lo mismo para el turista que califica al guía [guideName] al terminar el
/// recorrido: su reseña se publica en el perfil del guía.
Future<({int stars, String comment})?> showRateGuideSheet(
  BuildContext context, {
  required String guideName,
  required String tripLabel,
}) {
  final l10n = context.l10n;
  return _showRateSheet(
    context,
    touristName: guideName,
    tripLabel: tripLabel,
    texts: (
      question: l10n.bookingReviewQuestion(guideName),
      commentHint: l10n.bookingReviewCommentHint,
      visibility: l10n.bookingReviewVisibility,
    ),
  );
}

typedef _RateTexts = ({String question, String commentHint, String visibility});

Future<({int stars, String comment})?> _showRateSheet(
  BuildContext context, {
  required String touristName,
  required String tripLabel,
  required _RateTexts? texts,
}) {
  return showModalBottomSheet<({int stars, String comment})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _RateTouristSheet(
      touristName: touristName,
      tripLabel: tripLabel,
      texts: texts,
    ),
  );
}

class _RateTouristSheet extends StatefulWidget {
  const _RateTouristSheet({
    required this.touristName,
    required this.tripLabel,
    required this.texts,
  });

  final String touristName;
  final String tripLabel;

  /// `null`: los textos del guía que califica a un turista.
  final _RateTexts? texts;

  @override
  State<_RateTouristSheet> createState() => _RateTouristSheetState();
}

class _RateTouristSheetState extends State<_RateTouristSheet> {
  final _comment = TextEditingController();
  int _stars = 0;
  bool _missingStars = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _send() {
    if (_stars == 0) {
      setState(() => _missingStars = true);
      return;
    }
    Navigator.of(context).pop((stars: _stars, comment: _comment.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.guideAppRateTourist(widget.touristName),
                      style: AppTextStyles.title,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.tripLabel, style: AppTextStyles.caption),
                    const SizedBox(height: 16),
                    Text(
                      widget.texts?.question ??
                          l10n.guideAppRateQuestion(widget.touristName),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (var star = 1; star <= 5; star++)
                          IconButton(
                            icon: Icon(
                              star <= _stars ? Icons.star : Icons.star_border,
                              size: 34,
                              color: AppColors.star,
                            ),
                            tooltip: l10n.guideAppRateStars(star),
                            isSelected: star <= _stars,
                            onPressed: () => setState(() {
                              _stars = star;
                              _missingStars = false;
                            }),
                          ),
                      ],
                    ),
                    if (_missingStars)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          l10n.guideAppRateMissingStars,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    AppTextField(
                      hint:
                          widget.texts?.commentHint ??
                          l10n.guideAppRateCommentHint,
                      controller: _comment,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.texts?.visibility ?? l10n.guideAppRateVisibility,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: l10n.guideAppRateSubmit,
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
