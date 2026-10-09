import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_application.dart';
import '../../../data/models/guide_request.dart';
import '../../../router/routes.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/guide_hired_overlay.dart';

/// Pregunta antes de contratar a quien mandó [application]. `true` si el
/// turista confirmó.
Future<bool> confirmHire(BuildContext context, GuideApplication application) {
  final l10n = context.l10n;
  final price = Formatters.currency(application.proposedPrice);

  return showConfirmDialog(
    context,
    icon: Icons.handshake_outlined,
    title: l10n.guideRequestHireTitle(application.guide.name),
    message: application.role == ApplicationRole.guide
        ? l10n.guideRequestHireMessageGuide(price)
        : l10n.guideRequestHireMessageTranslator(price),
    confirmLabel: l10n.guideRequestHire,
  );
}

/// Lo que sigue después de contratar: si ya quedó completo el equipo,
/// muestra el aviso y abre el chat (con el API, la reserva [bookingId] que
/// nació al elegir); si falta el otro puesto, avisa cuál queda por elegir.
/// Devuelve `true` si ya no falta nadie.
Future<bool> showHireOutcome(
  BuildContext context,
  GuideRequest request, {
  String? bookingId,
}) async {
  if (request.status == GuideRequestStatus.hired) {
    await showGuideHiredOverlay(
      context,
      people: [for (final application in request.hired) application.guide],
    );
    if (context.mounted) {
      context.push(
        bookingId == null
            ? Routes.guideChat
            : Routes.bookingDetailPath(bookingId),
      );
    }
    return true;
  }

  final missing = request.roles.firstWhere(
    (role) => request.hiredFor(role) == null,
    orElse: () => ApplicationRole.guide,
  );
  final l10n = context.l10n;
  ScaffoldMessenger.of(context).showMessage(
    missing == ApplicationRole.translator
        ? l10n.guideRequestHireNextTranslator
        : l10n.guideRequestHireNextGuide,
    tone: SnackTone.success,
  );
  return false;
}
