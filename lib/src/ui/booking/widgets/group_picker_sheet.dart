import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Cantidad de personas de la reserva.
typedef GroupSelection = ({int adults, int children});

/// Hoja para elegir cuántos adultos y niños van al circuito.
Future<GroupSelection?> showGroupPickerSheet(
  BuildContext context, {
  required int adults,
  required int children,
}) {
  return showModalBottomSheet<GroupSelection>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _GroupPickerSheet(adults: adults, children: children),
  );
}

class _GroupPickerSheet extends StatefulWidget {
  const _GroupPickerSheet({required this.adults, required this.children});

  final int adults;
  final int children;

  @override
  State<_GroupPickerSheet> createState() => _GroupPickerSheetState();
}

class _GroupPickerSheetState extends State<_GroupPickerSheet> {
  late int _adults = widget.adults;
  late int _children = widget.children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.group, style: AppTextStyles.title),
            const SizedBox(height: 16),
            _CounterRow(
              label: 'Adultos',
              value: _adults,
              onChanged: (value) => setState(() => _adults = value),
            ),
            _CounterRow(
              label: 'Niños',
              value: _children,
              onChanged: (value) => setState(() => _children = value),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _adults + _children == 0
                        ? null
                        : () => Navigator.of(context).pop((
                            adults: _adults,
                            children: _children,
                          )),
                    child: const Text(AppStrings.accept),
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

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primary30,
            onPressed: value == 0 ? null : () => onChanged(value - 1),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary30,
            onPressed: value >= 20 ? null : () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
