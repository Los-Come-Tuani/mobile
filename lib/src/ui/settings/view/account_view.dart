import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../router/routes.dart';
import '../../widgets/action_row.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/soft_button.dart';
import '../widgets/logout_sheet.dart';
import '../widgets/settings_page.dart';

/// Cuenta: nombre, correo de acceso y contraseña.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  Future<void> _editName(BuildContext context, String current) async {
    final l10n = context.l10n;
    final name = await showTextInputDialog(
      context,
      title: l10n.settingsAccountNameTitle,
      hint: l10n.commonFullName,
      initialValue: current,
      confirmLabel: l10n.commonSave,
      emptyMessage: l10n.settingsAccountNameRequired,
      textCapitalization: TextCapitalization.words,
    );
    if (name == null || !context.mounted) return;
    context.read<AuthRepository>().updateName(name);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().currentUser;
    final name = user?.name ?? '';
    final l10n = context.l10n;

    return SettingsPage(
      title: l10n.settingsAccountTitle,
      children: [
        ActionRow(
          icon: Icons.person_outline,
          title: l10n.settingsAccountPersonalData,
          subtitle: name.isEmpty ? l10n.settingsAccountAddName : name,
          onTap: () => _editName(context, name),
        ),
        ActionRow(
          icon: Icons.mail_outline,
          title: l10n.settingsAccountLoginEmail,
          subtitle: user?.email ?? '',
        ),
        ActionRow(
          icon: Icons.lock_outline,
          title: l10n.settingsChangePassword,
          subtitle: l10n.settingsAccountChangePasswordSubtitle,
          onTap: () => context.push(Routes.settingsPassword),
        ),
        const SizedBox(height: 16),
        SoftButton(
          label: l10n.commonLogout,
          onPressed: () => showLogoutSheet(context),
        ),
      ],
    );
  }
}
