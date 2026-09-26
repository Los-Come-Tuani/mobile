import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../router/routes.dart';
import '../../widgets/action_row.dart';
import '../../widgets/soft_button.dart';
import '../widgets/logout_sheet.dart';
import '../widgets/settings_page.dart';

/// Cuenta: nombre, correo de acceso y contraseña.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  Future<void> _editName(BuildContext context, String current) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initialName: current),
    );
    if (name == null || !context.mounted) return;
    context.read<AuthRepository>().updateName(name);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().currentUser;
    final name = user?.name ?? '';

    return SettingsPage(
      title: 'Cuenta',
      children: [
        ActionRow(
          icon: Icons.person_outline,
          title: 'Datos personales',
          subtitle: name.isEmpty ? 'Agrega tu nombre' : name,
          onTap: () => _editName(context, name),
        ),
        ActionRow(
          icon: Icons.mail_outline,
          title: 'Correo de acceso',
          subtitle: user?.email ?? '',
        ),
        ActionRow(
          icon: Icons.lock_outline,
          title: 'Cambiar contraseña',
          subtitle: 'Solicitar un enlace de recuperación',
          onTap: () => context.push(Routes.settingsPassword),
        ),
        const SizedBox(height: 16),
        SoftButton(
          label: 'Cerrar sesión',
          onPressed: () => showLogoutSheet(context),
        ),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initialName});

  final String initialName;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text('Tu nombre', style: AppTextStyles.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Nombre completo'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
