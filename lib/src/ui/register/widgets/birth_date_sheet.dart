import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Abre la hoja con las ruedas de día, mes y año. Devuelve la fecha elegida,
/// o `null` si se cancela.
Future<DateTime?> showBirthDateSheet(
  BuildContext context, {
  DateTime? initialDate,
}) {
  final now = DateTime.now();
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
    ),
    builder: (context) => _BirthDateSheet(
      initialDate: initialDate ?? DateTime(now.year - 18, now.month, now.day),
      lastDate: now,
    ),
  );
}

enum _DatePart { day, month, year }

class _BirthDateSheet extends StatefulWidget {
  const _BirthDateSheet({required this.initialDate, required this.lastDate});

  final DateTime initialDate;
  final DateTime lastDate;

  @override
  State<_BirthDateSheet> createState() => _BirthDateSheetState();
}

class _BirthDateSheetState extends State<_BirthDateSheet> {
  static const int _yearsBack = 100;

  late int _day = widget.initialDate.day;
  late int _month = widget.initialDate.month;
  late int _year = widget.initialDate.year;
  _DatePart _active = _DatePart.day;

  int get _lastYear => widget.lastDate.year;
  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  // Las ruedas van de mayor a menor hacia abajo, como en el diseño: el
  // índice 0 es el valor más alto.
  late final _dayController = FixedExtentScrollController(
    initialItem: 31 - _day,
  );
  late final _monthController = FixedExtentScrollController(
    initialItem: 12 - _month,
  );
  late final _yearController = FixedExtentScrollController(
    initialItem: _lastYear - _year,
  );

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _select(_DatePart part, int value) {
    setState(() {
      _active = part;
      switch (part) {
        case _DatePart.day:
          _day = value;
        case _DatePart.month:
          _month = value;
        case _DatePart.year:
          _year = value;
      }
    });

    // El 31 no existe en todos los meses: la rueda baja al último día válido.
    final overflow = _day - _daysInMonth;
    if (overflow > 0) {
      setState(() => _day = _daysInMonth);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _dayController.animateToItem(
          _dayController.selectedItem + overflow,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  DateTime get _selectedDate {
    final date = DateTime(_year, _month, _day.clamp(1, _daysInMonth));
    return date.isAfter(widget.lastDate) ? widget.lastDate : date;
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = _day.toString().padLeft(2, '0');
    final monthLabel = _month.toString().padLeft(2, '0');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 65,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.secondaryText,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 30),
            _PartSelector(
              active: _active,
              onSelected: (part) => setState(() => _active = part),
            ),
            const SizedBox(height: 28),
            Text.rich(
              TextSpan(
                children: [
                  _datePart(dayLabel, _active == _DatePart.day),
                  _datePart(' / ', false),
                  _datePart(monthLabel, _active == _DatePart.month),
                  _datePart(' / ', false),
                  _datePart('$_year', _active == _DatePart.year),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: _Wheel.visibleItems * _Wheel.itemExtent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Wheel(
                    controller: _dayController,
                    itemCount: 31,
                    looping: true,
                    selectedIndex: 31 - _day,
                    label: (index) => (31 - index).toString().padLeft(2, '0'),
                    isEnabled: (index) => 31 - index <= _daysInMonth,
                    onSelected: (index) => _select(_DatePart.day, 31 - index),
                  ),
                  const _WheelDivider(),
                  _Wheel(
                    controller: _monthController,
                    itemCount: 12,
                    looping: true,
                    selectedIndex: 12 - _month,
                    label: (index) => (12 - index).toString().padLeft(2, '0'),
                    onSelected: (index) => _select(_DatePart.month, 12 - index),
                  ),
                  const _WheelDivider(),
                  _Wheel(
                    controller: _yearController,
                    itemCount: _yearsBack + 1,
                    selectedIndex: _lastYear - _year,
                    label: (index) => '${_lastYear - index}',
                    onSelected: (index) =>
                        _select(_DatePart.year, _lastYear - index),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: _sheetButtonStyle(
                      OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary30,
                        side: const BorderSide(
                          color: AppColors.primary30,
                          width: 1.6,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 19),
                Expanded(
                  child: ElevatedButton(
                    style: _sheetButtonStyle(ElevatedButton.styleFrom()),
                    onPressed: () => Navigator.of(context).pop(_selectedDate),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _datePart(String text, bool highlighted) => TextSpan(
    text: text,
    style: AppTextStyles.body.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: highlighted ? AppColors.primary30 : AppColors.primaryText,
    ),
  );

  ButtonStyle _sheetButtonStyle(ButtonStyle base) => base.copyWith(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(42)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.4)),
    ),
    textStyle: WidgetStatePropertyAll(
      AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
    ),
  );
}

/// Pestañas "Día / Mes / Año": marcan qué parte de la fecha se está
/// editando.
class _PartSelector extends StatelessWidget {
  const _PartSelector({required this.active, required this.onSelected});

  final _DatePart active;
  final ValueChanged<_DatePart> onSelected;

  static const _labels = {
    _DatePart.day: 'Día',
    _DatePart.month: 'Mes',
    _DatePart.year: 'Año',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final part in _DatePart.values)
          GestureDetector(
            onTap: () => onSelected(part),
            child: Container(
              width: 80,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: part == _DatePart.day || part == active
                      ? const Radius.circular(6.4)
                      : Radius.zero,
                  right: part == _DatePart.year || part == active
                      ? const Radius.circular(6.4)
                      : Radius.zero,
                ),
                border: Border.all(
                  color: part == active
                      ? AppColors.primary30
                      : AppColors.placeholder,
                  width: 1.6,
                ),
              ),
              child: Text(
                _labels[part]!,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: part == active
                      ? AppColors.primary30
                      : AppColors.primaryText,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Una rueda de valores; el elegido va resaltado al centro.
class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.itemCount,
    required this.selectedIndex,
    required this.label,
    required this.onSelected,
    this.isEnabled,
    this.looping = false,
  });

  static const double itemExtent = 32;
  static const int visibleItems = 5;
  static const double width = 80;

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedIndex;
  final String Function(int index) label;
  final bool Function(int index)? isEnabled;
  final ValueChanged<int> onSelected;
  final bool looping;

  /// Distancia al elegido, contando la vuelta en las ruedas que giran.
  int _distance(int index) {
    final raw = (index - selectedIndex).abs();
    return looping ? raw.clamp(0, itemCount - raw) : raw;
  }

  Widget _item(int index) {
    final distance = _distance(index);
    final isSelected = distance == 0;
    final enabled = isEnabled?.call(index) ?? true;
    final alpha = switch (distance) {
      0 => 1.0,
      1 => 0.75,
      2 => 0.5,
      _ => 0.25,
    };

    return Center(
      child: Text(
        label(index),
        style: AppTextStyles.body.copyWith(
          fontSize: distance >= 2 ? 12 : 14,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? AppColors.primary30
              : AppColors.primaryText.withValues(
                  alpha: enabled ? alpha : alpha * 0.4,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: itemExtent,
            decoration: BoxDecoration(
              color: AppColors.placeholder,
              borderRadius: BorderRadius.circular(6.4),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: itemExtent,
            diameterRatio: 100,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) => onSelected(index % itemCount),
            childDelegate: looping
                ? ListWheelChildLoopingListDelegate(
                    children: [for (var i = 0; i < itemCount; i++) _item(i)],
                  )
                : ListWheelChildBuilderDelegate(
                    childCount: itemCount,
                    builder: (context, index) => _item(index),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WheelDivider extends StatelessWidget {
  const _WheelDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.6,
      height: _Wheel.visibleItems * _Wheel.itemExtent,
      margin: const EdgeInsets.symmetric(horizontal: 9.6),
      color: AppColors.primaryText,
    );
  }
}
