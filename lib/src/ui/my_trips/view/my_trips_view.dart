import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/remote_image.dart';
import '../viewmodels/my_trips_viewmodel.dart';

/// Pantalla "Mis viajes": todos los circuitos que el usuario armó, con la
/// opción de crear uno nuevo o borrar los que ya no quiere.
class MyTripsView extends StatefulWidget {
  const MyTripsView({super.key});

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MyTripsViewModel>().load();
    });
  }

  Future<void> _createTrip() async {
    final viewModel = context.read<MyTripsViewModel>();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => const _NewTripDialog(),
    );
    if (title == null || title.isEmpty || !mounted) return;

    final trip = viewModel.createTrip(title);
    if (!mounted) return;
    context.push(Routes.myCircuitPath(trip.id));
  }

  Future<void> _deleteTrip(CircuitCollection trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text('¿Eliminar "${trip.title}"?', style: AppTextStyles.title),
        content: const Text('Se borrarán sus paradas guardadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<MyTripsViewModel>().deleteTrip(trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyTripsViewModel>();
    final trips = viewModel.trips;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis viajes')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 8, bottom: 24),
              children: [
                _NewTripRow(onTap: _createTrip),
                const SizedBox(height: 16),
                if (trips.isEmpty)
                  const _EmptyState()
                else
                  for (final trip in trips)
                    _TripTile(
                      trip: trip,
                      onTap: () => context.push(Routes.myCircuitPath(trip.id)),
                      onDelete: () => _deleteTrip(trip),
                    ),
              ],
            ),
    );
  }
}

/// Fila para crear un viaje nuevo, siempre visible al tope de la lista.
class _NewTripRow extends StatelessWidget {
  const _NewTripRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary30.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: const Icon(Icons.add, color: AppColors.primary30),
              ),
              const SizedBox(width: 12),
              Text(
                'Crear viaje nuevo',
                style: AppTextStyles.body.copyWith(color: AppColors.primary30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  final CircuitCollection trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                trip.image.isEmpty
                    ? Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.placeholder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.route_outlined,
                          color: AppColors.secondaryText,
                        ),
                      )
                    : RemoteImage(
                        url: trip.image,
                        width: 56,
                        height: 56,
                        borderRadius: BorderRadius.circular(8),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trip.stopCount} '
                        '${trip.stopCount == 1 ? 'parada' : 'paradas'}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.secondaryText,
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.route_outlined, size: 44, color: AppColors.hintText),
          const SizedBox(height: 12),
          Text(
            'Todavía no armaste ningún viaje',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Diálogo con el nombre del viaje nuevo.
class _NewTripDialog extends StatefulWidget {
  const _NewTripDialog();

  @override
  State<_NewTripDialog> createState() => _NewTripDialogState();
}

class _NewTripDialogState extends State<_NewTripDialog> {
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
      title: Text('Nuevo viaje', style: AppTextStyles.title),
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
