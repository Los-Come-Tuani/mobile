import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/datasources/repository/saved_repository.dart';

/// Marcador de "guardado" conectado a [SavedRepository]: el estado se
/// mantiene entre el home y el detalle sin pasar callbacks.
class BookmarkButton extends StatelessWidget {
  const BookmarkButton({
    super.key,
    required this.itemId,
    this.size = 20,
    this.color = AppColors.primaryText,
  });

  final String itemId;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SavedRepository>();
    final isSaved = repository.isSaved(itemId);

    return IconButton(
      iconSize: size,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tight(Size.square(size + 16)),
      visualDensity: VisualDensity.compact,
      tooltip: isSaved ? 'Quitar de guardados' : 'Guardar',
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_border,
        color: isSaved ? AppColors.primary30 : color,
      ),
      onPressed: () => repository.toggle(itemId),
    );
  }
}
