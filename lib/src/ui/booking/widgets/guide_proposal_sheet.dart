import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_request.dart';

/// Idiomas que puede pedir el turista para un guía bilingüe o un traductor.
const _touristLanguages = [
  'Inglés',
  'Francés',
  'Alemán',
  'Portugués',
  'Italiano',
];

/// Hoja para armar la propuesta de trabajo que verán los guías: qué se
/// necesita, por cuántas horas, quién pone el transporte y (si dura más de
/// un día) si se incluye alojamiento para el guía. El presupuesto se calcula
/// solo; cada guía lo acepta o propone su precio al postularse.
///
/// Sin propuesta previa, arranca con las horas que cubren el itinerario
/// ([suggestedHours]) y, si el recorrido pide vehículo ([requiresVehicle]),
/// con el guía poniendo el transporte.
///
/// Devuelve las condiciones elegidas, o `null` si el turista cerró sin
/// guardar.
Future<GuideRequestTerms?> showGuideProposalSheet(
  BuildContext context, {
  GuideRequestTerms? initial,
  int suggestedHours = 0,
  Duration? itineraryDuration,
  bool requiresVehicle = false,
}) {
  return showModalBottomSheet<GuideRequestTerms>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _GuideProposalSheet(
      initial: initial,
      suggestedHours: suggestedHours,
      itineraryDuration: itineraryDuration,
      requiresVehicle: requiresVehicle,
    ),
  );
}

class _GuideProposalSheet extends StatefulWidget {
  const _GuideProposalSheet({
    this.initial,
    required this.suggestedHours,
    required this.itineraryDuration,
    required this.requiresVehicle,
  });

  final GuideRequestTerms? initial;
  final int suggestedHours;
  final Duration? itineraryDuration;
  final bool requiresVehicle;

  @override
  State<_GuideProposalSheet> createState() => _GuideProposalSheetState();
}

class _GuideProposalSheetState extends State<_GuideProposalSheet> {
  late GuideNeed _need = widget.initial?.need ?? GuideNeed.localGuide;
  late String _language =
      widget.initial?.touristLanguage ?? _touristLanguages.first;
  late int _hours =
      widget.initial?.serviceHours ??
      math.max(_need.minServiceHours, widget.suggestedHours);
  late TransportOption _transport =
      widget.initial?.transportOption ??
      (widget.requiresVehicle
          ? TransportOption.guideProvides
          : TransportOption.onFoot);
  late bool _lodging = widget.initial?.touristProvidesLodging ?? false;

  GuideRequestTerms get _terms => GuideRequestTerms(
    need: _need,
    serviceHours: _hours,
    touristLanguage: _need.needsTouristLanguage ? _language : null,
    transportOption: _need.needsGuide ? _transport : TransportOption.onFoot,
    touristProvidesLodging:
        _need.needsGuide &&
        _hours > GuideRequestTerms.multiDayThresholdHours &&
        _lodging,
  );

  void _setNeed(GuideNeed need) {
    setState(() {
      _need = need;
      // Sube las horas al nuevo mínimo si quedaron por debajo.
      if (_hours < need.minServiceHours) _hours = need.minServiceHours;
    });
  }

  void _setHours(int value) {
    if (value < _need.minServiceHours) return;
    setState(() => _hours = value);
  }

  @override
  Widget build(BuildContext context) {
    final terms = _terms;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Propuesta para guía o traductor',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 4),
              Text(
                'Los guías verán tu propuesta y se postularán. Tú revisas sus '
                'perfiles y eliges a quién contratar.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 20),
              Text('¿Qué necesitas?', style: AppTextStyles.body),
              const SizedBox(height: 8),
              for (final need in GuideNeed.values) ...[
                _NeedOption(
                  need: need,
                  selected: _need == need,
                  onTap: () => _setNeed(need),
                ),
                const SizedBox(height: 8),
              ],
              if (_need.needsTouristLanguage) ...[
                const SizedBox(height: 8),
                Text('Tu idioma', style: AppTextStyles.body),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _language,
                  items: [
                    for (final language in _touristLanguages)
                      DropdownMenuItem(value: language, child: Text(language)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _language = value);
                  },
                ),
              ],
              const SizedBox(height: 20),
              Text('Duración del servicio', style: AppTextStyles.body),
              const SizedBox(height: 2),
              Text(
                [
                  _need.needsGuide
                      ? 'Mínimo ${_need.minServiceHours} horas con guía.'
                      : 'Mínimo ${_need.minServiceHours} horas sólo con '
                            'traductor.',
                  if (widget.itineraryDuration case final duration?)
                    'Tu itinerario dura ${Formatters.duration(duration)}.',
                ].join(' '),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 8),
              _HoursStepper(
                hours: _hours,
                minHours: _need.minServiceHours,
                onChanged: _setHours,
              ),
              if (_need.needsGuide) ...[
                const SizedBox(height: 20),
                Text('Transporte', style: AppTextStyles.body),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _transportChip('A pie', TransportOption.onFoot),
                    _transportChip(
                      'Yo pongo el transporte',
                      TransportOption.touristProvides,
                    ),
                    _transportChip(
                      'Que lo ponga el guía',
                      TransportOption.guideProvides,
                    ),
                  ],
                ),
                if (widget.requiresVehicle &&
                    _transport == TransportOption.onFoot) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.star,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Este recorrido se hace en vehículo: a pie hay '
                          'tramos muy largos y el día no alcanza.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              if (_need.needsGuide && terms.isMultiDay) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _lodging,
                  onChanged: (value) =>
                      setState(() => _lodging = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary30,
                  title: Text(
                    '¿Le darás alojamiento al guía?',
                    style: AppTextStyles.body,
                  ),
                  subtitle: Text(
                    'Más de un día de recorrido: si le das alojamiento, el '
                    'precio baja.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('Presupuesto que ofreces', style: AppTextStyles.body),
              const SizedBox(height: 8),
              _BudgetBox(terms: terms),
              const SizedBox(height: 6),
              Text(
                'Cada guía lo acepta o propone su precio al postularse.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(terms),
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transportChip(String label, TransportOption option) {
    final selected = _transport == option;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary30,
      labelStyle: AppTextStyles.caption.copyWith(
        color: selected ? AppColors.white : AppColors.primaryText,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary30 : AppColors.divider,
      ),
      onSelected: (_) => setState(() => _transport = option),
    );
  }
}

/// Una de las formas de conseguir quién te acompañe en el recorrido.
class _NeedOption extends StatelessWidget {
  const _NeedOption({
    required this.need,
    required this.selected,
    required this.onTap,
  });

  final GuideNeed need;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (need) {
      GuideNeed.localGuide => (
        Icons.person_pin_circle_outlined,
        'Guía local',
        'Te da el recorrido en español.',
      ),
      GuideNeed.bilingualGuide => (
        Icons.record_voice_over_outlined,
        'Guía que habla tu idioma',
        'Te explica todo el recorrido en tu idioma.',
      ),
      GuideNeed.localGuideAndTranslator => (
        Icons.groups_outlined,
        'Guía local + traductor',
        'Un guía local y alguien que te traduce en el momento.',
      ),
      GuideNeed.translatorOnly => (
        Icons.translate,
        'Solo traductor',
        'Recorres por tu cuenta con alguien que te traduce.',
      ),
    };

    return Material(
      color: selected
          ? AppColors.primary30.withValues(alpha: 0.06)
          : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(
          color: selected ? AppColors.primary30 : AppColors.divider,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary30 : AppColors.hintText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Presupuesto total y, si se piden guía y traductor, cuánto va a cada uno.
class _BudgetBox extends StatelessWidget {
  const _BudgetBox({required this.terms});

  final GuideRequestTerms terms;

  @override
  Widget build(BuildContext context) {
    final bothRoles = terms.need.needsGuide && terms.need.needsTranslator;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary30.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: bothRoles
          ? Column(
              children: [
                _BudgetLine(label: 'Guía', amount: terms.guideBudget),
                _BudgetLine(label: 'Traductor', amount: terms.translatorBudget),
                const Divider(height: 16, color: AppColors.divider),
                _BudgetLine(label: 'Total', amount: terms.budget, bold: true),
              ],
            )
          : Text(
              Formatters.currency(terms.budget),
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
    );
  }
}

class _BudgetLine extends StatelessWidget {
  const _BudgetLine({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  final String label;
  final num amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTextStyles.title : AppTextStyles.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(Formatters.currency(amount), style: style),
        ],
      ),
    );
  }
}

class _HoursStepper extends StatelessWidget {
  const _HoursStepper({
    required this.hours,
    required this.minHours,
    required this.onChanged,
  });

  final int hours;
  final int minHours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.primary30,
          tooltip: 'Menos horas',
          onPressed: hours <= minHours ? null : () => onChanged(hours - 1),
        ),
        Expanded(
          child: Text(
            '$hours h',
            textAlign: TextAlign.center,
            style: AppTextStyles.title,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primary30,
          tooltip: 'Más horas',
          onPressed: () => onChanged(hours + 1),
        ),
      ],
    );
  }
}
