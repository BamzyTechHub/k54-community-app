import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:k54_mobile/core/services/api_service.dart';

class AuthService {
  final ApiService _api = ApiService.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

Future<Response> getMember(String userId) async {
  return ApiService.instance.get(
    "/buddyboss/v1/members/$userId",
  );
}

  /// Login
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      // ApiService.initialize() restores a saved bearer token into the
      // shared Dio instance's base headers on app start. That token must
      // never ride along on the login request itself — it may be stale,
      // expired, or otherwise invalid, and has no bearing on a fresh
      // username/password exchange.
      _api.dio.options.headers.remove("Authorization");

      final Response response = await _api.post(
        "/jwt-auth/v1/token",
        {
          "username": username,
          "password": password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {"Accept": "application/json"},
        ),
      );

      final token = response.data["token"];

      await _api.saveToken(token);

      await _storage.write(
        key: "user",
        value: response.data.toString(),
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }


/// Register
 Future<Response> register({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
  required String username,
}) async {
  try {
    final response = await _api.post(
      "/buddyboss/v1/signup",
      {
        "signup_email": email,
        "signup_email_confirm": email,
        "signup_password": password,
        "signup_password_confirm": password,
        "field_1": firstName,
        "field_2": lastName,
        "field_3": username,
        "legal_agreement": true,
      },
    );

    return response;
  } on DioException catch (e) {
    throw Exception(
      e.response?.data["message"] ??
          "Registration failed",
    );
  }
}


  /// Logout
  Future<void> logout() async {
    await _api.logout();
    await _storage.delete(key: "user");
  }

  /// Check Login
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: "token");
    return token != null;
  }

  /// Get Token
  Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  /// Get Current User
  Future<Response> getCurrentUser() async {
    return await _api.get("/buddyboss/v1/members/me");
  }

  /// Updates the logged-in account's email via WordPress core's own REST
  /// API (POST /wp/v2/users/me, field "email") - confirmed via the
  /// official REST API Handbook (developer.wordpress.org/rest-api/
  /// reference/users/), not a BuddyBoss-specific or guessed endpoint.
  /// WordPress core itself is what sends the confirmation link to the
  /// old address before applying the change, not this app.
  Future<void> updateEmail(String newEmail) async {
    await _api.post("/wp/v2/users/me", {"email": newEmail});
  }

  /// Updates the logged-in account's password via the same confirmed
  /// WordPress core endpoint (field "password").
  Future<void> updatePassword(String newPassword) async {
    await _api.post("/wp/v2/users/me", {"password": newPassword});
  }
}