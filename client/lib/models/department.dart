class Department {
  final int id;
  final String name;
  final String type;
  final int? parentId;

  Department({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    parentId: json['parent_id'],
  );
}
