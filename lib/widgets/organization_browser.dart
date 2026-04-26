import 'package:flutter/material.dart';
import '../models/department_tree.dart';

class OrganizationBrowser extends StatelessWidget {
  final List<DepartmentTree> departments;
  final VoidCallback onClose;
  final Function(String userId) onUserTap; // Добавляем

  const OrganizationBrowser({
    super.key,
    required this.departments,
    required this.onClose,
    required this.onUserTap, // Добавляем
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: departments.length,
            itemBuilder: (context, index) {
              return _buildDepartmentTile(context, departments[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: onClose,
            child: const Text('Закрыть'),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentTile(BuildContext context, DepartmentTree dept) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text(dept.name),
        children: [
          if (dept.users.isNotEmpty)
            ...dept.users.map((user) => _buildUserTile(context, user)),
          if (dept.children.isNotEmpty)
            ...dept.children
                .map((child) => _buildDepartmentTile(context, child)),
          if (dept.users.isEmpty && dept.children.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Нет сотрудников'),
            ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserTree user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(user.firstName[0] + user.lastName[0]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(user.fullName)),
          ElevatedButton(
            onPressed: () => onUserTap(user.id),
            child: const Text('Написать'),
          ),
        ],
      ),
    );
  }
}
