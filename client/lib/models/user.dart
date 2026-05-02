class RegisterRequest {
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String login;
  final int departmentId;
  final String position;
  final String publicKey;
  final String password;

  RegisterRequest({
    required this.lastName,
    required this.firstName,
    this.patronymic,
    required this.login,
    required this.departmentId,
    required this.position,
    required this.publicKey,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'last_name': lastName,
    'first_name': firstName,
    'patronymic': patronymic,
    'login': login,
    'department_id': departmentId,
    'position': position,
    'public_key': publicKey,
    'password': password,
  };
}
