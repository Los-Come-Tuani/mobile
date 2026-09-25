import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_application.dart';
import '../../../data/models/guide_request.dart';
import '../../../router/routes.dart';
import '../../booking/widgets/booking_card.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/primary_button.dart';
import '../viewmodels/guide_request_viewmodel.dart';
import '../widgets/application_card.dart';
import '../widgets/hire_flow.dart';

/// La propuesta de trabajo publicada: su resumen, las postulaciones que van
/// llegando y a quién contratar — como publicar una oferta y revisar a los
/// candidatos.
class GuideProposalView extends StatefulWidget {
  const GuideProposalView({super.key});

  @override
  State<GuideProposalView> createState() => _GuideProposalViewState();
}

class _GuideProposalViewState extends State<GuideProposalView> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Sólo redibuja el tiempo restante; el estado real vive en el repo.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _hire(GuideApplication application) async {
    final viewModel = context.read<GuideRequestViewModel>();
    if (!await confirmHire(context, application) || !mounted) return;

    if (!viewModel.hire(application)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Esta postulación ya no está disponible'),
          ),
        );
      return;
    }

    final request = viewModel.request;
    if (request != null) await showHireOutcome(context, request);
  }

  void _openProfile(GuideApplication application) =>
      context.push(Routes.guideProfilePath(application.guide.id));

  Future<void> _cancel() async {
    final viewModel = context.read<GuideRequestViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('¿Retirar tu propuesta?'),
        content: const Text(
          'Los guías ya no podrán postularse. Tu reserva del circuito sigue '
          'agendada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed == true) viewModel.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuideRequestViewModel>();
    final request = viewModel.request;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          'Tu propuesta',
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: request == null
          ? const _NoProposal()
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 16, bottom: 24),
              children: [
                _StatusCard(request: request, remaining: viewModel.remaining),
                const SizedBox(height: 16),
                _TermsCard(request: request),
                if (request.status == GuideRequestStatus.hired) ...[
                  const SizedBox(height: 24),
                  Text('Tu equipo', style: AppTextStyles.title),
                  const SizedBox(height: 10),
                  for (final application in request.hired) ...[
                    ApplicationCard(
                      application: application,
                      budget: request.terms.budgetFor(application.role),
                      isHired: true,
                      onViewProfile: () => _openProfile(application),
                    ),
                    const SizedBox(height: 12),
                  ],
                  PrimaryButton(
                    label: 'Ir al chat',
                    icon: Icons.chat_bubble_outline,
                    onPressed: () => context.push(Routes.guideChat),
                  ),
                ] else if (request.isOpen) ...[
                  for (final role in request.roles) ...[
                    const SizedBox(height: 24),
                    _RoleSection(
                      request: request,
                      role: role,
                      onHire: _hire,
                      onViewProfile: _openProfile,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _cancel,
                      child: const Text('Retirar propuesta'),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Volver al inicio',
                    onPressed: () => context.go(Routes.home),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Postulaciones para un puesto (guía o traductor), o quién quedó
/// contratado para él.
class _RoleSection extends StatelessWidget {
  const _RoleSection({
    required this.request,
    required this.role,
    required this.onHire,
    required this.onViewProfile,
  });

  final GuideRequest request;
  final ApplicationRole role;
  final ValueChanged<GuideApplication> onHire;
  final ValueChanged<GuideApplication> onViewProfile;

  @override
  Widget build(BuildContext context) {
    final hired = request.hiredFor(role);
    final applications = request.applicationsFor(role);
    final budget = request.terms.budgetFor(role);
    final title = request.roles.length == 1
        ? 'Postulaciones'
        : switch (role) {
            ApplicationRole.guide => 'Guías',
            ApplicationRole.translator => 'Traductores',
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hired == null ? '$title (${applications.length})' : title,
          style: AppTextStyles.title,
        ),
        const SizedBox(height: 10),
        if (hired != null)
          ApplicationCard(
            application: hired,
            budget: budget,
            isHired: true,
            onViewProfile: () => onViewProfile(hired),
          )
        else if (applications.isEmpty)
          _WaitingForApplications(role: role, request: request)
        else
          for (final application in applications) ...[
            ApplicationCard(
              application: application,
              budget: budget,
              onViewProfile: () => onViewProfile(application),
              onHire: request.canHire(application)
                  ? () => onHire(application)
                  : null,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _WaitingForApplications extends StatelessWidget {
  const _WaitingForApplications({required this.role, required this.request});

  final ApplicationRole role;
  final GuideRequest request;

  @override
  Widget build(BuildContext context) {
    final language = request.terms.touristLanguage?.toLowerCase();
    final who = switch (role) {
      ApplicationRole.guide => 'guías',
      ApplicationRole.translator =>
        language == null ? 'traductores' : 'traductores de $language',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Esperando postulaciones de $who. Te avisamos aquí apenas '
              'alguien se postule.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// En qué va la propuesta: publicada (y cuánto le queda), resuelta o
/// cerrada sin contratar.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.request, required this.remaining});

  final GuideRequest request;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final (color, leading, title, subtitle) = switch (request.status) {
      GuideRequestStatus.open => (
        AppColors.primary30,
        const _PulsingDot(),
        'Publicada · recibiendo postulaciones',
        'Los guías ya pueden verla. Vence en '
            '${Formatters.remaining(remaining)}.',
      ),
      GuideRequestStatus.hired => (
        AppColors.accentSecondaryGreen,
        const Icon(Icons.check_circle, color: AppColors.accentSecondaryGreen),
        '¡Listo! Ya tienes quién te acompañe',
        'Acordaste ${Formatters.currency(request.agreedPrice)} por el '
            'servicio.',
      ),
      GuideRequestStatus.expired => (
        AppColors.hintText,
        const Icon(
          Icons.hourglass_disabled_outlined,
          color: AppColors.hintText,
        ),
        'Tu propuesta venció',
        'No contrataste a nadie a tiempo. Puedes publicar otra desde Agendar.',
      ),
      GuideRequestStatus.cancelled => (
        AppColors.hintText,
        const Icon(Icons.cancel_outlined, color: AppColors.hintText),
        'Retiraste esta propuesta',
        'Los guías ya no pueden postularse.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que publicó el turista: el mismo detalle que ven los guías.
class _TermsCard extends StatelessWidget {
  const _TermsCard({required this.request});

  final GuideRequest request;

  @override
  Widget build(BuildContext context) {
    final terms = request.terms;
    final bothRoles = request.roles.length > 1;

    return BookingCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        Text(request.circuitTitle, style: AppTextStyles.cardTitle),
        const SizedBox(height: 6),
        _TermLine(
          icon: Icons.calendar_month_outlined,
          text:
              '${Formatters.shortDate(request.date)} · ${request.startTime} · '
              '${Formatters.people(request.groupSize)}',
        ),
        _TermLine(
          icon: Icons.person_pin_circle_outlined,
          text: '${terms.needLabel} · ${terms.serviceHours} h',
        ),
        if (terms.need.needsGuide)
          _TermLine(
            icon: Icons.directions_car_outlined,
            text: switch (terms.transportOption) {
              TransportOption.onFoot => 'Recorrido a pie',
              TransportOption.touristProvides => 'Tú pones el transporte',
              TransportOption.guideProvides => 'El guía pone el transporte',
            },
          ),
        if (terms.touristProvidesLodging)
          const _TermLine(
            icon: Icons.hotel_outlined,
            text: 'Le das alojamiento al guía',
          ),
        _TermLine(
          icon: Icons.sell_outlined,
          text: bothRoles
              ? 'Presupuesto: ${Formatters.currency(terms.budget)} (guía '
                    '${Formatters.currency(terms.guideBudget)} + traductor '
                    '${Formatters.currency(terms.translatorBudget)})'
              : 'Presupuesto: ${Formatters.currency(terms.budget)}',
        ),
      ],
    );
  }
}

class _TermLine extends StatelessWidget {
  const _TermLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary30),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

/// Punto que late mientras la propuesta sigue abierta.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: 1 - _controller.value,
              child: Transform.scale(
                scale: 0.4 + _controller.value * 0.6,
                child: child,
              ),
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary30.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary30,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoProposal extends StatelessWidget {
  const _NoProposal();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 48,
              color: AppColors.hintText,
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes una propuesta activa',
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 6),
            Text(
              'Publica una al agendar un circuito, desde "Guía o traductor".',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
