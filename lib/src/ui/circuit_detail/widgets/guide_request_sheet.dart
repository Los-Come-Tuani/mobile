import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_request.dart';

/// Lo que armó el turista: precio ofrecido, tiempo límite de búsqueda y qué
/// tipo de guía y/o traductor pidió.
typedef GuideRequestSelection = ({
  num price,
  Duration timeLimit,
  GuideTier guideTier,
  bool includeTranslator,
  String? touristLanguage,
});

/// Pasos del contador de precio.
const _priceStep = 25;

/// Opciones de tiempo límite de búsqueda.
const _timeLimitOptions = [
  Duration(minutes: 3),
  Duration(minutes: 5),
  Duration(minutes: 10),
];

/// Idiomas que puede pedir el turista para un guía bilingüe o un traductor.
const _touristLanguages = ['Inglés', 'Francés', 'Alemán', 'Portugués', 'Italiano'];

/// Multiplicador sobre el precio adulto del circuito, según lo que se pida.
double _priceMultiplier(GuideTier tier, bool includeTranslator) {
  return switch ((tier, includeTranslator)) {
    (GuideTier.bilingual, _) => 1.6,
    (GuideTier.local, true) => 1.4,
    (GuideTier.none, true) => 0.8,
    (GuideTier.local, false) => 1.0,
    (GuideTier.none, false) => 1.0,
  };
}

/// Hoja para armar la solicitud: precio ofrecido (como la tarifa de
/// inDrive), tiempo límite de búsqueda, y tipo de guía y/o traductor.
Future<GuideRequestSelection?> showGuideRequestSheet(
  BuildContext context, {
  required num suggestedPrice,
}) {
  return showModalBottomSheet<GuideRequestSelection>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _GuideRequestSheet(suggestedPrice: suggestedPrice),
  );
}

class _GuideRequestSheet extends StatefulWidget {
  const _GuideRequestSheet({required this.suggestedPrice});

  final num suggestedPrice;

  @override
  State<_GuideRequestSheet> createState() => _GuideRequestSheetState();
}

class _GuideRequestSheetState extends State<_GuideRequestSheet> {
  late num _price = widget.suggestedPrice;
  Duration _timeLimit = _timeLimitOptions.first;
  GuideTier _guideTier = GuideTier.local;
  bool _includeTranslator = false;
  String _touristLanguage = _touristLanguages.first;

  bool get _needsLanguage =>
      _guideTier == GuideTier.bilingual || _includeTranslator;

  bool get _canSubmit =>
      _guideTier != GuideTier.none || _includeTranslator;

  void _setGuideTier(GuideTier tier) {
    setState(() {
      _guideTier = tier;
      // Un guía bilingüe ya cubre la traducción: el traductor aparte deja
      // de tener sentido.
      if (tier == GuideTier.bilingual) _includeTranslator = false;
      _price = (widget.suggestedPrice * _priceMultiplier(tier, _includeTranslator))
          .round();
    });
  }

  void _setIncludeTranslator(bool value) {
    setState(() {
      _includeTranslator = value;
      _price = (widget.suggestedPrice * _priceMultiplier(_guideTier, value))
          .round();
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
                'Elige qué necesitas, ofrece un precio y cuánto tiempo '
                'buscar.',
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
              Text('Precio que ofreces', style: AppTextStyles.body),
              const SizedBox(height: 8),
              _PriceStepper(
                price: _price,
                onChanged: (value) => setState(() => _price = value),
              ),
              const SizedBox(height: 20),
              Text('Tiempo límite de búsqueda', style: AppTextStyles.body),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in _timeLimitOptions)
                    ChoiceChip(
                      label: Text('${option.inMinutes} min'),
                      selected: _timeLimit == option,
                      selectedColor: AppColors.primary30,
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: _timeLimit == option
                            ? AppColors.white
                            : AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: _timeLimit == option
                            ? AppColors.primary30
                            : AppColors.divider,
                      ),
                      onSelected: (_) => setState(() => _timeLimit = option),
                    ),
                ],
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
                              timeLimit: _timeLimit,
                              guideTier: _guideTier,
                              includeTranslator: _includeTranslator,
                              touristLanguage: _needsLanguage
                                  ? _touristLanguage
                                  : null,
                            ))
                          : null,
                      child: const Text('Buscar'),
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
}

class _PriceStepper extends StatelessWidget {
  const _PriceStepper({required this.price, required this.onChanged});

  final num price;
  final ValueChanged<num> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.primary30,
          onPressed: price <= _priceStep
              ? null
              : () => onChanged(price - _priceStep),
        ),
        Expanded(
          child: Text(
            Formatters.currency(price),
            textAlign: TextAlign.center,
            style: AppTextStyles.title,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primary30,
          onPressed: () => onChanged(price + _priceStep),
        ),
      ],
    );
  }
}
