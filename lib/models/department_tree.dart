class DepartmentTree {
  final String id;
  final String name;
  final int level;
  final List<UserTree> users;
  final List<DepartmentTree> children;

  DepartmentTree({
    required this.id,
    required this.name,
    required this.level,
    required this.users,
    required this.children,
  });

  factory DepartmentTree.fromJson(Map<String, dynamic> json) {
    return DepartmentTree(
      id: json['id'].toString(),
      name: json['name'],
      level: json['level'],
      users: (json['users'] as List)
          .map((u) => UserTree.fromJson(u))
          .toList(),
      children: (json['children'] as List)
          .map((c) => DepartmentTree.fromJson(c))
          .toList(),
    );
  }
}

class UserTree {
  final String id;
  final String login;
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String? occupation;

  UserTree({
    required this.id,
    required this.login,
    required this.lastName,
    required this.firstName,
    this.patronymic,
    this.occupation,
  });

  factory UserTree.fromJson(Map<String, dynamic> json) {
    return UserTree(
      id: json['id'].toString(),
      login: json['login'],
      lastName: json['last_name'],
      firstName: json['first_name'],
      patronymic: json['patronymic'],
      occupation: json['occupation'],
    );
  }

  String get fullName {
    if (patronymic != null && patronymic!.isNotEmpty) {
      return '$lastName $firstName $patronymic';
    }
    return '$lastName $firstName';
  }
}
