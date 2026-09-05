import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_request.dart';

/// Lo que armó el turista: precio calculado, horas del servicio, qué tipo
/// de guía y/o traductor pidió, quién pone el transporte y si incluye
/// alojamiento para el guía. El tiempo límite de la publicación siempre es
/// fijo (24h), como una oferta de trabajo.
typedef GuideRequestSelection = ({
  num price,
  Duration timeLimit,
  GuideTier guideTier,
  bool includeTranslator,
  int serviceHours,
  TransportOption transportOption,
  bool touristProvidesLodging,
  String? touristLanguage,
});

/// La solicitud queda publicada 24h, como una oferta de trabajo, sin que el
/// turista elija un tiempo límite más corto.
const _searchTimeLimit = Duration(hours: 24);

/// Más de un día de servicio: a partir de ahí se pregunta por alojamiento.
const _multiDayThresholdHours = 24;

/// Paso del stepper de horas.
const _hoursStep = 1;

/// Idiomas que puede pedir el turista para un guía bilingüe o un traductor.
const _touristLanguages = ['Inglés', 'Francés', 'Alemán', 'Portugués', 'Italiano'];

/// Mínimo de horas reservables: más de 4h si hay guía, más de 2h si sólo
/// hay traductor.
int _minHours(GuideTier tier, bool includeTranslator) {
  if (tier != GuideTier.none) return 5;
  if (includeTranslator) return 3;
  return 1;
}

/// Tarifa por hora según lo que se pida, en vez de un múltiplo del precio
/// del circuito: esto ahora es un servicio aparte, cobrado por horas.
num _hourlyRate(GuideTier tier, bool includeTranslator) {
  return switch ((tier, includeTranslator)) {
    (GuideTier.bilingual, _) => 200,
    (GuideTier.local, true) => 210,
    (GuideTier.local, false) => 140,
    (GuideTier.none, true) => 90,
    (GuideTier.none, false) => 0,
  };
}

/// Precio total: tarifa por hora × horas, más el extra si el guía pone el
/// transporte, menos el descuento si el turista le da alojamiento al guía.
num _calculatePrice({
  required GuideTier tier,
  required bool includeTranslator,
  required int hours,
  required TransportOption transport,
  required bool touristProvidesLodging,
}) {
  var price = _hourlyRate(tier, includeTranslator) * hours;
  if (tier != GuideTier.none && transport == TransportOption.guideProvides) {
    price *= 1.15;
  }
  if (tier != GuideTier.none &&
      hours > _multiDayThresholdHours &&
      touristProvidesLodging) {
    price *= 0.90;
  }
  return price.round();
}

/// Hoja para armar la solicitud: como publicar una oferta de trabajo — se
/// elige qué se necesita, por cuántas horas, quién pone el transporte y (si
/// dura más de un día) si se incluye alojamiento para el guía. El precio se
/// calcula solo y la publicación queda abierta 24h.
Future<GuideRequestSelection?> showGuideRequestSheet(BuildContext context) {
  return showModalBottomSheet<GuideRequestSelection>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _GuideRequestSheet(),
  );
}

class _GuideRequestSheet extends StatefulWidget {
  const _GuideRequestSheet();

  @override
  State<_GuideRequestSheet> createState() => _GuideRequestSheetState();
}

class _GuideRequestSheetState extends State<_GuideRequestSheet> {
  GuideTier _guideTier = GuideTier.local;
  bool _includeTranslator = false;
  String _touristLanguage = _touristLanguages.first;
  late int _hours = _minHours(_guideTier, _includeTranslator);
  TransportOption _transport = TransportOption.onFoot;
  bool _touristProvidesLodging = false;

  bool get _needsLanguage =>
      _guideTier == GuideTier.bilingual || _includeTranslator;

  bool get _canSubmit =>
      _guideTier != GuideTier.none || _includeTranslator;

  bool get _hasGuide => _guideTier != GuideTier.none;

  bool get _isMultiDay => _hours > _multiDayThresholdHours;

  num get _price => _calculatePrice(
    tier: _guideTier,
    includeTranslator: _includeTranslator,
    hours: _hours,
    transport: _transport,
    touristProvidesLodging: _touristProvidesLodging,
  );

  /// Sube las horas al nuevo mínimo si quedaron por debajo al cambiar el
  /// tier o el traductor.
  void _clampHours() {
    final min = _minHours(_guideTier, _includeTranslator);
    if (_hours < min) _hours = min;
  }

  void _setGuideTier(GuideTier tier) {
    setState(() {
      _guideTier = tier;
      // Un guía bilingüe ya cubre la traducción: el traductor aparte deja
      // de tener sentido.
      if (tier == GuideTier.bilingual) _includeTranslator = false;
      // Sin guía no tiene sentido elegir transporte ni alojamiento.
      if (tier == GuideTier.none) {
        _transport = TransportOption.onFoot;
        _touristProvidesLodging = false;
      }
      _clampHours();
    });
  }

  void _setIncludeTranslator(bool value) {
    setState(() {
      _includeTranslator = value;
      _clampHours();
    });
  }

  void _setHours(int value) {
    final min = _minHours(_guideTier, _includeTranslator);
    if (value < min) return;
    setState(() {
      _hours = value;
      if (!_isMultiDay) _touristProvidesLodging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Solicitar guía o traductor', style: AppTextStyles.title),
              const SizedBox(height: 4),
              Text(
                'Publica lo que necesitas, como una oferta: queda abierta '
                '24 horas hasta que alguien la tome.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 20),
              Text('Tipo de guía', style: AppTextStyles.body),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tierChip('Sin guía', GuideTier.none),
                  _tierChip('Guía local', GuideTier.local),
                  _tierChip('Guía + mi idioma', GuideTier.bilingual),
                ],
              ),
              if (_guideTier != GuideTier.bilingual) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _includeTranslator,
                  onChanged: (value) => _setIncludeTranslator(value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary30,
                  title: Text('Agregar traductor', style: AppTextStyles.body),
                ),
              ],
              if (_needsLanguage) ...[
                const SizedBox(height: 4),
                Text('Tu idioma', style: AppTextStyles.body),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _touristLanguage,
                  items: [
                    for (final language in _touristLanguages)
                      DropdownMenuItem(value: language, child: Text(language)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _touristLanguage = value);
                  },
                ),
              ],
              const SizedBox(height: 20),
              Text('Duración del servicio', style: AppTextStyles.body),
              const SizedBox(height: 2),
              Text(
                _hasGuide
                    ? 'Mínimo 5 horas con guía.'
                    : 'Mínimo 3 horas sólo con traductor.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 8),
              _HoursStepper(
                hours: _hours,
                minHours: _minHours(_guideTier, _includeTranslator),
                onChanged: _setHours,
              ),
              if (_hasGuide) ...[
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
              ],
              if (_hasGuide && _isMultiDay) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _touristProvidesLodging,
                  onChanged: (value) =>
                      setState(() => _touristProvidesLodging = value ?? false),
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
              Text('Precio estimado', style: AppTextStyles.body),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary30.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  Formatters.currency(_price),
                  style: AppTextStyles.title,
                ),
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
                      onPressed: _canSubmit
                          ? () => Navigator.of(context).pop((
                              price: _price,
                              timeLimit: _searchTimeLimit,
                              guideTier: _guideTier,
                              includeTranslator: _includeTranslator,
                              serviceHours: _hours,
                              transportOption: _transport,
                              touristProvidesLodging:
                                  _isMultiDay && _touristProvidesLodging,
                              touristLanguage: _needsLanguage
                                  ? _touristLanguage
                                  : null,
                            ))
                          : null,
                      child: const Text('Publicar solicitud'),
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

  Widget _tierChip(String label, GuideTier tier) {
    final selected = _guideTier == tier;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary30,
      labelStyle: AppTextStyles.caption.copyWith(
        color: selected ? AppColors.white : AppColors.primaryText,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: selected ? AppColors.primary30 : AppColors.divider),
      onSelected: (_) => _setGuideTier(tier),
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
      side: BorderSide(color: selected ? AppColors.primary30 : AppColors.divider),
      onSelected: (_) => setState(() => _transport = option),
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
          onPressed: hours <= minHours
              ? null
              : () => onChanged(hours - _hoursStep),
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
          onPressed: () => onChanged(hours + _hoursStep),
        ),
      ],
    );
  }
}
