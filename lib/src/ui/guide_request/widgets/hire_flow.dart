import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_application.dart';
import '../../../data/models/guide_request.dart';
import '../../../router/routes.dart';
import '../../widgets/guide_hired_overlay.dart';

/// Pregunta antes de contratar a quien mandó [application]. `true` si el
/// turista confirmó.
Future<bool> confirmHire(
  BuildContext context,
  GuideApplication application,
) async {
  final roleName = application.role == ApplicationRole.guide
      ? 'guía'
      : 'traductor';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.white,
      title: Text('¿Contratar a ${application.guide.name}?'),
      content: Text(
        'Será tu $roleName por '
        '${Formatters.currency(application.proposedPrice)}. Las demás '
        'postulaciones para este puesto quedan descartadas.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Contratar'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Lo que sigue después de contratar: si ya quedó completo el equipo,
/// muestra el aviso y abre el chat; si falta el otro puesto, avisa cuál
/// queda por elegir. Devuelve `true` si ya no falta nadie.
Future<bool> showHireOutcome(BuildContext context, GuideRequest request) async {
  if (request.status == GuideRequestStatus.hired) {
    await showGuideHiredOverlay(
      context,
      people: [for (final application in request.hired) application.guide],
    );
    if (context.mounted) context.push(Routes.guideChat);
    return true;
  }

  final missing = request.roles.firstWhere(
    (role) => request.hiredFor(role) == null,
    orElse: () => ApplicationRole.guide,
  );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          missing == ApplicationRole.translator
              ? '¡Listo! Ahora elige a tu traductor.'
              : '¡Listo! Ahora elige a tu guía.',
        ),
      ),
    );
  return false;
}
