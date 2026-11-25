import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The result of one API call. `data` is the decoded JSON body (or an
/// empty map), and `message` is always something safe to show the user.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.data,
    required this.message,
  });

  final int statusCode;
  final Map<String, dynamic> data;
  final String message;

  bool get success =>
      statusCode >= 200 && statusCode < 300 && data['success'] != false;

  /// The same map shape the screens already use: success + message + data.
  Map<String, dynamic> toMap() => {
        ...data,
        'success': success,
        'message': message,
      };
}

/// One place for the server address, timeouts, login tokens and error
/// messages. Logged-in calls refresh an expired access token automatically
/// and retry once; if that fails, [sessionExpired] fires and the app goes
/// back to the welcome screen.
class ApiClient {
  ApiClient._();

  // Pass the deployed server with:
  //   flutter run --dart-define=API_BASE_URL=https://<your-app>.up.railway.app/api
  //   flutter build apk --dart-define=API_BASE_URL=https://<your-app>.up.railway.app/api
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Set this to the Railway URL (ending in /api) after the first deploy, so
  /// release builds work without --dart-define. Leave empty until then.
  static const String productionBaseUrl = '';

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kReleaseMode && productionBaseUrl.isNotEmpty) {
      return productionBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    // Local development only.
    if (kIsWeb) return 'http://localhost:5000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.80.23:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static const Duration defaultTimeout = Duration(seconds: 20);

  static const String accessTokenKey = 'auth_token';
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String userKey = 'auth_user';

  /// Increments when the login session can't be renewed. main.dart listens
  /// to it and sends the user back to the welcome screen.
  static final ValueNotifier<int> sessionExpired = ValueNotifier<int>(0);

  static Future<void>? _refreshInFlight;

  // ---------------------------------------------------------------- session

  static Future<String?> accessToken() async =>
      (await SharedPreferences.getInstance()).getString(accessTokenKey);

  static Future<String?> refreshToken() async =>
      (await SharedPreferences.getInstance()).getString(refreshTokenKey);

  /// Saves tokens and user from a login/register/refresh response.
  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final access = (data['accessToken'] ?? data['token'])?.toString();
    final refresh = data['refreshToken']?.toString();
    if (access != null && access.isNotEmpty) {
      await prefs.setString(accessTokenKey, access);
    }
    if (refresh != null && refresh.isNotEmpty) {
      await prefs.setString(refreshTokenKey, refresh);
    }
    if (data['user'] is Map<String, dynamic>) {
      await saveUser(data['user'] as Map<String, dynamic>);
    }
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(userKey);
  }

  // ---------------------------------------------------------------- requests

  static Future<ApiResponse> get(String path, {bool auth = false}) =>
      _send('GET', path, auth: auth);

  static Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    Duration? timeout,
  }) =>
      _send('POST', path, body: body, auth: auth, timeout: timeout);

  static Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    Duration? timeout,
  }) =>
      _send('PUT', path, body: body, auth: auth, timeout: timeout);

  static Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) =>
      _send('PATCH', path, body: body, auth: auth);

  static Future<ApiResponse> delete(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) =>
      _send('DELETE', path, body: body, auth: auth);

  /// Uploads one image as multipart field "image".
  static Future<ApiResponse> uploadImage(
    String path,
    XFile image, {
    bool auth = true,
  }) async {
    final bytes = await image.readAsBytes();
    final mime = _imageMimeType(image);
    Future<http.BaseRequest> build() async {
      final request = http.MultipartRequest('POST', _uri(path));
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: image.name.isNotEmpty ? image.name : 'photo.jpg',
          contentType: MediaType.parse(mime),
        ),
      );
      return request;
    }

    return _execute(build, auth: auth, timeout: const Duration(seconds: 60));
  }

  static Uri _uri(String path) =>
      Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}');

  static Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    Duration? timeout,
  }) {
    Future<http.BaseRequest> build() async {
      final request = http.Request(method, _uri(path));
      request.headers['Accept'] = 'application/json';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      return request;
    }

    return _execute(build, auth: auth, timeout: timeout ?? defaultTimeout);
  }

  static Future<ApiResponse> _execute(
    Future<http.BaseRequest> Function() build, {
    required bool auth,
    required Duration timeout,
  }) async {
    try {
      var response = await _sendOnce(build, auth: auth, timeout: timeout);
      if (auth && response.statusCode == 401) {
        final refreshed = await _refreshSession();
        if (refreshed) {
          response = await _sendOnce(build, auth: true, timeout: timeout);
        }
      }
      return _toApiResponse(response);
    } on TimeoutException {
      return const ApiResponse(
        statusCode: 0,
        data: {},
        message: 'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      return const ApiResponse(
        statusCode: 0,
        data: {},
        message:
            "Can't reach PlotPost right now. Check your internet connection and try again.",
      );
    } catch (_) {
      return const ApiResponse(
        statusCode: 0,
        data: {},
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  static Future<http.Response> _sendOnce(
    Future<http.BaseRequest> Function() build, {
    required bool auth,
    required Duration timeout,
  }) async {
    final request = await build();
    if (auth) {
      final token = await accessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    final streamed = await request.send().timeout(timeout);
    return http.Response.fromStream(streamed).timeout(timeout);
  }

  static ApiResponse _toApiResponse(http.Response response) {
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      // Non-JSON body (e.g. a proxy error page); handled below.
    }
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    final message = data['message']?.toString() ??
        (ok
            ? 'Done.'
            : response.statusCode >= 500
                ? 'The server had a problem. Please try again in a moment.'
                : 'Request failed (HTTP ${response.statusCode}).');
    return ApiResponse(
      statusCode: response.statusCode,
      data: data,
      message: message,
    );
  }

  /// Only one refresh runs at a time: the server accepts each refresh token
  /// once, so parallel refreshes would log the user out.
  static Future<bool> _refreshSession() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      await inFlight;
      final token = await accessToken();
      return token != null && token.isNotEmpty;
    }

    final completer = Completer<void>();
    _refreshInFlight = completer.future;
    try {
      final token = await refreshToken();
      if (token == null || token.isEmpty) {
        await _expireSession();
        return false;
      }
      final response = await http
          .post(
            _uri('/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': token}),
          )
          .timeout(defaultTimeout);
      final result = _toApiResponse(response);
      if (result.success) {
        await saveSession(result.data);
        return true;
      }
      // 401 = the session really is over. Anything else (server down) keeps
      // the tokens so the next attempt can try again.
      if (response.statusCode == 401) await _expireSession();
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshInFlight = null;
      completer.complete();
    }
  }

  static Future<void> _expireSession() async {
    final hadSession = (await accessToken()) != null;
    await clearSession();
    if (hadSession) sessionExpired.value++;
  }

  static String _imageMimeType(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) return mimeType;
    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
