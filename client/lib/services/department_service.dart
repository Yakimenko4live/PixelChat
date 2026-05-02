import 'dart:convert';
import 'package:http/http.dart' as http;

class DepartmentService {
  static const String baseUrl = 'https://domenfromdevigor4live.store/api';

  Future<List<Map<String, dynamic>>> getDepartments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/departments'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load departments: ${response.statusCode}');
    }
  }
}
