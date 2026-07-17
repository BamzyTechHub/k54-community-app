import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
 ApiService._() {
  // REMOVED 2026-07-16: this used to force IPv4-only connections via a
  // custom Socket-level connectionFactory, added to fix a real IPv6-
  // black-hole connectTimeout for one tester's network. An A/B test
  // (real device, two builds, otherwise identical) proved this exact code
  // was the cause of a *different*, much bigger problem: it made login
  // fail with a 301 self-redirect for at least two other testers, on both
  // mobile data and WiFi - almost certainly because bypassing the normal
  // OS-level connection path in favor of a raw manually-resolved Socket
  // changes the connection's fingerprint in a way Hostinger's/LiteSpeed's
  // bot-protection flags specifically on the sensitive login endpoint.
  // Login blocking multiple testers outright is worse than one tester's
  // narrower IPv6 edge case, so this is removed rather than re-enabled.
  // If the IPv6 issue resurfaces, the right fix is a "try normal first,
  // only fall back to forced IPv4 after a connection actually times out"
  // approach - not forcing it unconditionally for every connection.

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra["k54_startTime"] = DateTime.now();

        // Redact password-shaped fields before logging - never print
        // credentials, even to local debug output.
        Object? loggedBody = options.data;
        if (loggedBody is Map) {
          final redacted = Map<String, dynamic>.from(loggedBody);
          for (final key in redacted.keys.toList()) {
            if (key.toString().toLowerCase().contains("password")) {
              redacted[key] = "***REDACTED***";
            }
          }
          loggedBody = redacted;
        }

        // Diagnostic logging added 2026-07-16 to root-cause a release-build
        // "login times out after 30s" report (previously "Failed host
        // lookup" before android.permission.INTERNET was added - that's
        // fixed; this is a new, different symptom). Prints the
        // fully-resolved URL, headers, and body up front so we know
        // exactly what left the device, then onResponse/onError below
        // report elapsed time and - critically - Dio's DioExceptionType,
        // which distinguishes "TCP/TLS never connected" (connectionError)
        // from "connected but the server/CDN never sent a response body"
        // (receiveTimeout) from "a response DID come back, just not a
        // success" (badResponse - e.g. the Hostinger CDN's JS challenge
        // page, which would show up here as a real HTTP status instead of
        // a timeout at all).
        print("========== API REQUEST ==========");
        print("${options.method} ${options.uri}");
        print("Headers: ${options.headers}");
        print("Body: $loggedBody");
        print("connectTimeout=${options.connectTimeout} sendTimeout=${options.sendTimeout} receiveTimeout=${options.receiveTimeout}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final start = response.requestOptions.extra["k54_startTime"] as DateTime?;
        final elapsed = start != null ? DateTime.now().difference(start).inMilliseconds : null;
        print("========== API RESPONSE ==========");
        print("${response.requestOptions.method} ${response.requestOptions.uri}");
        print("Status: ${response.statusCode}  Elapsed: ${elapsed}ms");
        if (response.isRedirect || response.redirects.isNotEmpty) {
          print("Redirects: ${response.redirects.map((r) => r.location).toList()}");
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        final start = error.requestOptions.extra["k54_startTime"] as DateTime?;
        final elapsed = start != null ? DateTime.now().difference(start).inMilliseconds : null;
        print("========== API ERROR ==========");
        print("${error.requestOptions.method} ${error.requestOptions.uri}");
        print("DioExceptionType: ${error.type}  Elapsed: ${elapsed}ms");
        print("Message: ${error.message}");
        if (error.response != null) {
          print("Response status: ${error.response?.statusCode}");
          print("Response headers: ${error.response?.headers}");
          final body = error.response?.data?.toString() ?? "";
          print("Response body (first 500 chars): ${body.substring(0, body.length > 500 ? 500 : body.length)}");
        } else {
          print("No response was received at all - failed before/during connect, send, or receive (see DioExceptionType above for which stage).");
        }
        return handler.next(error);
      },
    ),
  );
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