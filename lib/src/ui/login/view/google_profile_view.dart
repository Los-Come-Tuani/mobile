import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/nationality.dart';
import '../../../data/models/user_role.dart';
import '../../../router/routes.dart';
import '../../guide_access/widgets/labeled_field.dart';
import '../../register/widgets/birth_date_sheet.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/nationality_sheet.dart';
import '../../widgets/picker_field.dart';
import '../../widgets/primary_button.dart';
import '../viewmodels/google_profile_viewmodel.dart';
import '../viewmodels/two_factor_login_viewmodel.dart';

/// "Completa tu perfil": la primera vez que alguien entra con Google, la cuenta nueva
/// necesita la fecha de nacimiento (mayores de 18 años) y la nacionalidad, que Google no
/// entrega.
class GoogleProfileView extends StatelessWidget {
  const GoogleProfileView({super.key, this.role = UserRole.tourist});

  final UserRole role;

  static String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _pickBirthDate(BuildContext context) async {
    final viewModel = context.read<GoogleProfileViewModel>();
    final date = await showBirthDateSheet(
      context,
      initialDate: viewModel.birthDate,
    );
    if (date != null) viewModel.setBirthDate(date);
  }

  Future<void> _pickNationality(BuildContext context) async {
    final viewModel = context.read<GoogleProfileViewModel>();
    final picked = await showNationalitySheet(
      context,
      selectedCode: viewModel.nationality,
    );
    if (picked != null) viewModel.setNationality(picked.code);
  }

  Future<void> _submit(BuildContext context) async {
    final viewModel = context.read<GoogleProfileViewModel>();
    final result = await viewModel.submit();
    if (!context.mounted) return;

    switch (result) {
      case GoogleProfileResult.success:
        context.go(role == UserRole.guide ? Routes.guideAccess : Routes.home);
      case GoogleProfileResult.twoFactor:
        context.push(
          Routes.loginTwoFactor,
          extra: TwoFactorLoginArgs(
            challenge: viewModel.challenge!,
            role: role,
          ),
        );
      case GoogleProfileResult.failed:
        ScaffoldMessenger.of(context).showMessage(
          viewModel.errorMessage ?? context.l10n.commonSomethingWentWrong,
          tone: SnackTone.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GoogleProfileViewModel>();
    final nationality = Nationality.byCode(viewModel.nationality);
    final birthDate = viewModel.birthDate;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.commonBack,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(l10n.loginGoogleProfileTitle, style: AppTextStyles.headline),
              const SizedBox(height: 8),
              Text(
                l10n.loginGoogleProfileSubtitle,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 24),
              LabeledField(
                label: l10n.commonBirthDate,
                child: PickerField(
                  text: birthDate == null ? null : _format(birthDate),
                  hint: '00/00/0000',
                  icon: Icons.calendar_month_outlined,
                  enabled: !viewModel.isBusy,
                  onTap: () => _pickBirthDate(context),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: l10n.commonNationality,
                child: PickerField(
                  text: nationality?.name,
                  hint: l10n.commonChooseCountry,
                  enabled: !viewModel.isBusy,
                  onTap: () => _pickNationality(context),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: l10n.commonContinue,
                isLoading: viewModel.isBusy,
                onPressed: viewModel.isComplete ? () => _submit(context) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
