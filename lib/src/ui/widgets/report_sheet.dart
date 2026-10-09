import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/result.dart';
import '../../data/datasources/remote/reports_api.dart';
import '../../data/datasources/repository/reports_repository.dart';
import 'app_snack_bar.dart';
import 'app_text_field.dart';
import 'kplan_loader.dart';
import 'primary_button.dart';

/// Un botón "Reportar" para la persona, reseña, lugar o evento [targetId].
class ReportButton extends StatelessWidget {
  const ReportButton({
    super.key,
    required this.target,
    required this.targetId,
    required this.label,
  });

  final ReportTarget target;
  final String targetId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: AppColors.secondaryText),
      onPressed: () =>
          showReportSheet(context, target: target, targetId: targetId),
      icon: const Icon(Icons.flag_outlined, size: 18),
      label: Text(label),
    );
  }
}

/// Pide el motivo (y la nota, si el motivo la exige) y manda el reporte al
/// equipo. Avisa cómo salió.
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final sent = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ReportSheet(target: target, targetId: targetId),
  );
  if (sent == null) return;
  messenger.showMessage(sent, tone: SnackTone.success);
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.target, required this.targetId});

  final ReportTarget target;
  final String targetId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _note = TextEditingController();
  List<ReportReason>? _reasons;
  ReportReason? _selected;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await context.read<ReportsRepository>().reasons();
      if (!mounted) return;
      setState(() {
        switch (result) {
          case Ok(:final value):
            _reasons = value;
          case Failure(:final message):
            _reasons = const [];
            _error = message;
        }
      });
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final reason = _selected;
    if (reason == null) {
      setState(() => _error = l10n.reportChooseReason);
      return;
    }
    if (reason.requiresText && _note.text.trim().isEmpty) {
      setState(() => _error = l10n.reportNoteRequired);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await context.read<ReportsRepository>().report(
      target: widget.target,
      targetId: widget.targetId,
      reason: reason.code,
      note: _note.text,
    );
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop(l10n.reportSent);
      case Failure(:final message):
        setState(() {
          _sending = false;
          _error = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reasons = _reasons;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.reportTitle, style: AppTextStyles.title),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(l10n.reportHint, style: AppTextStyles.caption),
              const SizedBox(height: 8),
              if (reasons == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: KPlanLoader()),
                )
              else
                RadioGroup<String>(
                  groupValue: _selected?.code,
                  onChanged: (code) => setState(() {
                    _selected = reasons.firstWhere((r) => r.code == code);
                    _error = null;
                  }),
                  child: Column(
                    children: [
                      for (final reason in reasons)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: reason.code,
                          title: Text(
                            reason.label,
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              AppTextField(
                hint: _selected?.requiresText ?? false
                    ? l10n.reportNoteRequiredHint
                    : l10n.reportNoteHint,
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                minLines: 2,
                maxLines: 4,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: l10n.reportSend,
                onPressed: _sending || reasons == null || reasons.isEmpty
                    ? null
                    : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
