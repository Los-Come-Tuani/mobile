import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/guide_access_request.dart';
import '../../../../router/routes.dart';
import '../../../guide_access/widgets/guide_heading.dart';
import '../../../guide_access/widgets/labeled_field.dart';
import '../../../widgets/app_choice_chip.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/inline_notice.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../widgets/guide_bar.dart';
import '../viewmodels/guide_profile_edit_viewmodel.dart';

/// Editar el perfil público: lo que ve el turista. Se ve de inmediato, sin revisión.
class GuideProfileEditView extends StatefulWidget {
  const GuideProfileEditView({super.key});

  @override
  State<GuideProfileEditView> createState() => _GuideProfileEditViewState();
}

class _GuideProfileEditViewState extends State<GuideProfileEditView> {
  late final GuideProfileEditViewModel _viewModel = context
      .read<GuideProfileEditViewModel>();
  late final TextEditingController _presentation = TextEditingController(
    text: _viewModel.presentation,
  )..addListener(() => _viewModel.presentation = _presentation.text);
  late final TextEditingController _phone = TextEditingController(
    text: _viewModel.phone,
  )..addListener(() => _viewModel.phone = _phone.text);

  @override
  void dispose() {
    _presentation.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: GuideProfileEditViewModel.photoExtensions,
      );
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos abrir tus fotos.')),
      );
      return;
    }
    if (file == null) return;
    final size = file.lengthSync() ?? await file.length();
    final problem = GuideProfileEditViewModel.photoProblem(
      name: file.name,
      sizeBytes: size,
    );
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    _viewModel.setPhoto(GuideDocument(name: file.name, uri: file.uri));
  }

  Future<void> _save() async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (await _viewModel.save()) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Guardamos tu perfil.')),
      );
      router.go(Routes.guideSelfProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuideProfileEditViewModel>();
    final photo = viewModel.photo;
    final photoUrl = viewModel.currentPhotoUrl;

    return Scaffold(
      appBar: const GuideBar(),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 32),
        children: [
          const GuideHeading(
            title: 'Tu perfil público',
            subtitle:
                'Lo que ve el turista al buscarte. Los cambios se ven de inmediato.',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: photo == null && photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photo != null
                    ? const Icon(Icons.check)
                    : photoUrl == null
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SecondaryButton(
                  label: photo == null ? 'Cambiar la foto' : photo.name,
                  onPressed: viewModel.isBusy ? null : _pickPhoto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LabeledField(
            label: 'Preséntate a los turistas',
            child: AppTextField(
              hint: 'Ej.: 3 años en recorridos de historia colonial',
              controller: _presentation,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              enabled: !viewModel.isBusy,
              minLines: 3,
              maxLines: 6,
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Teléfono de contacto',
            child: AppTextField(
              hint: '+505 8888 0000',
              controller: _phone,
              keyboardType: TextInputType.phone,
              enabled: !viewModel.isBusy,
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Idiomas',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final language in viewModel.languageOptions)
                  AppChoiceChip(
                    label: language.label,
                    selected: viewModel.isSelected(language.code),
                    onSelected: () => viewModel.toggleLanguage(language.code),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lo que ofreces y dónde trabajas no se cambian aquí: son parte de lo '
            'que revisamos.',
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
            label: 'Guardar',
            isLoading: viewModel.isBusy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
