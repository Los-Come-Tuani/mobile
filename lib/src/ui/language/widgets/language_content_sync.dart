import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/group_session_repository.dart';
import '../../../data/datasources/repository/guide_work_repository.dart';
import '../../../data/datasources/repository/tourist_repository.dart';

/// Cuando cambia el idioma de la app, pide a los repositorios que ya cargaron
/// contenido del catálogo que lo vuelvan a leer en el idioma nuevo.
///
/// Sin esto, lo que se cargó antes (títulos de circuitos, horarios de grupo,
/// propuestas y viajes del guía, turistas) seguiría en el idioma anterior
/// hasta reiniciar la app. Lo que la persona hizo en la sesión (reservas,
/// circuitos propios, postulaciones, retiros) no se toca: cada repositorio
/// sólo cambia los textos que vienen del catálogo.
///
/// Va una sola vez, sobre los providers de los repositorios.
class LanguageContentSync extends StatefulWidget {
  const LanguageContentSync({super.key, required this.child});

  final Widget child;

  @override
  State<LanguageContentSync> createState() => _LanguageContentSyncState();
}

class _LanguageContentSyncState extends State<LanguageContentSync> {
  @override
  void initState() {
    super.initState();
    AppStrings.changes.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    AppStrings.changes.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    unawaited(context.read<CircuitCollectionsRepository>().relocalize());
    unawaited(context.read<GroupSessionRepository>().relocalize());
    unawaited(context.read<GuideWorkRepository>().relocalize());
    unawaited(context.read<TouristRepository>().relocalize());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
