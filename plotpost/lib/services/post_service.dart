import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class PostService {
  // Create a new post
  static Future<Map<String, dynamic>> createPost({
    required String caption,
    String imageUrl = '',
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'caption': caption,
          'imageUrl': imageUrl,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create post');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get all posts
  static Future<List<dynamic>> getPosts() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/posts'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['posts'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load posts');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
