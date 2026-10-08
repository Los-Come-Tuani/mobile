import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/guide_repository.dart';
import '../../../data/models/tour_guide.dart';
import '../../core/base_viewmodel.dart';

/// Qué servicio se busca en la lista de guías.
enum GuideServiceFilter {
  all,
  guide,
  translator;

  /// El código que espera `GET /guide/?service=`.
  String? get apiCode => switch (this) {
    all => null,
    guide => 'guia',
    translator => 'traductor',
  };

  bool matches(TourGuide guide) => switch (this) {
    all => true,
    GuideServiceFilter.guide => guide.role.canGuide,
    translator => guide.role.canTranslate,
  };
}

/// Los guías y traductores aprobados, de mejor a peor calificados.
class GuidesViewModel extends BaseViewModel {
  GuidesViewModel(this._guideRepository);

  final GuideRepository _guideRepository;

  List<TourGuide> _guides = const [];
  GuideServiceFilter _filter = GuideServiceFilter.all;

  GuideServiceFilter get filter => _filter;

  /// La demo no filtra en el repositorio: se filtra aquí también.
  List<TourGuide> get guides =>
      _guides.where(_filter.matches).toList(growable: false);

  Future<void> load() async {
    setBusy(true);
    clearError();
    switch (await _guideRepository.getGuides(service: _filter.apiCode)) {
      case Ok(:final value):
        _guides = value;
      case Failure(:final message):
        setError(message);
    }
    setBusy(false);
  }

  Future<void> setFilter(GuideServiceFilter value) async {
    if (value == _filter) return;
    _filter = value;
    await load();
  }
}
