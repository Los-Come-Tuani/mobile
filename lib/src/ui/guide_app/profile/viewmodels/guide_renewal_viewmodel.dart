import '../../../../core/utils/result.dart';
import '../../../../data/datasources/repository/guide_access_repository.dart';
import '../../../../data/models/guide_access_request.dart';
import '../../../../data/models/provider.dart';
import '../../../core/base_viewmodel.dart';
import '../../../guide_access/viewmodels/guide_application_viewmodel.dart';

/// Renovar un documento: el archivo nuevo con su número y sus fechas. Mientras se
/// revisa, el anterior sigue en vigor y el guía sigue trabajando.
class GuideRenewalViewModel extends BaseViewModel {
  GuideRenewalViewModel(this._access, {String? typeCode})
    : _typeCode = typeCode {
    _load();
  }

  final GuideAccessRepository _access;

  ProviderCatalogs? _catalogs;

  /// Los tipos que se le piden: los únicos que se renuevan.
  List<CredentialType> get types {
    final self = _access.self;
    final catalogs = _catalogs;
    if (self == null || catalogs == null) return const [];
    return CredentialType.requiredFor(
      catalogs.credentialTypes,
      services: self.services,
      carriesTourists: self.carriesTourists,
    );
  }

  String? _typeCode;
  String? get typeCode => _typeCode;

  CredentialType? get type =>
      types.where((item) => item.code == _typeCode).firstOrNull;

  void setType(String? code) {
    _typeCode = code;
    safeNotify();
  }

  final DocumentForm form = DocumentForm();

  bool _tried = false;

  Future<void> _load() async {
    if (_access.self == null) await _access.refresh();
    if (await _access.catalogs() case Ok(:final value)) _catalogs = value;
    if (_typeCode == null && types.isNotEmpty) _typeCode = types.first.code;
    safeNotify();
  }

  void attach(GuideDocument file) {
    form.file = file;
    safeNotify();
  }

  void removeFile() {
    form.file = null;
    safeNotify();
  }

  void setNumber(String value) => form.number = value;

  void setIssuedOn(DateTime date) {
    form.issuedOn = date;
    safeNotify();
  }

  void setExpiresOn(DateTime date) {
    form.expiresOn = date;
    safeNotify();
  }

  /// Lo que falta o está mal, después de intentar enviar.
  String? get problem {
    final type = this.type;
    if (!_tried || type == null) return null;
    final day = DateTime.now();
    if (form.file == null) return 'Adjunta el archivo';
    if (form.number.trim().isEmpty) return 'Escribe el número del documento';
    final issued = form.issuedOn;
    if (issued == null) return 'Elige la fecha de emisión';
    if (issued.isAfter(day)) return 'La fecha de emisión no puede ser futura';
    final expires = form.expiresOn;
    if (type.requiresExpiry && expires == null) {
      return 'Elige la fecha de vencimiento';
    }
    if (expires != null && !expires.isAfter(issued)) {
      return 'El vencimiento tiene que ser posterior a la emisión';
    }
    if (expires != null && !expires.isAfter(day)) {
      return 'El documento ya venció: sube uno vigente';
    }
    return null;
  }

  /// `true` si la renovación quedó enviada.
  Future<bool> submit() async {
    _tried = true;
    final type = this.type;
    if (type == null || problem != null) {
      safeNotify();
      return false;
    }
    clearError();
    setBusy(true);
    final result = await _access.renew([
      DocumentDraft(
        typeCode: type.code,
        number: form.number,
        issuedOn: form.issuedOn!,
        expiresOn: form.expiresOn,
        file: form.file!,
      ),
    ]);
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
