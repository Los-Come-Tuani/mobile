import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_request.dart';
import '../../../router/routes.dart';
import '../../circuit_detail/widgets/guide_request_sheet.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/guide_found_overlay.dart';
import '../viewmodels/guide_request_viewmodel.dart';

/// Pantalla de "Buscando guía…", con radar y cuenta regresiva contra el
/// tiempo límite elegido por el turista — como la búsqueda de conductor de
/// inDrive.
///
/// Si llega con [selection] (recién armada en `guide_request_sheet.dart`),
/// arranca la búsqueda. Si no (por ejemplo, se reabre desde el aviso del
/// home), sólo observa la solicitud activa que ya existe.
class GuideSearchingView extends StatefulWidget {
  const GuideSearchingView({super.key, this.selection});

  final GuideRequestSelection? selection;

  @override
  State<GuideSearchingView> createState() => _GuideSearchingViewState();
}

class _GuideSearchingViewState extends State<GuideSearchingView> {
  Timer? _tick;
  bool _started = false;
  bool _matchedHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final viewModel = context.read<GuideRequestViewModel>();
      await viewModel.load();
      if (!mounted) return;

      final selection = widget.selection;
      if (selection != null && !_started) {
        _started = true;
        viewModel.startRequest(
          price: selection.price,
          timeLimit: selection.timeLimit,
          guideTier: selection.guideTier,
          includeTranslator: selection.includeTranslator,
          serviceHours: selection.serviceHours,
          transportOption: selection.transportOption,
          touristProvidesLodging: selection.touristProvidesLodging,
          touristLanguage: selection.touristLanguage,
        );
      }
    });

    // Sólo redibuja la cuenta regresiva; el estado real vive en el repo.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _handleMatched(GuideRequestViewModel viewModel) async {
    if (_matchedHandled) return;
    final participants = viewModel.activeRequest?.matchedParticipants ?? const [];
    if (participants.isEmpty) return;

    _matchedHandled = true;
    await showGuideFoundOverlay(context, participants: participants);
    if (mounted) {
      context.pushReplacement(Routes.guideProfilePath(participants.first.id));
    }
  }

  void _cancel() => context.read<GuideRequestViewModel>().cancel();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuideRequestViewModel>();

    if (viewModel.status == GuideRequestStatus.matched) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleMatched(viewModel),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Guía en vivo',
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : _Body(viewModel: viewModel, onCancel: _cancel),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.viewModel, required this.onCancel});

  final GuideRequestViewModel viewModel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final request = viewModel.activeRequest;

    return switch (request?.status) {
      GuideRequestStatus.searching => _SearchingState(
        request: request!,
        remaining: viewModel.remaining,
        onCancel: onCancel,
      ),
      GuideRequestStatus.matched => _MessageState(
        icon: Icons.check_circle_outline,
        iconColor: AppColors.accentSecondaryGreen,
        title: _matchedTitle(request!),
        message: 'Abriendo su perfil…',
      ),
      GuideRequestStatus.expired => _MessageState(
        icon: Icons.hourglass_disabled_outlined,
        iconColor: AppColors.hintText,
        title: 'No encontramos a nadie a tiempo',
        message: 'Puedes intentarlo de nuevo con un precio más alto o un '
            'tiempo de búsqueda mayor.',
        onBack: () => context.pop(),
      ),
      GuideRequestStatus.cancelled => _MessageState(
        icon: Icons.cancel_outlined,
        iconColor: AppColors.hintText,
        title: 'Solicitud cancelada',
        message: 'Puedes pedir un guía o traductor cuando quieras desde el '
            'circuito.',
        onBack: () => context.pop(),
      ),
      null => _MessageState(
        icon: Icons.info_outline,
        iconColor: AppColors.hintText,
        title: 'No hay una solicitud activa',
        message: 'Vuelve al circuito para pedir un guía o traductor.',
        onBack: () => context.pop(),
      ),
    };
  }

  String _matchedTitle(GuideRequest request) {
    final hasGuide = request.guide != null;
    final hasTranslator = request.translator != null;
    if (hasGuide && hasTranslator) return '¡Guía y traductor encontrados!';
    if (hasTranslator) return '¡Traductor encontrado!';
    return '¡Guía encontrado!';
  }
}

class _SearchingState extends StatelessWidget {
  const _SearchingState({
    required this.request,
    required this.remaining,
    required this.onCancel,
  });

  final GuideRequest request;
  final Duration remaining;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RadarPing(remaining: remaining, timeLimit: request.timeLimit),
            const SizedBox(height: 20),
            Text(_formatCountdown(remaining), style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(
              'Buscando ${_describeRequest(request)}…',
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 8),
            Text(
              'Para ${request.circuitTitle} · Ofreces '
              '${Formatters.currency(request.suggestedPrice)}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              _describeExtras(request),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 32),
            OutlinedButton(onPressed: onCancel, child: const Text('Cancelar')),
          ],
        ),
      ),
    );
  }
}

/// Radar tipo inDrive: círculos que se expanden y se desvanecen alrededor
/// de un ícono central, en fases distintas sobre el mismo controlador.
class _RadarPing extends StatefulWidget {
  const _RadarPing({required this.remaining, required this.timeLimit});

  final Duration remaining;
  final Duration timeLimit;

  @override
  State<_RadarPing> createState() => _RadarPingState();
}

class _RadarPingState extends State<_RadarPing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  static const _phases = [0.0, 1 / 3, 2 / 3];
  static const _size = 180.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final phase in _phases)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = (_controller.value + phase) % 1.0;
                return Opacity(
                  opacity: (1 - t) * 0.45,
                  child: Transform.scale(
                    scale: 0.35 + t * 0.65,
                    child: Container(
                      width: _size,
                      height: _size,
                      decoration: const BoxDecoration(
                        color: AppColors.primary30,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary30,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search,
              color: AppColors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.onBack,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: AppTextStyles.title),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              if (onBack != null) ...[
                const SizedBox(height: 20),
                TextButton(onPressed: onBack, child: const Text('Volver')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto corto de lo que se está buscando, para el encabezado de la
/// búsqueda ("Buscando guía local + traductor (Inglés)…").
String _describeRequest(GuideRequest request) {
  final parts = <String>[];
  switch (request.guideTier) {
    case GuideTier.local:
      parts.add('guía local');
    case GuideTier.bilingual:
      parts.add('guía + ${request.touristLanguage}');
    case GuideTier.none:
      break;
  }
  if (request.includeTranslator) {
    parts.add('traductor de ${request.touristLanguage}');
  }
  return parts.isEmpty ? 'guía' : parts.join(' + ');
}

/// Línea con los detalles de la publicación: horas, transporte y
/// alojamiento, más el plazo fijo de 24h — como el detalle de una oferta de
/// trabajo.
String _describeExtras(GuideRequest request) {
  final parts = <String>['${request.serviceHours}h de servicio'];
  if (request.guideTier != GuideTier.none) {
    parts.add(switch (request.transportOption) {
      TransportOption.onFoot => 'a pie',
      TransportOption.touristProvides => 'transporte del turista',
      TransportOption.guideProvides => 'transporte del guía',
    });
    if (request.touristProvidesLodging) parts.add('con alojamiento');
  }
  return '${parts.join(' · ')} · vence en 24h si nadie responde';
}

/// `remaining` puede llegar a 24h: se muestra en horas y minutos mientras
/// falte una hora o más, y en minutos y segundos por debajo de eso.
String _formatCountdown(Duration d) {
  if (d.inHours >= 1) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m';
  }
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
