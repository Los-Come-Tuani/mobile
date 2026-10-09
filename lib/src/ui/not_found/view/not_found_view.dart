import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';

/// Una dirección que la app no conoce (un enlace viejo o incompleto): en vez
/// del error del router, una salida al inicio.
class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          title: l10n.commonNotFoundTitle,
          message: l10n.commonNotFoundMessage,
          action: const BackToHomeButton(outlined: true),
        ),
      ),
    );
  }
}
