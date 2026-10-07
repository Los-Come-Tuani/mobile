import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/guide_access_request.dart';
import '../../../../router/routes.dart';
import '../../../guide_access/viewmodels/guide_application_viewmodel.dart';
import '../../../guide_access/widgets/credential_card.dart';
import '../../../guide_access/widgets/guide_heading.dart';
import '../../../guide_access/widgets/labeled_field.dart';
import '../../../widgets/inline_notice.dart';
import '../../../widgets/kplan_loader.dart';
import '../../../widgets/primary_button.dart';
import '../../widgets/guide_bar.dart';
import '../viewmodels/guide_renewal_viewmodel.dart';

/// Renovar un documento sin dejar de trabajar: el anterior sigue en vigor mientras el
/// equipo revisa el nuevo.
class GuideRenewalView extends StatelessWidget {
  const GuideRenewalView({super.key});

  Future<void> _pickFile(BuildContext context) async {
    final viewModel = context.read<GuideRenewalViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: GuideApplicationViewModel.allowedExtensions,
      );
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos abrir tus archivos.')),
      );
      return;
    }
    if (file == null) return;
    final size = file.lengthSync() ?? await file.length();
    final problem = GuideApplicationViewModel.fileProblem(
      name: file.name,
      sizeBytes: size,
    );
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    viewModel.attach(GuideDocument(name: file.name, uri: file.uri));
  }

  Future<DateTime?> _pickDate(BuildContext context, {required bool future}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: future ? now.add(const Duration(days: 365)) : now,
      firstDate: future ? now : DateTime(now.year - 40),
      lastDate: future ? DateTime(now.year + 30) : now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuideRenewalViewModel>();
    final type = viewModel.type;

    Future<void> submit() async {
      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      if (await viewModel.submit()) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Enviamos tu renovación: te avisamos al revisarla.'),
          ),
        );
        router.go(Routes.guideSelfProfile);
      } else if (viewModel.hasError) {
        messenger.showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage!)),
        );
      }
    }

    return Scaffold(
      appBar: const GuideBar(),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 32),
        children: [
          const GuideHeading(
            title: 'Renueva un documento',
            subtitle:
                'Sube la versión nueva. Mientras la revisamos, el anterior sigue '
                'en vigor y sigues trabajando.',
          ),
          const SizedBox(height: 24),
          if (viewModel.types.isEmpty)
            const Center(child: KPlanLoader(size: 88))
          else ...[
            LabeledField(
              label: 'Documento',
              child: DropdownButtonFormField<String>(
                initialValue: viewModel.typeCode,
                isExpanded: true,
                dropdownColor: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                items: [
                  for (final item in viewModel.types)
                    DropdownMenuItem(value: item.code, child: Text(item.label)),
                ],
                onChanged: viewModel.isBusy ? null : viewModel.setType,
              ),
            ),
            const SizedBox(height: 16),
            if (type != null)
              CredentialCard(
                key: ValueKey(type.code),
                type: type,
                file: viewModel.form.file,
                number: viewModel.form.number,
                issuedOn: viewModel.form.issuedOn,
                expiresOn: viewModel.form.expiresOn,
                problem: viewModel.problem,
                enabled: !viewModel.isBusy,
                onAttach: () => _pickFile(context),
                onRemove: viewModel.removeFile,
                onNumberChanged: viewModel.setNumber,
                onPickIssued: () async {
                  final date = await _pickDate(context, future: false);
                  if (date != null) viewModel.setIssuedOn(date);
                },
                onPickExpires: () async {
                  final date = await _pickDate(context, future: true);
                  if (date != null) viewModel.setExpiresOn(date);
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Solo el equipo de revisión verá el archivo.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),
            if (viewModel.hasError) ...[
              InlineNotice(
                tone: NoticeTone.error,
                message: viewModel.errorMessage!,
              ),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              label: 'Enviar renovación',
              isLoading: viewModel.isBusy,
              onPressed: submit,
            ),
          ],
        ],
      ),
    );
  }
}
