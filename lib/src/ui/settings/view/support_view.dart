import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/support_repository.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../widgets/done_panel.dart';
import '../widgets/settings_page.dart';

/// Escribirle al equipo de soporte.
class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String get _email => context.read<AuthRepository>().currentUser?.email ?? '';

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);
    final result = await context.read<SupportRepository>().send(
      email: _email,
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSending = false);

    switch (result) {
      case Ok():
        setState(() => _sent = true);
      case Failure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_sent) {
      final isDemo = context.read<SupportRepository>().isDemo;
      return SettingsPage(
        title: l10n.settingsSupportSentTitle,
        children: [
          DonePanel(
            icon: Icons.chat_bubble_outline,
            title: l10n.settingsSupportSentPanelTitle,
            message: l10n.settingsSupportSentMessage(_email),
            note: isDemo ? l10n.settingsSupportDemoNote : null,
            actionLabel: l10n.settingsSupportBackToHelp,
            onAction: context.pop,
          ),
        ],
      );
    }

    return SettingsPage(
      title: l10n.settingsContactSupport,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settingsSupportSubject, style: AppTextStyles.caption),
              const SizedBox(height: 6),
              AppTextField(
                hint: l10n.settingsSupportSubjectHint,
                controller: _subjectController,
                textInputAction: TextInputAction.next,
                enabled: !_isSending,
                validator: (value) =>
                    _required(value, l10n.settingsSupportSubjectRequired),
              ),
              const SizedBox(height: 16),
              Text(l10n.settingsSupportMessage, style: AppTextStyles.caption),
              const SizedBox(height: 6),
              AppTextField(
                hint: l10n.settingsSupportMessageHint,
                controller: _messageController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 4,
                maxLines: 8,
                enabled: !_isSending,
                validator: (value) =>
                    _required(value, l10n.settingsSupportMessageRequired),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.settingsSupportReplyTo(_email),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.settingsSupportSend,
                isLoading: _isSending,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
