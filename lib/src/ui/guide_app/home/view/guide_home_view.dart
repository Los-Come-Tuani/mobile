import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../../router/routes.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/inline_notice.dart';
import '../../widgets/coverage_chip.dart';
import '../../widgets/date_badge.dart';
import '../../widgets/guide_bar.dart';
import '../../widgets/guide_bottom_nav.dart';
import '../../widgets/job_row.dart';
import '../viewmodels/guide_home_viewmodel.dart';

/// Inicio del guía: lo del momento primero (saldo y próximo viaje) y, como
/// contenido principal, las propuestas que puede tomar.
class GuideHomeView extends StatefulWidget {
  const GuideHomeView({super.key});

  @override
  State<GuideHomeView> createState() => _GuideHomeViewState();
}

class _GuideHomeViewState extends State<GuideHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GuideHomeViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideHomeViewModel>();
    final newHire = viewModel.newHire;
    final nextTrip = viewModel.nextTrip;

    return Scaffold(
      appBar: const GuideBar(),
      bottomNavigationBar: const GuideBottomNav(),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 32),
        children: [
          if (newHire != null) ...[
            _HireNotice(
              trip: newHire,
              tourist: viewModel.touristOf(newHire.touristId),
              onOpen: () {
                viewModel.dismissNewHire();
                context.push(Routes.guideTripPath(newHire.id));
              },
            ),
            const SizedBox(height: 20),
          ],
          Semantics(
            header: true,
            child: Text(
              l10n.guideAppHomeGreeting(viewModel.firstName),
              style: AppTextStyles.formTitle,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: CoverageChip(label: viewModel.coverageLabel),
          ),
          const SizedBox(height: 12),
          _BalanceLine(
            available: viewModel.available,
            pending: viewModel.pending,
            onTap: () => context.push(Routes.guideBalance),
          ),
          if (nextTrip != null) ...[
            const SizedBox(height: 24),
            Text(l10n.guideAppHomeNextTrip, style: AppTextStyles.title),
            const SizedBox(height: 10),
            _NextTrip(
              trip: nextTrip,
              tourist: viewModel.touristOf(nextTrip.touristId),
              onTap: () => context.push(Routes.guideTripPath(nextTrip.id)),
            ),
          ],
          const SizedBox(height: 28),
          Semantics(
            header: true,
            child: Text(l10n.guideAppHomeProposals, style: AppTextStyles.title),
          ),
          const SizedBox(height: 2),
          Text(
            viewModel.isLocal
                ? l10n.guideAppHomeProposalsLocal(viewModel.city ?? '')
                : l10n.guideAppHomeProposalsNational,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          ..._jobs(context, viewModel),
        ],
      ),
    );
  }

  List<Widget> _jobs(BuildContext context, GuideHomeViewModel viewModel) {
    if (!viewModel.isLoaded) return const [_JobsSkeleton()];

    final jobs = viewModel.jobs;
    if (jobs.isEmpty) {
      final l10n = context.l10n;
      return [
        EmptyState(
          compact: true,
          title: viewModel.isLocal
              ? l10n.guideAppHomeEmptyLocal(viewModel.city ?? '')
              : l10n.guideAppHomeEmptyNational,
          message: l10n.guideAppHomeEmptyMessage,
        ),
      ];
    }

    return [
      for (final (index, job) in jobs.indexed) ...[
        if (index > 0) const Divider(color: AppColors.divider, height: 1),
        JobRow(
          job: job,
          tourist: viewModel.touristOf(job.touristId),
          showCity: !viewModel.isLocal,
          onTap: () => context.push(Routes.guideJobPath(job.id)),
        ),
      ],
    ];
  }
}

/// "Disponible C$ 1152" y "Por cobrar C$ 1920": el saldo de un vistazo, que
/// lleva al balance.
class _BalanceLine extends StatelessWidget {
  const _BalanceLine({
    required this.available,
    required this.pending,
    required this.onTap,
  });

  final num available;
  final num pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget amount(String label, num value, {Color? color}) => Text.rich(
      TextSpan(
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryText),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: Formatters.keepTogether(Formatters.currency(value)),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 2,
                    children: [
                      amount(
                        l10n.guideAppHomeAvailable,
                        available,
                        color: AppColors.accentSecondaryGreen,
                      ),
                      amount(l10n.guideAppHomePending, pending),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El viaje más próximo: cuándo, qué, con quién y cuánto recibe.
class _NextTrip extends StatelessWidget {
  const _NextTrip({
    required this.trip,
    required this.tourist,
    required this.onTap,
  });

  final GuideTrip trip;
  final TouristProfile? tourist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: AppColors.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            side: const BorderSide(color: AppColors.divider),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  DateBadge(date: trip.date, time: trip.startTime),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.circuitTitle, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.facts([
                            Formatters.people(trip.groupSize),
                            ?tourist?.name,
                          ]),
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.guideAppYouReceive(
                            Formatters.currency(trip.earnings),
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentSecondaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "¡Carlos te contrató!", hasta que el guía abre el viaje.
class _HireNotice extends StatelessWidget {
  const _HireNotice({
    required this.trip,
    required this.tourist,
    required this.onOpen,
  });

  final GuideTrip trip;
  final TouristProfile? tourist;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final who = tourist?.shortName ?? l10n.guideAppHomeATourist;
    return InlineNotice(
      tone: NoticeTone.success,
      message: l10n.guideAppHomeHiredNotice(
        who,
        trip.circuitTitle,
        Formatters.relativeDay(trip.date),
        Formatters.timeText(trip.startTime),
      ),
      action: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onOpen,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            l10n.guideAppViewTrip,
            style: AppTextStyles.link.copyWith(
              color: AppColors.accentSecondaryGreen,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mientras se leen las propuestas: la forma de la lista, sin contenido.
class _JobsSkeleton extends StatelessWidget {
  const _JobsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.guideAppHomeLoadingProposals,
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(width: 170, height: 14),
                        const SizedBox(height: 8),
                        _bar(width: 230, height: 10),
                        const SizedBox(height: 8),
                        _bar(width: 140, height: 10),
                      ],
                    ),
                  ),
                  _bar(width: 70, height: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
