import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
 ApiService._() {
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ),
  );
}

  static final ApiService instance = ApiService._();
  static const String baseUrl = "https://k54global.com/wp-json";

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        "Accept": "application/json",
      },
    ),
  );

  

  final FlutterSecureStorage storage = const FlutterSecureStorage();

   Future<void> initialize() async {
  final token = await storage.read(key: "token");

  print("========== API INITIALIZE ==========");
  print("Saved Token: $token");

  if (token != null) {
    dio.options.headers["Authorization"] = "Bearer $token";
  }
}

  Future<void> saveToken(String token) async {
  print("========== SAVING TOKEN ==========");
  print(token);

  await storage.write(key: "token", value: token);

  dio.options.headers["Authorization"] = "Bearer $token";
}

  Future<void> logout() async {
    await storage.delete(key: "token");
    dio.options.headers.remove("Authorization");
  }

  Future<Response> get(String endpoint,
      {Map<String, dynamic>? query}) async {
    return await dio.get(
      endpoint,
      queryParameters: query,
    );
  }

  Future<Response> post(
    String endpoint,
    dynamic data, {
    Options? options,
  }) async {
    return await dio.post(
      endpoint,
      data: data,
      options: options,
    );
  }

  Future<Response> put(
    String endpoint,
    dynamic data,
  ) async {
    return await dio.put(
      endpoint,
      data: data,
    );
  }

  Future<Response> delete(String endpoint) async {
    return await dio.delete(endpoint);
  }
}