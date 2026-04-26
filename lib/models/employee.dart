class Employee {
  final String id;
  final String login;
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String? occupation;
  final String? avatarUrl;

  Employee({
    required this.id,
    required this.login,
    required this.lastName,
    required this.firstName,
    this.patronymic,
    this.occupation,
    this.avatarUrl,
  });

  String get fullName {
    if (patronymic != null && patronymic!.isNotEmpty) {
      return '$lastName $firstName $patronymic';
    }
    return '$lastName $firstName';
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      login: json['login'],
      lastName: json['last_name'],
      firstName: json['first_name'],
      patronymic: json['patronymic'],
      occupation: json['occupation'],
      avatarUrl: json['avatar_url'],
    );
  }
}
