import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/group_session_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_group_session.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/remote_image.dart';

/// Hoja con las salidas de grupo programadas por la alcaldía para un
/// circuito creativo. Devuelve la sesión a la que se unió el turista, o
/// `null` si cerró sin unirse.
Future<CircuitGroupSession?> showGroupSessionsSheet(
  BuildContext context, {
  required Circuit circuit,
}) {
  final repository = context.read<GroupSessionRepository>();

  return showModalBottomSheet<CircuitGroupSession>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ChangeNotifierProvider.value(
      value: repository,
      child: _GroupSessionsSheet(circuit: circuit),
    ),
  );
}

class _GroupSessionsSheet extends StatefulWidget {
  const _GroupSessionsSheet({required this.circuit});

  final Circuit circuit;

  @override
  State<_GroupSessionsSheet> createState() => _GroupSessionsSheetState();
}

class _GroupSessionsSheetState extends State<_GroupSessionsSheet> {
  bool _loading = true;
  String? _error;
  List<CircuitGroupSession> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    final repository = context.read<GroupSessionRepository>();
    switch (await repository.getSessionsForCircuit(widget.circuit.id)) {
      case Ok(:final value):
        _sessions = value;
        _error = null;
      case Failure(:final message):
        _error = message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _join(CircuitGroupSession session) async {
    final joined = context.read<GroupSessionRepository>().join(session.id);
    if (!joined) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Ese cupo ya no está disponible')),
        );
      return;
    }

    await _load();
    if (!mounted) return;

    final updated = _sessions.firstWhere(
      (s) => s.id == session.id,
      orElse: () => session,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<GroupSessionRepository>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unirte a un grupo', style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(
              'Salidas programadas por ${widget.circuit.organizer}, con '
              'guía municipal incluido.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary30),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(_error!, style: AppTextStyles.bodySmall),
              )
            else if (_sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No hay salidas programadas por ahora.',
                  style: AppTextStyles.bodySmall,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _sessions.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 20,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) => _SessionTile(
                    session: _sessions[index],
                    alreadyJoined: repository.hasJoined(_sessions[index].id),
                    onJoin: () => _join(_sessions[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.alreadyJoined,
    required this.onJoin,
  });

  final CircuitGroupSession session;
  final bool alreadyJoined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${Formatters.shortDate(session.date)} · ${session.startTime}',
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ClipOval(
                    child: RemoteImage(
                      url: session.guidePhotoUrl,
                      height: 28,
                      width: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      session.guideName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 6),
                  RatingStars(
                    rating: session.guideRating,
                    starSize: 12,
                    showValue: false,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                session.isFull
                    ? 'Sin cupo'
                    : '${session.joinedCount}/${session.capacity} cupos',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: alreadyJoined || session.isFull ? null : onJoin,
          child: Text(
            alreadyJoined ? 'Unido' : (session.isFull ? 'Lleno' : 'Unirme'),
          ),
        ),
      ],
    );
  }
}
