import 'employee.dart';

class DepartmentEmployeeNode {
  final String id;
  final String name;
  final int level;
  final List<DepartmentEmployeeNode> children;
  final List<Employee> employees;

  bool get hasChildren => children.isNotEmpty;
  bool get hasEmployees => employees.isNotEmpty;

  DepartmentEmployeeNode({
    required this.id,
    required this.name,
    required this.level,
    required this.children,
    required this.employees,
  });
}
