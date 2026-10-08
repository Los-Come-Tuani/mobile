import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/result.dart';
import '../../data/datasources/repository/badges_repository.dart';
import '../../data/datasources/repository/location_repository.dart';
import '../stop_detail/view/qr_scanner_view.dart';
import '../widgets/badge_earned_overlay.dart';

/// Con el API: escanea el QR de un lugar y acredita la visita
/// (`POST /visit/`) con la ubicación del teléfono. Muestra la insignia ganada
/// o el mensaje del API (lejos del lugar, ya ganada hoy, QR que no da
/// insignia). `true` si se acreditó.
Future<bool> scanAndRecordVisit(BuildContext context) async {
  final code = await scanVisitQr(context);
  if (code == null || !context.mounted) return false;

  final badges = context.read<BadgesRepository>();
  final location = context.read<LocationRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final result = await badges.recordVisit(
    code,
    locate: location.currentPosition,
  );
  if (!context.mounted) return false;
  switch (result) {
    case Ok(:final value):
      await showBadgeEarnedAnimation(context, category: value.category);
      return true;
    case Failure(:final message):
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return false;
  }
}
