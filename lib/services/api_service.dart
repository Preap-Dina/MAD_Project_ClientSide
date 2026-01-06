import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food.dart';
import 'auth_notifier.dart';

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
      var token = body['access_token'] ?? body['token'] ?? body['accessToken'];
      // also check nested 'data' payloads (e.g., { data: { token: ..., user: ... } })
      if (token == null &&
          body is Map<String, dynamic> &&
          body['data'] is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>;
        token = data['access_token'] ?? data['token'] ?? data['accessToken'];
      }
      if (token != null) {
        await _saveToken(token.toString());
        // Prefer user data returned in the login response (some backends return it)
        Map<String, dynamic>? userFromBody;
        if (body is Map<String, dynamic>) {
          if (body['user'] is Map<String, dynamic>) {
            userFromBody = Map<String, dynamic>.from(body['user']);
          } else if (body['data'] is Map<String, dynamic>) {
            final data = body['data'] as Map<String, dynamic>;
            if (data['user'] is Map<String, dynamic>) {
              userFromBody = Map<String, dynamic>.from(data['user']);
            } else if (data['data'] is Map<String, dynamic>) {
              // nested structure: { data: { data: { user: ... }}}
              final inner = data['data'] as Map<String, dynamic>;
              if (inner['user'] is Map<String, dynamic>) {
                userFromBody = Map<String, dynamic>.from(inner['user']);
              }
            } else {
              // sometimes the user is directly in data
              if (data['name'] != null || data['email'] != null) {
                userFromBody = Map<String, dynamic>.from(data);
              }
            }
          }
        }

        if (userFromBody != null) {
          AuthNotifier.setUser(userFromBody);
        } else {
          // Fallback: call /me. Note: /me may be protected by email verification middleware
          // so it can return null even when login succeeded. In that case we still keep the token
          // but the app won't show profile info until the backend allows /me or returns user in login.
          final me = await getMe();
          if (me != null) AuthNotifier.setUser(me);
        }
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
    // Clear global user
    AuthNotifier.clear();
  }

  // Profile management endpoints (requires token)
  Future<Map<String, dynamic>?> updateUsername(String name) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not logged in');
    final uri = Uri.parse('$baseUrl/profile/username');
    final res = await http.put(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode == 200) {
      final b = jsonDecode(res.body);
      // If backend returns updated user, refresh notifier
      final user = b['user'] ?? b;
      if (user is Map<String, dynamic>) {
        AuthNotifier.setUser(Map<String, dynamic>.from(user));
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateEmail(String email) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not logged in');
    final uri = Uri.parse('$baseUrl/profile/email');
    final res = await http.put(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode == 200) {
      final b = jsonDecode(res.body);
      final user = b['user'] ?? b;
      if (user is Map<String, dynamic>) {
        AuthNotifier.setUser(Map<String, dynamic>.from(user));
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  Future<bool> updatePassword(
    String currentPassword,
    String newPassword,
    String newPasswordConfirmation,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not logged in');
    final uri = Uri.parse('$baseUrl/profile/password');
    final res = await http.put(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      }),
    );
    return res.statusCode == 200;
  }

  Future<List<Food>> getWishlist() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/wishlist');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      // Handle both old and new format for backward compatibility
      List<dynamic> list;
      if (body is List) {
        // New format: direct array of foods
        list = body;
      } else if (body is Map && body.containsKey('wishlist')) {
        // Old format: nested in 'wishlist' key
        list = body['wishlist'] as List<dynamic>;
        // Extract food from each wishlist item
        return list.map((e) => Food.fromJson(e['food'] ?? e)).toList();
      } else {
        return [];
      }

      // New format: foods already have full URLs
      return list.map((e) => Food.fromJson(e)).toList();
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
