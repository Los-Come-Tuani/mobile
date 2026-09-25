import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/user_location.dart';
import '../../widgets/map/kplan_map.dart';

/// El mini mapa del viaje en curso en el home: hacia dónde va el turista y lo
/// que le falta. No recibe gestos, para no pelear con el scroll del home;
/// tocarlo abre el mapa completo.
class ActiveTripMap extends StatelessWidget {
  const ActiveTripMap({
    super.key,
    required this.map,
    required this.user,
    required this.onTap,
  });

  final RouteMap map;
  final UserLocation? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: KPlanMap(
            map: map,
            user: user,
            interactive: false,
            compact: true,
            // Arriba cabe el pin destacado, abajo su nombre y a los lados
            // media píldora.
            padding: const EdgeInsets.fromLTRB(64, 64, 64, 36),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary60.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.open_in_full,
                  size: 14,
                  color: AppColors.primary30,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ver mapa',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: onTap),
          ),
        ),
      ],
    );
  }
}
