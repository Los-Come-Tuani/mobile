import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/time_parser.dart';
import '../../../data/models/itinerary.dart';
import '../../widgets/app_choice_chip.dart';

/// Cómo quiere hacer el día: a qué hora sale, cómo se mueve y a qué ritmo.
///
/// Todo se elige aquí mismo, sin abrir hojas: cada cambio recalcula al
/// instante los horarios del itinerario que va debajo.
class DayPlanEditor extends StatelessWidget {
  const DayPlanEditor({
    super.key,
    required this.startTime,
    required this.startTimes,
    required this.travelMode,
    required this.pace,
    required this.onStartTimeChanged,
    required this.onTravelModeChanged,
    required this.onPaceChanged,
  });

  final String startTime;
  final List<String> startTimes;
  final TravelMode travelMode;
  final ItineraryPace pace;
  final ValueChanged<String> onStartTimeChanged;
  final ValueChanged<TravelMode> onTravelModeChanged;
  final ValueChanged<ItineraryPace> onPaceChanged;

  static String _paceHint(ItineraryPace pace) => switch (pace) {
    ItineraryPace.relaxed =>
      'Más tiempo en cada parada y un respiro entre una y otra',
    ItineraryPace.balanced => 'El tiempo sugerido en cada parada',
    ItineraryPace.intense => 'Visitas más cortas para que te rinda el día',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿A qué hora sales?', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        _StartTimeStrip(
          times: startTimes,
          selected: startTime,
          onSelected: onStartTimeChanged,
        ),
        const SizedBox(height: 20),
        Text('¿Cómo te mueves?', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        _Segmented<TravelMode>(
          values: TravelMode.values,
          selected: travelMode,
          label: (mode) => mode.label,
          icon: (mode) => mode == TravelMode.walking
              ? Icons.directions_walk
              : Icons.directions_car_outlined,
          onChanged: onTravelModeChanged,
        ),
        const SizedBox(height: 20),
        Text('¿A qué ritmo?', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        _Segmented<ItineraryPace>(
          values: ItineraryPace.values,
          selected: pace,
          label: (pace) => pace.label,
          onChanged: onPaceChanged,
        ),
        const SizedBox(height: 6),
        Text(_paceHint(pace), style: AppTextStyles.caption),
      ],
    );
  }
}

/// Horas de salida en una fila que se desliza; la elegida queda a la vista.
/// "Otra hora" abre el reloj para cualquier hora que no esté en la lista.
class _StartTimeStrip extends StatefulWidget {
  const _StartTimeStrip({
    required this.times,
    required this.selected,
    required this.onSelected,
  });

  final List<String> times;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<_StartTimeStrip> createState() => _StartTimeStripState();
}

class _StartTimeStripState extends State<_StartTimeStrip> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealSelected(animate: false);
  }

  @override
  void didUpdateWidget(_StartTimeStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _revealSelected(animate: true);
  }

  void _revealSelected({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _selectedKey.currentContext;
      if (chip == null || !chip.mounted) return;
      Scrollable.ensureVisible(
        chip,
        alignment: 0.5,
        duration: animate && !MediaQuery.disableAnimationsOf(chip)
            ? const Duration(milliseconds: 250)
            : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _pickOtherTime() async {
    final minutes = TimeParser.minutesOfDay(widget.selected) ?? 9 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: 'Hora de salida',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (picked == null) return;
    widget.onSelected(Formatters.time(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.times.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == widget.times.length) {
            return Center(
              child: AppChoiceChip(
                label: 'Otra hora',
                icon: Icons.schedule,
                selected: false,
                onSelected: _pickOtherTime,
              ),
            );
          }
          final time = widget.times[index];
          final isSelected = time == widget.selected;
          return Center(
            child: AppChoiceChip(
              key: isSelected ? _selectedKey : null,
              label: time,
              selected: isSelected,
              onSelected: () => widget.onSelected(time),
            ),
          );
        },
      ),
    );
  }
}

/// Selector de pocas opciones excluyentes, a lo ancho.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.icon,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final IconData Function(T value)? icon;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        segments: [
          for (final value in values)
            ButtonSegment<T>(
              value: value,
              label: Text(label(value)),
              icon: icon == null ? null : Icon(icon!(value), size: 18),
            ),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (values) => onChanged(values.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.primaryText,
          selectedBackgroundColor: AppColors.primary30,
          selectedForegroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.divider),
          textStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size.fromHeight(44),
        ),
      ),
    );
  }
}
