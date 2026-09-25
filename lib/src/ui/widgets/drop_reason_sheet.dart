import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/stop.dart';
import '../../data/models/visit_event.dart';
import 'app_choice_chip.dart';

const String _whyWeAsk =
    'Nos ayuda a mejorar los circuitos y a que cada lugar sepa qué pasó.';

/// Pregunta por qué se deja una parada (al quitarla o saltarla). Devuelve
/// `null` si el turista cierra la hoja sin elegir.
Future<DropReason?> showDropReasonSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<DropReason>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(_whyWeAsk, style: AppTextStyles.caption),
            const SizedBox(height: 8),
            for (final reason in DropReason.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  iconForDropReason(reason),
                  color: AppColors.primary30,
                ),
                title: Text(reason.label, style: AppTextStyles.body),
                onTap: () => Navigator.of(context).pop(reason),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Al finalizar un viaje con paradas pendientes, pregunta por qué no se fue
/// a cada una; se puede dejar sin responder. Devuelve las razones elegidas
/// por id de parada, o `null` si el turista prefiere seguir el viaje.
Future<Map<String, DropReason>?> showTripEndSheet(
  BuildContext context, {
  required List<Stop> pending,
}) {
  return showModalBottomSheet<Map<String, DropReason>>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _TripEndSheet(pending: pending),
  );
}

IconData iconForDropReason(DropReason reason) => switch (reason) {
  DropReason.closed => Icons.lock_clock,
  DropReason.tooFar => Icons.route_outlined,
  DropReason.noTime => Icons.timer_off_outlined,
  DropReason.tooExpensive => Icons.money_off,
  DropReason.notInterested => Icons.thumb_down_off_alt_outlined,
  DropReason.weather => Icons.thunderstorm_outlined,
  DropReason.other => Icons.more_horiz,
};

class _TripEndSheet extends StatefulWidget {
  const _TripEndSheet({required this.pending});

  final List<Stop> pending;

  @override
  State<_TripEndSheet> createState() => _TripEndSheetState();
}

class _TripEndSheetState extends State<_TripEndSheet> {
  final Map<String, DropReason> _reasons = {};

  void _toggle(String stopId, DropReason reason) {
    setState(() {
      if (_reasons[stopId] == reason) {
        _reasons.remove(stopId);
      } else {
        _reasons[stopId] = reason;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.pending.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count == 1
                  ? 'Te quedó 1 parada sin visitar'
                  : 'Te quedaron $count paradas sin visitar',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 4),
            Text(
              '¿Por qué no fuiste? Es opcional. $_whyWeAsk',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final stop in widget.pending) ...[
                    Text(stop.name, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final reason in DropReason.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AppChoiceChip(
                                label: reason.label,
                                selected: _reasons[stop.id] == reason,
                                onSelected: () => _toggle(stop.id, reason),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Seguir el viaje'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_reasons),
                    child: const Text('Finalizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
