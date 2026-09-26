import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    if (_sent) {
      final isDemo = context.read<SupportRepository>().isDemo;
      return SettingsPage(
        title: 'Consulta enviada',
        children: [
          DonePanel(
            icon: Icons.chat_bubble_outline,
            title: 'Tu consulta está lista',
            message: 'El equipo de soporte te responderá a $_email.',
            note: isDemo
                ? 'Demostración: por ahora el mensaje no sale de tu teléfono.'
                : null,
            actionLabel: 'Volver a Ayuda',
            onAction: context.pop,
          ),
        ],
      );
    }

    return SettingsPage(
      title: 'Contactar soporte',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Asunto', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              AppTextField(
                hint: 'Ej. Consulta sobre mi reserva',
                controller: _subjectController,
                textInputAction: TextInputAction.next,
                enabled: !_isSending,
                validator: (value) =>
                    _required(value, 'Cuéntanos de qué se trata'),
              ),
              const SizedBox(height: 16),
              Text('Mensaje', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              AppTextField(
                hint: 'Qué pasó, en qué circuito y cuándo',
                controller: _messageController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 4,
                maxLines: 8,
                enabled: !_isSending,
                validator: (value) => _required(value, 'Escribe tu mensaje'),
              ),
              const SizedBox(height: 12),
              Text('Te responderemos a $_email.', style: AppTextStyles.caption),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Enviar consulta',
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
