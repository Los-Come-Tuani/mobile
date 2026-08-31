/// Usuario autenticado.
class User {
  const User({
    required this.id,
    required this.email,
    this.name = '',
    this.token = '',
  });

  final String id;
  final String email;
  final String name;
  final String token;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: '${json['id'] ?? json['Id'] ?? ''}',
      email: '${json['email'] ?? json['Email'] ?? ''}',
      name: '${json['name'] ?? json['Nombre'] ?? ''}',
      token: '${json['token'] ?? json['Token'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'token': token,
  };

  User copyWith({String? id, String? email, String? name, String? token}) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      token: token ?? this.token,
    );
  }
}
