import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/datasources/repository/saved_repository.dart';

/// Hoja de opciones rápidas detrás del botón de "más" del detalle de una
/// parada o un evento: guardar y, sólo para paradas, añadir a un circuito.
///
/// Devuelve `true` si el usuario eligió "Añadir a un circuito" — quien la
/// llama es quien abre esa segunda hoja, para no encadenar navegación desde
/// acá adentro.
Future<bool?> showItemOptionsSheet(
  BuildContext context, {
  required String itemId,
  bool showAddToCircuit = false,
}) {
  final savedRepository = context.read<SavedRepository>();

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ChangeNotifierProvider.value(
      value: savedRepository,
      child: _ItemOptionsSheet(
        itemId: itemId,
        showAddToCircuit: showAddToCircuit,
      ),
    ),
  );
}

class _ItemOptionsSheet extends StatelessWidget {
  const _ItemOptionsSheet({
    required this.itemId,
    required this.showAddToCircuit,
  });

  final String itemId;
  final bool showAddToCircuit;

  @override
  Widget build(BuildContext context) {
    final savedRepository = context.watch<SavedRepository>();
    final isSaved = savedRepository.isSaved(itemId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: AppColors.primary30,
              ),
              title: Text(
                isSaved ? 'Quitar de guardados' : 'Guardar',
                style: AppTextStyles.body,
              ),
              onTap: () {
                savedRepository.toggle(itemId);
                Navigator.of(context).pop();
              },
            ),
            if (showAddToCircuit)
              ListTile(
                leading: const Icon(
                  Icons.playlist_add,
                  color: AppColors.primary30,
                ),
                title: Text('Añadir a un circuito', style: AppTextStyles.body),
                onTap: () => Navigator.of(context).pop(true),
              ),
          ],
        ),
      ),
    );
  }
}
