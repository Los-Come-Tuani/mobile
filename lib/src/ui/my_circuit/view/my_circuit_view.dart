import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/stop_list_tile.dart';
import '../viewmodels/my_circuit_viewmodel.dart';

/// Detalle de un circuito creado por el usuario: su lista de paradas.
class MyCircuitView extends StatefulWidget {
  const MyCircuitView({super.key});

  @override
  State<MyCircuitView> createState() => _MyCircuitViewState();
}

class _MyCircuitViewState extends State<MyCircuitView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MyCircuitViewModel>().load();
    });
  }

  void _removeStop(String stopId, String stopName) {
    final viewModel = context.read<MyCircuitViewModel>();
    viewModel.removeStop(stopId);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$stopName se quitó del circuito'),
          action: SnackBarAction(
            label: 'Deshacer',
            textColor: AppColors.primary10,
            onPressed: () => viewModel.addStopBack(stopId),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyCircuitViewModel>();
    final collection = viewModel.collection;
    final stops = viewModel.stops;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text(collection?.title ?? 'Mis circuitos'),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 16, bottom: 24),
              children: [
                Text(
                  '${stops.length} ${stops.length == 1 ? 'parada' : 'paradas'}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
                if (stops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.route_outlined,
                          size: 44,
                          color: AppColors.hintText,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Este circuito todavía no tiene paradas',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  )
                else
                  for (var i = 0; i < stops.length; i++)
                    StopListTile(
                      stop: stops[i],
                      position: i + 1,
                      showConnector: i < stops.length - 1,
                      onTap: () =>
                          context.push(Routes.stopDetailPath(stops[i].id)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: AppColors.secondaryText,
                        tooltip: 'Quitar del circuito',
                        onPressed: () =>
                            _removeStop(stops[i].id, stops[i].name),
                      ),
                    ),
              ],
            ),
    );
  }
}
