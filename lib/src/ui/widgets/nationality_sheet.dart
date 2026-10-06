import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/nationality.dart';

/// Hoja para elegir el país de nacionalidad, con buscador. Nicaragua va primero.
/// Devuelve el país elegido, o `null` si se cierra la hoja.
Future<Nationality?> showNationalitySheet(
  BuildContext context, {
  String? selectedCode,
}) {
  return showModalBottomSheet<Nationality>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _NationalitySheet(selectedCode: selectedCode),
  );
}

class _NationalitySheet extends StatefulWidget {
  const _NationalitySheet({this.selectedCode});

  final String? selectedCode;

  @override
  State<_NationalitySheet> createState() => _NationalitySheetState();
}

class _NationalitySheetState extends State<_NationalitySheet> {
  String _query = '';

  /// Sin tildes ni mayúsculas, para que "peru" encuentre "Perú".
  static String _fold(String text) {
    const from = 'áéíóúüñÁÉÍÓÚÜÑ';
    const to = 'aeiouunaeiouun';
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index < 0 ? char.toLowerCase() : to[index]);
    }
    return buffer.toString();
  }

  List<Nationality> get _matches {
    final all = Nationality.all;
    final query = _fold(_query.trim());
    if (query.isEmpty) {
      return [
        for (final item in all)
          if (item.code == Nationality.home) item,
        for (final item in all)
          if (item.code != Nationality.home) item,
      ];
    }
    return [
      for (final item in all)
        if (_fold(item.name).contains(query) ||
            item.code.toLowerCase() == query)
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Tu nacionalidad', style: AppTextStyles.title),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: false,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Busca tu país',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No encontramos ese país',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final item = matches[index];
                        final selected = item.code == widget.selectedCode;
                        return ListTile(
                          title: Text(item.name, style: AppTextStyles.body),
                          trailing: selected
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primary30,
                                )
                              : null,
                          selected: selected,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
