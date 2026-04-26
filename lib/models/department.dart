class UserInfo {
  final String id;
  final String login;
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String? occupation;

  UserInfo({
    required this.id,
    required this.login,
    required this.lastName,
    required this.firstName,
    this.patronymic,
    this.occupation,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
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

class DepartmentNode {
  final String id;
  final String name;
  final int level;
  final List<UserInfo> users;
  final List<DepartmentNode> children;

  DepartmentNode({
    required this.id,
    required this.name,
    required this.level,
    required this.users,
    required this.children,
  });

  factory DepartmentNode.fromJson(Map<String, dynamic> json) {
    return DepartmentNode(
      id: json['id'].toString(),
      name: json['name'],
      level: json['level'],
      users: (json['users'] as List).map((u) => UserInfo.fromJson(u)).toList(),
      children: (json['children'] as List)
          .map((c) => DepartmentNode.fromJson(c))
          .toList(),
    );
  }
}
