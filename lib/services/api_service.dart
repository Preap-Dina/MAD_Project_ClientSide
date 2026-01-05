import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<String?> _getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('auth_token', token);
  }

  Map<String, String> _headers(String? token) {
    final headers = {'Accept': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<Food>> getFoods({String? search, String? category}) async {
    final uri = Uri.parse('$baseUrl/food').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final res = await http.get(uri, headers: _headers(null));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body['foods'] as List<dynamic>;
      return list.map((e) => Food.fromJson(e)).toList();
    }
    throw Exception('Failed to load foods');
  }

  Future<Food> getFood(int id) async {
    final uri = Uri.parse('$baseUrl/food/$id');
    final res = await http.get(uri, headers: _headers(null));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return Food.fromJson(body['food']);
    }
    throw Exception('Failed to load food');
  }

  Future<bool> register(String name, String email, String password) async {
    final uri = Uri.parse('$baseUrl/register');
    final res = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );
    return res.statusCode == 201 || res.statusCode == 200;
  }

  Future<bool> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/login');
    final res = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final token =
          body['access_token'] ?? body['token'] ?? body['accessToken'];
      if (token != null) {
        await _saveToken(token.toString());
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    final token = await _getToken();
    if (token == null) return;
    final uri = Uri.parse('$baseUrl/logout');
    await http.post(uri, headers: _headers(token));
    final sp = await SharedPreferences.getInstance();
    await sp.remove('auth_token');
  }

  Future<List<Food>> getWishlist() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/wishlist');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body['wishlist'] as List<dynamic>;
      // wishlist items contain food field
      return list.map((e) => Food.fromJson(e['food'] ?? e)).toList();
    }
    return [];
  }

  Future<bool> addToWishlist(int foodId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not logged in');
    final uri = Uri.parse('$baseUrl/wishlist');
    final res = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'food_id': foodId}),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> removeFromWishlist(int foodId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not logged in');
    final uri = Uri.parse('$baseUrl/wishlist');
    final request = http.Request('DELETE', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.body = jsonEncode({'food_id': foodId});
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return res.statusCode == 200 || res.statusCode == 204;
  }

  /// Fetch current authenticated user (requires token). Returns a map with user data or null.
  Future<Map<String, dynamic>?> getMe() async {
    final token = await _getToken();
    if (token == null) return null;
    final uri = Uri.parse('$baseUrl/me');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        // Laravel APIs often return {"user": {...}} or the user object directly
        if (body.containsKey('user') && body['user'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(body['user']);
        }
        return Map<String, dynamic>.from(body);
      }
    }
    return null;
  }
}
