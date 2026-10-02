import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/guide_job.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../../router/routes.dart';
import '../../../guide_access/widgets/labeled_field.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/inline_notice.dart';
import '../../../widgets/offer_chip.dart';
import '../../../widgets/primary_button.dart';
import '../../widgets/detail_line.dart';
import '../../widgets/guide_bar.dart';
import '../../widgets/guide_empty_state.dart';
import '../../widgets/tourist_identity.dart';
import '../viewmodels/guide_job_viewmodel.dart';

/// Una propuesta vista por el guía: qué pide, cuánto ofrece el turista y
/// cuánto le queda después del 20%, quién la publicó y cómo postularse.
class GuideJobView extends StatefulWidget {
  const GuideJobView({super.key});

  @override
  State<GuideJobView> createState() => _GuideJobViewState();
}

class _GuideJobViewState extends State<GuideJobView> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  bool _pricePrefilled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GuideJobViewModel>().load(),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<GuideJobViewModel>();
    final ok = await viewModel.apply(
      price: int.parse(_priceController.text.trim()),
      message: _messageController.text,
    );
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? l10n.guideAppJobApplicationSent
                : viewModel.errorMessage ?? l10n.commonSomethingWentWrong,
          ),
        ),
      );
  }

  String? _validatePrice(String? value) {
    final price = int.tryParse(value?.trim() ?? '');
    if (price == null || price <= 0) {
      return context.l10n.guideAppJobPriceRequired;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideJobViewModel>();
    final job = viewModel.job;

    if (!viewModel.isLoaded || job == null) {
      return Scaffold(
        appBar: GuideBar(title: l10n.guideAppJobTitle),
        body: !viewModel.isLoaded
            ? const Center(child: CircularProgressIndicator())
            : GuideEmptyState(
                icon: Icons.search_off,
                title: l10n.guideAppJobNotFoundTitle,
                message: l10n.guideAppJobNotFoundMessage,
              ),
      );
    }

    if (!_pricePrefilled) {
      _priceController.text = '${job.budget}';
      _pricePrefilled = true;
    }
    final tourist = viewModel.tourist;
    final terms = job.terms;

    return Scaffold(
      appBar: GuideBar(title: l10n.guideAppJobTitle),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 32),
        children: [
          Row(
            children: [
              OfferChip(icon: Icons.location_on_outlined, label: job.city),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  l10n.guideAppJobPublished(
                    Formatters.timeAgo(job.publishedAt),
                  ),
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(job.circuitTitle, style: AppTextStyles.formTitle),
          ),
          const SizedBox(height: 16),
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.currency(job.budget),
                  style: AppTextStyles.headline,
                ),
                Text(
                  l10n.guideAppJobTouristBudget,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.guideAppJobYouReceiveAfterFee(
                    Formatters.currency(GuidePay.earningsOf(job.budget)),
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentSecondaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DetailLine(
            icon: Icons.calendar_month_outlined,
            text:
                '${Formatters.weekdayDate(job.date)} · '
                '${Formatters.timeText(job.startTime)}',
          ),
          DetailLine(
            icon: Icons.schedule,
            text: l10n.guideAppServiceHours(terms.serviceHours),
          ),
          DetailLine(
            icon: Icons.group_outlined,
            text: Formatters.people(job.groupSize),
          ),
          DetailLine(
            icon: Icons.person_pin_circle_outlined,
            text: terms.needLabel,
          ),
          DetailLine(
            icon: Icons.directions_car_outlined,
            text: transportForGuide(terms.transportOption),
          ),
          if (terms.isMultiDay && terms.touristProvidesLodging)
            DetailLine(
              icon: Icons.hotel_outlined,
              text: l10n.guideAppJobLodging,
            ),
          const SizedBox(height: 24),
          Text(l10n.guideAppJobPostedBy, style: AppTextStyles.title),
          const SizedBox(height: 10),
          TouristTile(
            tourist: tourist,
            onTap: () => context.push(Routes.guideTouristPath(job.touristId)),
          ),
          const SizedBox(height: 28),
          ..._status(context, viewModel, job, tourist),
        ],
      ),
    );
  }

  List<Widget> _status(
    BuildContext context,
    GuideJobViewModel viewModel,
    GuideJob job,
    TouristProfile? tourist,
  ) {
    final l10n = context.l10n;
    final name = tourist?.firstName ?? l10n.guideAppTheTouristCapital;

    return switch (job.status) {
      GuideJobStatus.open => [_applyForm(viewModel, job, tourist)],
      GuideJobStatus.applied => [
        InlineNotice(
          message: l10n.guideAppJobAppliedNotice(
            Formatters.currency(job.offeredPrice ?? job.budget),
            name,
          ),
        ),
      ],
      GuideJobStatus.hired => [
        InlineNotice(
          tone: NoticeTone.success,
          message: l10n.guideAppJobHiredNotice(name),
          action: _NoticeAction(
            label: l10n.guideAppViewTrip,
            color: AppColors.accentSecondaryGreen,
            onPressed: () {
              final trip = viewModel.trip;
              if (trip != null) context.push(Routes.guideTripPath(trip.id));
            },
          ),
        ),
      ],
      GuideJobStatus.taken => [
        InlineNotice(
          message: l10n.guideAppJobTakenNotice(name),
          action: _NoticeAction(
            label: l10n.guideAppSeeProposals,
            color: AppColors.primaryText,
            onPressed: () => context.go(Routes.guideHome),
          ),
        ),
      ],
    };
  }

  Widget _applyForm(
    GuideJobViewModel viewModel,
    GuideJob job,
    TouristProfile? tourist,
  ) {
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.guideAppJobApplicationTitle,
              style: AppTextStyles.title,
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: l10n.guideAppJobPriceLabel,
            child: AppTextField(
              hint: '${job.budget}',
              helper: l10n.guideAppJobPriceHelper(
                Formatters.currency(job.budget),
              ),
              controller: _priceController,
              validator: _validatePrice,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              enabled: !viewModel.isBusy,
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _priceController,
            builder: (context, _) {
              final price = int.tryParse(_priceController.text.trim()) ?? 0;
              return Text(
                price > 0
                    ? l10n.guideAppJobWouldReceive(
                        Formatters.currency(GuidePay.earningsOf(price)),
                      )
                    : ' ',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accentSecondaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: l10n.guideAppJobMessageLabel(
              tourist?.firstName ?? l10n.guideAppTheTourist,
            ),
            child: AppTextField(
              hint: l10n.guideAppJobMessageHint,
              controller: _messageController,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 5,
              enabled: !viewModel.isBusy,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: l10n.guideAppJobApply,
            isLoading: viewModel.isBusy,
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}

class _NoticeAction extends StatelessWidget {
  const _NoticeAction({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(label, style: AppTextStyles.link.copyWith(color: color)),
      ),
    );
  }
}
