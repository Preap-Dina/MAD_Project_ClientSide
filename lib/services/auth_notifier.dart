import 'package:flutter/foundation.dart';

/// A simple global notifier for the currently authenticated user.
/// The value is a Map<String,dynamic> matching the /api/me response, or null.
class AuthNotifier {
  static final ValueNotifier<Map<String, dynamic>?> currentUser =
      ValueNotifier<Map<String, dynamic>?>(null);

  static void setUser(Map<String, dynamic>? u) => currentUser.value = u;

  static void clear() => currentUser.value = null;
}
