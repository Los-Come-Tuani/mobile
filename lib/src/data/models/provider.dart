import 'guide_access_request.dart';

/// Guías y traductores (F5), con la forma que entrega el API (`docs/prestadores.md` del
/// repo del API): el perfil del prestador, sus documentos y su expediente.

/// Lo que ofrece: `guia`, `traductor` o los dos.
abstract final class ProviderServices {
  static const guide = 'guia';
  static const translator = 'traductor';

  /// "Guía", "Traductor" o "Guía y traductor".
  static String label(List<String> services) {
    final guides = services.contains(guide);
    final translates = services.contains(translator);
    if (guides && translates) return 'Guía y traductor';
    return translates ? 'Traductor' : 'Guía';
  }
}

/// En qué está el perfil: solo `active` aparece para el turista; `suspended` entra a la
/// app para renovar lo que venció.
enum ProviderStatus {
  unaccredited,
  inReview,
  active,
  suspended;

  static ProviderStatus fromApi(String? value) => switch (value) {
    'in_review' => inReview,
    'active' => active,
    'suspended' => suspended,
    _ => unaccredited,
  };

  /// Ya lo aprobaron: entra a la app del guía (suspendido, para regularizar).
  bool get isApproved => this == active || this == suspended;
}

/// El perfil de prestador que trae la sesión.
class ProviderRef {
  const ProviderRef({
    required this.id,
    required this.status,
    required this.services,
  });

  final String id;
  final ProviderStatus status;
  final List<String> services;

  static ProviderRef? fromApi(Object? json) {
    if (json is! Map) return null;
    return ProviderRef(
      id: '${json['id'] ?? ''}',
      status: ProviderStatus.fromApi(json['status'] as String?),
      services: [for (final item in json['services'] as List? ?? []) '$item'],
    );
  }
}

/// Una opción de una lista cerrada (ciudad, idioma).
class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.code,
    required this.label,
  });

  final String id;
  final String code;
  final String label;
}

/// Un documento que se le puede pedir a un guía o traductor.
class CredentialType {
  const CredentialType({
    required this.code,
    required this.label,
    this.service,
    this.requiresExpiry = true,
    this.requiresVehicle = false,
  });

  final String code;
  final String label;

  /// El servicio que acredita; nulo si se le pide a todos.
  final String? service;
  final bool requiresExpiry;

  /// Se le pide a quien lleva turistas en su vehículo.
  final bool requiresVehicle;

  factory CredentialType.fromApi(Map<String, dynamic> json) => CredentialType(
    code: '${json['code']}',
    label: '${json['label']}',
    service: json['service'] as String?,
    requiresExpiry: json['requires_expiry'] == true,
    requiresVehicle: json['requires_vehicle'] == true,
  );

  /// Los que se le piden: los de todos, los del servicio que ofrece y los de vehículo si
  /// lleva turistas en el suyo.
  static List<CredentialType> requiredFor(
    List<CredentialType> types, {
    required List<String> services,
    required bool carriesTourists,
  }) => [
    for (final type in types)
      if ((type.service == null || services.contains(type.service)) &&
          (!type.requiresVehicle || carriesTourists))
        type,
  ];

  /// La lista que siembra el API, para la demo.
  static const demo = [
    CredentialType(code: 'cedula', label: 'Cédula de identidad'),
    CredentialType(
      code: 'record_policia',
      label: 'Récord de policía',
      requiresExpiry: false,
    ),
    CredentialType(
      code: 'licencia_intur',
      label: 'Licencia o carné del INTUR',
      service: ProviderServices.guide,
    ),
    CredentialType(
      code: 'certificado_idioma',
      label: 'Certificado de idiomas',
      service: ProviderServices.translator,
      requiresExpiry: false,
    ),
    CredentialType(
      code: 'licencia_conducir',
      label: 'Licencia de conducir',
      requiresVehicle: true,
    ),
    CredentialType(
      code: 'seguro_vehiculo',
      label: 'Seguro del vehículo',
      requiresVehicle: true,
    ),
  ];
}

/// Lo que dijo quien revisó un documento.
class DocumentReview {
  const DocumentReview({required this.accepted, this.reason, this.note = ''});

  final bool accepted;

  /// Por qué se rechazó, como lo dice el equipo.
  final String? reason;
  final String note;
}

enum DocumentStatus {
  uploaded,
  inReview,
  approved,
  rejected,
  expired,
  replaced;

  static DocumentStatus fromApi(String? value) => switch (value) {
    'in_review' => inReview,
    'approved' => approved,
    'rejected' => rejected,
    'expired' => expired,
    'replaced' => replaced,
    _ => uploaded,
  };
}

/// Un documento del prestador con sus fechas y lo que dijo quien lo revisó.
class ProviderDocument {
  const ProviderDocument({
    required this.id,
    required this.typeCode,
    required this.typeLabel,
    required this.number,
    required this.issuedOn,
    required this.status,
    this.expiresOn,
    this.fileKey = '',
    this.review,
  });

  final String id;
  final String typeCode;
  final String typeLabel;
  final String number;
  final DateTime issuedOn;
  final DateTime? expiresOn;
  final String fileKey;
  final DocumentStatus status;
  final DocumentReview? review;

  /// Quien revisó lo rechazó: hay que subir otro.
  bool get isRejected =>
      status == DocumentStatus.rejected || review?.accepted == false;

  factory ProviderDocument.fromApi(Map<String, dynamic> json) {
    final type = json['type'] as Map? ?? const {};
    final review = json['review'];
    final file = json['file'];
    return ProviderDocument(
      id: '${json['id']}',
      typeCode: '${type['code']}',
      typeLabel: '${type['label']}',
      number: '${json['number'] ?? ''}',
      issuedOn: DateTime.parse('${json['issued_on']}'),
      expiresOn: DateTime.tryParse('${json['expires_on'] ?? ''}'),
      fileKey: file is Map ? '${file['key'] ?? ''}' : '',
      status: DocumentStatus.fromApi(json['status'] as String?),
      review: review is Map
          ? DocumentReview(
              accepted: review['accepted'] == true,
              reason: (review['reason'] as Map?)?['label'] as String?,
              note: '${review['note'] ?? ''}',
            )
          : null,
    );
  }
}

/// Un idioma con su nivel (`basic`, `intermediate`, `advanced` o `native`).
class ProviderLanguage {
  const ProviderLanguage({required this.code, required this.level, this.label});

  final String code;
  final String level;
  final String? label;

  Map<String, String> toApi() => {'code': code, 'level': level};

  static const levelLabels = {
    'basic': 'básico',
    'intermediate': 'intermedio',
    'advanced': 'avanzado',
    'native': 'nativo',
  };
}

/// Lo que el prestador declara de sí: lo mismo al postularse y al corregir.
class ProviderProfileData {
  const ProviderProfileData({
    required this.services,
    required this.phone,
    required this.languages,
    this.cityId,
    this.presentation = '',
    this.carriesTourists = false,
  });

  final List<String> services;

  /// Nula es todo el país.
  final String? cityId;
  final String phone;
  final String presentation;
  final List<ProviderLanguage> languages;
  final bool carriesTourists;

  Map<String, Object?> toApi() => {
    'services': services,
    'city_id': cityId,
    'phone': phone,
    'presentation': presentation,
    'languages': [for (final language in languages) language.toApi()],
    'carries_tourists': carriesTourists,
  };

  factory ProviderProfileData.fromApi(Map<String, dynamic> json) =>
      ProviderProfileData(
        services: [for (final item in json['services'] as List? ?? []) '$item'],
        cityId: json['city_id'] as String?,
        phone: '${json['phone'] ?? ''}',
        presentation: '${json['presentation'] ?? ''}',
        languages: [
          for (final item in json['languages'] as List? ?? [])
            ProviderLanguage(
              code: '${(item as Map)['code']}',
              level: '${item['level']}',
            ),
        ],
        carriesTourists: json['carries_tourists'] == true,
      );
}

enum ApplicationStatus {
  submitted,
  inReview,
  approved,
  rejected;

  static ApplicationStatus fromApi(String? value) => switch (value) {
    'in_review' => inReview,
    'approved' => approved,
    'rejected' => rejected,
    _ => submitted,
  };

  bool get isOpen => this == submitted || this == inReview;
}

/// El expediente más reciente del prestador: en qué va y qué hay que corregir.
class ProviderApplication {
  const ProviderApplication({
    required this.id,
    required this.status,
    required this.providerStatus,
    required this.profile,
    required this.documents,
    this.isRenewal = false,
    this.approved,
    this.reason,
    this.note = '',
    this.missing = const [],
    this.everApproved = false,
  });

  final String id;
  final bool isRenewal;
  final ApplicationStatus status;
  final ProviderStatus providerStatus;
  final ProviderProfileData profile;
  final List<ProviderDocument> documents;

  /// Cómo se resolvió; nulo mientras se revisa.
  final bool? approved;
  final String? reason;
  final String note;

  /// Los tipos que se le piden y no tienen un documento utilizable: (código, nombre).
  final List<(String, String)> missing;

  /// Ya lo aprobaron alguna vez: lo que sigue es renovar, no volver a postularse.
  final bool everApproved;

  /// Se puede corregir y volver a enviar desde la app.
  bool get canResubmit =>
      status == ApplicationStatus.rejected && !isRenewal && !everApproved;

  List<ProviderDocument> get rejected => [
    for (final document in documents)
      if (document.isRejected) document,
  ];

  factory ProviderApplication.fromApi(Map<String, dynamic> json) {
    final resolution = json['resolution'];
    final provider = json['provider'] as Map? ?? const {};
    return ProviderApplication(
      id: '${json['id']}',
      isRenewal: json['procedure'] == 'renewal',
      status: ApplicationStatus.fromApi(json['status'] as String?),
      providerStatus: ProviderStatus.fromApi(provider['status'] as String?),
      everApproved: provider['approved_at'] != null,
      profile: ProviderProfileData.fromApi(
        (json['profile'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      documents: [
        for (final item in json['documents'] as List? ?? [])
          ProviderDocument.fromApi((item as Map).cast<String, dynamic>()),
      ],
      missing: [
        for (final item in json['missing'] as List? ?? [])
          ('${(item as Map)['code']}', '${item['label']}'),
      ],
      approved: resolution is Map ? resolution['approved'] == true : null,
      reason: resolution is Map
          ? ((resolution['reason'] as Map?)?['label'] as String?)
          : null,
      note: resolution is Map ? '${resolution['note'] ?? ''}' : '',
    );
  }
}

/// El perfil del prestador como lo ve él mismo (`GET /provider-profile/mine/`).
class ProviderSelf {
  const ProviderSelf({
    required this.status,
    required this.services,
    required this.phone,
    required this.languages,
    required this.documents,
    this.cityName,
    this.presentation = '',
    this.photoUrl,
    this.carriesTourists = false,
    this.missing = const [],
  });

  final ProviderStatus status;
  final List<String> services;
  final bool carriesTourists;

  /// Nula es todo el país.
  final String? cityName;
  final String phone;
  final String presentation;
  final String? photoUrl;
  final List<ProviderLanguage> languages;

  /// Uno por tipo: el que está en vigor o, si no hay, el más reciente.
  final List<ProviderDocument> documents;

  /// Los tipos que se le piden y no tienen uno en vigor: (código, nombre).
  final List<(String, String)> missing;

  factory ProviderSelf.fromApi(Map<String, dynamic> json) {
    final city = json['city'];
    final photo = json['photo'];
    return ProviderSelf(
      status: ProviderStatus.fromApi(json['status'] as String?),
      services: [for (final item in json['services'] as List? ?? []) '$item'],
      cityName: city is Map ? '${city['name']}' : null,
      phone: '${json['phone'] ?? ''}',
      presentation: '${json['presentation'] ?? ''}',
      photoUrl: photo is Map ? (photo['url'] as String?) : null,
      carriesTourists: json['carries_tourists'] == true,
      languages: [
        for (final item in json['languages'] as List? ?? [])
          ProviderLanguage(
            code: '${(item as Map)['code']}',
            level: '${item['level']}',
            label: item['label'] as String?,
          ),
      ],
      documents: [
        for (final item in json['documents'] as List? ?? [])
          ProviderDocument.fromApi((item as Map).cast<String, dynamic>()),
      ],
      missing: [
        for (final item in json['missing'] as List? ?? [])
          ('${(item as Map)['code']}', '${item['label']}'),
      ],
    );
  }
}

/// Un documento que se va a subir: el archivo del teléfono y lo que dice.
class DocumentDraft {
  const DocumentDraft({
    required this.typeCode,
    required this.number,
    required this.issuedOn,
    required this.file,
    this.expiresOn,
  });

  final String typeCode;
  final String number;
  final DateTime issuedOn;
  final DateTime? expiresOn;
  final GuideDocument file;
}

/// Todo lo que se manda al postularse: la cuenta, el perfil y los documentos.
class ProviderApplicationDraft {
  const ProviderApplicationDraft({
    required this.fullName,
    required this.email,
    required this.profile,
    required this.documents,
    this.code = '',
    this.password = '',
    this.birthDate,
    this.nationality,
  });

  final String fullName;
  final String email;
  final String code;
  final String password;
  final DateTime? birthDate;
  final String? nationality;
  final ProviderProfileData profile;
  final List<DocumentDraft> documents;
}
