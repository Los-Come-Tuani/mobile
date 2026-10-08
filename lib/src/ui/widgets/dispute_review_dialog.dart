import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/utils/result.dart';
import '../../data/datasources/repository/bookings_repository.dart';
import 'app_dialog.dart';

/// Pide el motivo (10 caracteres o más) para que el equipo revise la reseña
/// [reviewId] que recibió quien pregunta, y la manda al API. Avisa cómo salió.
Future<void> disputeReview(BuildContext context, String reviewId) async {
  final l10n = context.l10n;
  final bookings = context.read<BookingsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final reason = await showTextInputDialog(
    context,
    title: l10n.reviewDisputeTitle,
    hint: l10n.reviewDisputeHint,
    confirmLabel: l10n.reviewDisputeSend,
    emptyMessage: l10n.reviewDisputeTooShort,
    validator: (value) =>
        (value ?? '').trim().length < 10 ? l10n.reviewDisputeTooShort : null,
  );
  if (reason == null) return;
  final result = await bookings.disputeReview(reviewId, reason);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok() => l10n.reviewDisputeSent,
          Failure(:final message) => message,
        }),
      ),
    );
}
