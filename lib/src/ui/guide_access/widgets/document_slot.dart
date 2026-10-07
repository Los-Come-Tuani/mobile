import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/guide_access_request.dart';

/// Tarjeta de un documento de la postulación: qué se pide, lo que ya se
/// adjuntó y cómo adjuntar.
class DocumentSlot extends StatelessWidget {
  const DocumentSlot({
    super.key,
    required this.title,
    required this.files,
    required this.onAttach,
    required this.onRemove,
    this.description,
    this.attachLabel,
    this.canAttach = true,
    this.hasError = false,
    this.enabled = true,
  });

  final String title;
  final List<GuideDocument> files;
  final VoidCallback onAttach;
  final ValueChanged<GuideDocument> onRemove;

  /// Qué debe mostrar el documento para que lo acepten.
  final String? description;

  /// Lo que dice la acción de adjuntar; si es `null`, "Adjuntar archivo".
  final String? attachLabel;

  /// `false` cuando ya no caben más archivos: un documento lleva uno solo.
  final bool canAttach;

  /// Resalta la tarjeta cuando falta su archivo.
  final bool hasError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: hasError
            ? const BorderSide(color: AppColors.error, width: 1.5)
            : const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(description!, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            for (final file in files)
              _AttachedFile(
                file: file,
                onRemove: enabled ? () => onRemove(file) : null,
              ),
            if (canAttach)
              _AttachAction(
                label: attachLabel ?? l10n.guideAccessAttachFile,
                onTap: enabled ? onAttach : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _AttachedFile extends StatelessWidget {
  const _AttachedFile({required this.file, required this.onRemove});

  final GuideDocument file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 24,
            color: AppColors.accentSecondaryGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.fieldLabel,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.guideAccessDocumentAttached,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.guideAccessRemoveFile(file.name),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AttachAction extends StatelessWidget {
  const _AttachAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final formats = context.l10n.guideAccessFileFormats;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$label. $formats',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius - 2),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.add, size: 24, color: AppColors.primary30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.link),
                    const SizedBox(height: 2),
                    Text(formats, style: AppTextStyles.caption),
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
