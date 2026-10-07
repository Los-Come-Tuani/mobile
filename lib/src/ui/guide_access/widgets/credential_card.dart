import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/guide_access_request.dart';
import '../../../data/models/provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/picker_field.dart';
import 'document_slot.dart';
import 'labeled_field.dart';

/// Un documento que se pide: el archivo, su número y sus fechas. Si el equipo lo
/// rechazó antes, dice por qué.
class CredentialCard extends StatefulWidget {
  const CredentialCard({
    super.key,
    required this.type,
    required this.file,
    required this.number,
    required this.issuedOn,
    required this.expiresOn,
    required this.onAttach,
    required this.onRemove,
    required this.onNumberChanged,
    required this.onPickIssued,
    required this.onPickExpires,
    this.rejected,
    this.problem,
    this.enabled = true,
  });

  final CredentialType type;
  final GuideDocument? file;
  final String number;
  final DateTime? issuedOn;
  final DateTime? expiresOn;
  final VoidCallback onAttach;
  final VoidCallback onRemove;
  final ValueChanged<String> onNumberChanged;
  final VoidCallback onPickIssued;
  final VoidCallback onPickExpires;

  /// Lo que se rechazó antes, para corregirlo sin adivinar.
  final ProviderDocument? rejected;

  /// Lo que falta o está mal; nulo si está completo.
  final String? problem;
  final bool enabled;

  static String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  State<CredentialCard> createState() => _CredentialCardState();
}

class _CredentialCardState extends State<CredentialCard> {
  late final _number = TextEditingController(text: widget.number);

  @override
  void initState() {
    super.initState();
    _number.addListener(() => widget.onNumberChanged(_number.text));
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    final type = widget.type;
    final file = widget.file;
    final issuedOn = widget.issuedOn;
    final expiresOn = widget.expiresOn;
    final problem = widget.problem;
    final enabled = widget.enabled;
    final rejected = widget.rejected;
    final review = rejected?.review;
    final formatDate = CredentialCard.formatDate;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentSlot(
          title: type.label,
          description: rejected == null
              ? null
              : l10n.guideAccessDocumentRejectedByUs(
                      review?.reason ?? l10n.guideAccessDocumentCouldNotAccept,
                    ) +
                    ((review?.note ?? '').isEmpty ? '' : '. ${review!.note}'),
          files: [?file],
          canAttach: file == null,
          hasError: problem != null,
          enabled: enabled,
          onAttach: widget.onAttach,
          onRemove: (_) => widget.onRemove(),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: l10n.guideAccessDocumentNumber,
          child: AppTextField(
            hint: l10n.guideAccessDocumentNumberHint,
            controller: _number,
            enabled: enabled,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledField(
                label: l10n.guideAccessDocumentIssuedOn,
                child: PickerField(
                  text: issuedOn == null ? null : formatDate(issuedOn),
                  hint: '00/00/0000',
                  icon: Icons.calendar_month_outlined,
                  enabled: enabled,
                  onTap: widget.onPickIssued,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledField(
                label: type.requiresExpiry
                    ? l10n.guideAccessDocumentExpiresOn
                    : l10n.guideAccessDocumentExpiresOnOptional,
                child: PickerField(
                  text: expiresOn == null ? null : formatDate(expiresOn),
                  hint: type.requiresExpiry
                      ? '00/00/0000'
                      : l10n.guideAccessDocumentNoExpiry,
                  icon: Icons.event_outlined,
                  enabled: enabled,
                  onTap: widget.onPickExpires,
                ),
              ),
            ),
          ],
        ),
        if (problem != null) ...[
          const SizedBox(height: 8),
          Text(
            problem,
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

/// Un documento que el equipo ya aceptó: pasa tal cual a la solicitud nueva.
class KeptCredential extends StatelessWidget {
  const KeptCredential({super.key, required this.document});

  final ProviderDocument document;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.verified_outlined,
              color: AppColors.accentSecondaryGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.typeLabel, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      document.review?.accepted == true
                          ? context.l10n.guideAccessDocumentKeptAccepted
                          : context.l10n.guideAccessDocumentKept,
                      style: AppTextStyles.caption,
                    ),
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
