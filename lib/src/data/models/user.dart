import 'provider.dart';

/// Usuario autenticado, con la forma que entrega el API (`GET /auth/profile/`).
class User {
  const User({
    required this.id,
    required this.email,
    this.name = '',
    this.firstName = '',
    this.lastName = '',
    this.username,
    this.birthDate,
    this.nationality = '',
    this.twoFactorEnabled = false,
    this.role,
    this.provider,
  });

  final String id;
  final String email;

  /// El nombre listo para mostrar.
  final String name;
  final String firstName;
  final String lastName;
  final String? username;
  final DateTime? birthDate;

  /// País en ISO 3166-1 de dos letras (`NI`, `US`), o vacío.
  final String nationality;

  /// Si la cuenta tiene la verificación en dos pasos activa.
  final bool twoFactorEnabled;

  /// El papel que le da el API: en la app, `turista`, `guia` o `traductor`. Si tiene
  /// varios, el API manda el de más rango (el de guía antes que el de traductor). Nulo en
  /// la demo y en una cuenta sin rol.
  final String? role;

  /// El equipo de K'Plan ya la habilitó como guía.
  bool get isGuide => role == 'guia';

  /// El equipo de K'Plan ya la habilitó como traductora (y no como guía).
  bool get isTranslator => role == 'traductor';

  /// Puede entrar a la app del guía: ofrece sus servicios como guía o como traductor.
  bool get providesServices => isGuide || isTranslator;

  /// Su perfil de guía o traductor: en revisión, activo o suspendido. Nulo para quien no
  /// es prestador (una cuenta, un papel: un turista no lo tiene).
  final ProviderRef? provider;

  factory User.fromApi(Map<String, dynamic> json) {
    final twoFactor = json['two_factor'];
    return User(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      name: '${json['name'] ?? ''}',
      firstName: '${json['first_name'] ?? ''}',
      lastName: '${json['last_name'] ?? ''}',
      username: json['username'] as String?,
      birthDate: DateTime.tryParse('${json['birth_date'] ?? ''}'),
      nationality: '${json['nationality'] ?? ''}',
      twoFactorEnabled: twoFactor is Map && twoFactor['enabled'] == true,
      role: json['role'] as String?,
      provider: ProviderRef.fromApi(json['provider']),
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? firstName,
    String? lastName,
    String? username,
    DateTime? birthDate,
    String? nationality,
    bool? twoFactorEnabled,
    String? role,
    ProviderRef? provider,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      birthDate: birthDate ?? this.birthDate,
      nationality: nationality ?? this.nationality,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      role: role ?? this.role,
      provider: provider ?? this.provider,
    );
  }
}
