import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/models/circuit_collection.dart';
import '../../widgets/remote_image.dart';

/// Hoja "Añadir a un circuito", al estilo de agregar una canción a una
/// playlist: lista los circuitos, marca en cuáles ya está la parada y deja
/// crear uno nuevo.
Future<void> showAddToCircuitSheet(
  BuildContext context, {
  required String stopId,
  required String stopName,
}) {
  final repository = context.read<CircuitCollectionsRepository>();

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ChangeNotifierProvider.value(
      value: repository,
      child: _AddToCircuitSheet(stopId: stopId, stopName: stopName),
    ),
  );
}

class _AddToCircuitSheet extends StatelessWidget {
  const _AddToCircuitSheet({required this.stopId, required this.stopName});

  final String stopId;
  final String stopName;

  Future<void> _createCircuit(BuildContext context) async {
    final repository = context.read<CircuitCollectionsRepository>();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => const _NewCircuitDialog(),
    );
    if (title == null || title.isEmpty) return;

    repository.createCollection(title, withStopId: stopId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Circuito "$title" creado')));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<CircuitCollectionsRepository>();
    final collections = repository.collections;
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
              child: Column(
                children: [
                  Text('Añadir a un circuito', style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(
                    stopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _NewCircuitRow(onTap: () => _createCircuit(context)),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: collections.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('Todavía no tienes circuitos'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: collections.length,
                      itemBuilder: (context, index) => _CollectionRow(
                        collection: collections[index],
                        isSelected: collections[index].contains(stopId),
                        onTap: () => repository.toggleStop(
                          circuitId: collections[index].id,
                          stopId: stopId,
                        ),
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

/// Fila del "+" para crear un circuito nuevo.
class _NewCircuitRow extends StatelessWidget {
  const _NewCircuitRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary30.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: const Icon(Icons.add, color: AppColors.primary30),
      ),
      title: Text(
        'Crear circuito nuevo',
        style: AppTextStyles.body.copyWith(color: AppColors.primary30),
      ),
      subtitle: Text('Y añadir esta parada ahí', style: AppTextStyles.caption),
    );
  }
}

/// Fila de un circuito existente, con su estado de "añadido".
class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.collection,
    required this.isSelected,
    required this.onTap,
  });

  final CircuitCollection collection;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: collection.image.isEmpty
          ? Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.placeholder,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: const Icon(
                Icons.route_outlined,
                size: 20,
                color: AppColors.secondaryText,
              ),
            )
          : RemoteImage(
              url: collection.image,
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
      title: Text(
        collection.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body,
      ),
      subtitle: Text(
        isSelected
            ? 'Añadida a este circuito'
            : '${collection.stopCount} paradas',
        style: AppTextStyles.caption.copyWith(
          color: isSelected ? AppColors.accentSecondaryGreen : null,
        ),
      ),
      trailing: Icon(
        isSelected ? Icons.check_circle : Icons.add_circle_outline,
        color: isSelected ? AppColors.accentSecondaryGreen : AppColors.outline,
      ),
    );
  }
}

/// Diálogo con el nombre del circuito nuevo.
class _NewCircuitDialog extends StatefulWidget {
  const _NewCircuitDialog();

  @override
  State<_NewCircuitDialog> createState() => _NewCircuitDialogState();
}

class _NewCircuitDialogState extends State<_NewCircuitDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text('Nuevo circuito', style: AppTextStyles.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'Ej. Fin de semana en el sur',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Crear')),
      ],
    );
  }
}
