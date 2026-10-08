import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/datasources/repository/circuit_collections_repository.dart';

/// Avisa cuando un circuito del turista no se pudo guardar en su cuenta (o traer de
/// ella). Lo que ve en pantalla no cambia: el aviso solo cuenta que no llegó al API.
///
/// Va una sola vez, sobre la app: los circuitos se cambian desde muchas pantallas y el
/// aviso puede llegar cuando ya salió de la que hizo el cambio.
class CollectionSyncNotices extends StatefulWidget {
  const CollectionSyncNotices({
    super.key,
    required this.messengerKey,
    required this.child,
  });

  /// El `scaffoldMessengerKey` de la app.
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<CollectionSyncNotices> createState() => _CollectionSyncNoticesState();
}

class _CollectionSyncNoticesState extends State<CollectionSyncNotices> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = context
        .read<CircuitCollectionsRepository>()
        .syncErrors
        .listen(_show);
  }

  void _show(String message) {
    widget.messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
