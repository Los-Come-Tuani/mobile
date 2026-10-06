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
    );
  }
}
