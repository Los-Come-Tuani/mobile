import '../../../../core/utils/result.dart';
import '../../../../data/datasources/repository/guide_access_repository.dart';
import '../../../../data/models/guide_access_request.dart';
import '../../../../data/models/provider.dart';
import '../../../core/base_viewmodel.dart';

/// Lo descriptivo del perfil del guía: la foto, la presentación, el teléfono y los
/// idiomas. Se ve de inmediato y no pasa por la revisión (RF-P-06).
class GuideProfileEditViewModel extends BaseViewModel {
  GuideProfileEditViewModel(this._access) {
    final self = _access.self;
    if (self != null) {
      presentation = self.presentation;
      phone = self.phone;
      for (final language in self.languages) {
        _languages[language.code] = language.level;
      }
    }
    _load();
  }

  static const photoExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const maxPhotoBytes = 5 * 1024 * 1024;

  final GuideAccessRepository _access;

  ProviderCatalogs? _catalogs;
  List<CatalogOption> get languageOptions => _catalogs?.languages ?? const [];

  String presentation = '';
  String phone = '';

  final Map<String, String> _languages = {};

  bool isSelected(String code) => _languages.containsKey(code);

  void toggleLanguage(String code) {
    if (_languages.remove(code) == null) {
      _languages[code] = code == 'es' ? 'native' : 'advanced';
    }
    safeNotify();
  }

  GuideDocument? _photo;
  GuideDocument? get photo => _photo;
  String? get currentPhotoUrl => _access.self?.photoUrl;

  void setPhoto(GuideDocument file) {
    _photo = file;
    safeNotify();
  }

  /// Por qué no sirve una foto, o `null` si sirve.
  static String? photoProblem({required String name, int? sizeBytes}) {
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    if (!photoExtensions.contains(extension)) {
      return 'Elige una foto JPG, PNG o WEBP.';
    }
    if (sizeBytes != null && sizeBytes > maxPhotoBytes) {
      return 'La foto pesa más de 5 MB. Elige una más liviana.';
    }
    return null;
  }

  Future<void> _load() async {
    if (await _access.catalogs() case Ok(:final value)) _catalogs = value;
    safeNotify();
  }

  /// `true` si se guardó.
  Future<bool> save() async {
    if (_languages.isEmpty) {
      setError('Elige al menos un idioma');
      return false;
    }
    clearError();
    setBusy(true);
    final result = await _access.updateProfile(
      presentation: presentation.trim(),
      phone: phone.trim(),
      languages: [
        for (final entry in _languages.entries)
          ProviderLanguage(code: entry.key, level: entry.value),
      ],
      photo: _photo,
    );
    setBusy(false);
    switch (result) {
      case Ok():
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }
}
