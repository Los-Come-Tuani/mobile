import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/stop.dart';
import '../../widgets/remote_image.dart';

/// Hoja "¿Dónde querés comenzar tu viaje?": elige la parada de arranque de
/// un circuito. Devuelve `null` si el usuario cancela.
Future<Stop?> showStartTripSheet(
  BuildContext context, {
  required List<Stop> stops,
}) {
  return showModalBottomSheet<Stop>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _StartTripSheet(stops: stops),
  );
}

class _StartTripSheet extends StatelessWidget {
  const _StartTripSheet({required this.stops});

  final List<Stop> stops;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                '¿Dónde querés comenzar tu viaje?',
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: stops.length,
                itemBuilder: (context, index) => _StopRow(
                  stop: stops[index],
                  position: index + 1,
                  onTap: () => Navigator.of(context).pop(stops[index]),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.position,
    required this.onTap,
  });

  final Stop stop;
  final int position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: stop.coverImage.isEmpty
          ? Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.placeholder,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.secondaryText,
              ),
            )
          : RemoteImage(
              url: stop.coverImage,
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
      title: Text(
        stop.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body,
      ),
      subtitle: Text(
        'Parada $position · ${stop.address}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
    );
  }
}
