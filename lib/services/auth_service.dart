import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';

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
      final Response response = await _api.post(
        "/jwt-auth/v1/token",
        {
          "username": username,
          "password": password,
        },
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
}