import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/stop.dart';
import 'remote_image.dart';

/// Hoja para cambiar el orden del recorrido arrastrando las paradas.
/// Devuelve los ids en el orden nuevo, o `null` si el turista cancela o lo
/// deja igual.
Future<List<String>?> showReorderStopsSheet(
  BuildContext context, {
  required List<Stop> stops,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ReorderStopsSheet(stops: stops),
  );
}

class _ReorderStopsSheet extends StatefulWidget {
  const _ReorderStopsSheet({required this.stops});

  final List<Stop> stops;

  @override
  State<_ReorderStopsSheet> createState() => _ReorderStopsSheetState();
}

class _ReorderStopsSheetState extends State<_ReorderStopsSheet> {
  late final List<Stop> _order = [...widget.stops];

  bool get _hasChanged {
    for (var i = 0; i < _order.length; i++) {
      if (_order[i].id != widget.stops[i].id) return true;
    }
    return false;
  }

  void _move(int from, int to) {
    setState(() {
      final stop = _order.removeAt(from);
      _order.insert(from < to ? to - 1 : to, stop);
    });
  }

  void _save() => Navigator.of(
    context,
  ).pop(_hasChanged ? [for (final stop in _order) stop.id] : null);

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ordenar paradas', style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(
                    'Arrastra cada parada a su lugar. Los horarios del '
                    'itinerario se recalculan solos.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _order.length,
                onReorder: _move,
                proxyDecorator: (child, index, animation) => Material(
                  color: AppColors.white,
                  elevation: 6,
                  shadowColor: AppColors.primary60.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: child,
                ),
                itemBuilder: (context, index) {
                  final stop = _order[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(stop.id),
                    index: index,
                    child: _StopRow(stop: stop, index: index),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary30),
                        foregroundColor: AppColors.primary30,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Guardar orden'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una parada con su lugar en el recorrido y la manija para arrastrarla
/// (también se arrastra manteniéndola presionada).
class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop, required this.index});

  final Stop stop;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 20, right: 8),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary30,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (stop.coverImage.isEmpty)
            Container(
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
          else
            RemoteImage(
              url: stop.coverImage,
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
        ],
      ),
      title: Text(
        stop.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body,
      ),
      subtitle: Text(
        [
          stop.category,
          stop.duration,
        ].where((part) => part.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption,
      ),
      trailing: ReorderableDragStartListener(
        index: index,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.drag_indicator,
            semanticLabel: 'Arrastrar para cambiar el orden',
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
