import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/property_post.dart';
import 'api_client.dart';
import 'google_auth_service.dart';

typedef PostPublisher =
    Future<PropertyPost> Function(PropertyPost post, List<XFile> images);

/// All the calls the screens make to the PlotPost server. Every method keeps
/// the same shape it had before; requests now go through [ApiClient], which
/// handles the server address, timeouts and token refresh.
class ApiService {
  static String get baseUrl => ApiClient.baseUrl;

  static const int _maxPostImageBytes = 8 * 1024 * 1024;

  // ------------------------------------------------------------------ posts

  static Future<List<PropertyPost>> getPosts() async {
    final res = await ApiClient.get('/posts');
    if (!res.success) throw Exception(res.message);
    final posts = res.data['posts'];
    if (posts is! List) {
      throw const FormatException('The server returned an invalid posts list.');
    }
    return posts
        .whereType<Map<String, dynamic>>()
        .map(PropertyPost.fromJson)
        .toList();
  }

  // Stage 2 replaces the base64 photos with Cloudinary uploads and removes
  // the local fallback below, so a failed publish is reported to the user.
  static Future<PropertyPost> savePost(
    PropertyPost post,
    List<XFile> images,
  ) async {
    final token = await getToken();
    final imageUrls = <String>[];
    var totalImageBytes = 0;
    if (images.isEmpty) {
      imageUrls.addAll(
        post.imagePaths.where(
          (path) =>
              path.startsWith('data:image/') ||
              path.startsWith('http://') ||
              path.startsWith('https://'),
        ),
      );
    }
    for (final image in images) {
      final bytes = await image.readAsBytes();
      totalImageBytes += bytes.length;
      if (totalImageBytes > _maxPostImageBytes) {
        throw Exception('Selected photos are too large. Choose fewer or smaller images.');
      }

      final mimeType = _imageMimeType(image);
      imageUrls.add('data:$mimeType;base64,${base64Encode(bytes)}');
    }

    if (token == null || token.isEmpty) {
      // Fallback for guest mode / offline mode
      return post;
    }

    try {
      final body = {
        'title': post.title,
        'type': post.type,
        'deal': post.deal,
        'price': post.price,
        'location': post.location,
        'description': post.description,
        'socialUrl': post.socialUrl,
        'sellerPhone': post.sellerPhone,
        'area': post.area,
        'bedrooms': post.bedrooms,
        'bathrooms': post.bathrooms,
        'platform': post.platform,
        'imageUrls': imageUrls,
      };
      const timeout = Duration(seconds: 60);
      final res = post.id == null
          ? await ApiClient.post('/posts', body: body, auth: true, timeout: timeout)
          : await ApiClient.put('/posts/${post.id}', body: body, auth: true, timeout: timeout);

      final expectedStatusCode = post.id == null ? 201 : 200;
      if (res.statusCode != expectedStatusCode || !res.success) {
        throw Exception(res.message);
      }
      if (res.data['post'] is! Map<String, dynamic>) {
        throw const FormatException('The server returned an invalid post.');
      }
      return PropertyPost.fromJson(res.data['post'] as Map<String, dynamic>);
    } catch (_) {
      // Return local post object if backend server at localhost:5000 is unreachable on Firebase Hosting
      return post;
    }
  }

  static String _imageMimeType(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) return mimeType;
    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  /// Get user's own property posts from backend
  static Future<List<PropertyPost>> getMyPosts() async {
    if (!await isLoggedIn()) return [];
    final res = await ApiClient.get('/posts/my', auth: true);
    if (res.success && res.data['posts'] is List) {
      return (res.data['posts'] as List)
          .whereType<Map<String, dynamic>>()
          .map(PropertyPost.fromJson)
          .toList();
    }
    return [];
  }

  /// Get count of user's enquiries from backend
  static Future<int> getMyEnquiriesCount() async {
    if (!await isLoggedIn()) return 0;
    final res = await ApiClient.get('/enquiries/my', auth: true);
    if (res.success && res.data['count'] is int) return res.data['count'] as int;
    return 0;
  }

  // ------------------------------------------------------------------- auth

  /// Register user. On success the session is saved and the server emails a
  /// 6-digit verification code (`verificationEmailSent` in the result).
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post(
      '/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    if (res.success) await ApiClient.saveSession(res.data);
    return res.toMap();
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post(
      '/auth/login',
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    if (res.success) await ApiClient.saveSession(res.data);
    return res.toMap();
  }

  /// Signs in with the phone's Google account and creates the PlotPost
  /// account on first use. Returns success false with a message if the user
  /// cancels or Google sign-in isn't set up.
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    final google = await GoogleAuthService.getIdToken();
    if (google.idToken == null) {
      return {'success': false, 'cancelled': google.cancelled, 'message': google.message};
    }
    final res = await ApiClient.post(
      '/auth/google',
      body: {'idToken': google.idToken},
    );
    if (res.success) {
      await ApiClient.saveSession(res.data);
    } else {
      await GoogleAuthService.signOut();
    }
    return res.toMap();
  }

  /// Emails a 6-digit reset code (the answer is the same whether or not the
  /// email has an account).
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await ApiClient.post(
      '/auth/forgot-password',
      body: {'email': email.trim().toLowerCase()},
    );
    return res.toMap();
  }

  /// Sets a new password with the emailed code and logs the user in.
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await ApiClient.post(
      '/auth/reset-password',
      body: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
    if (res.success) await ApiClient.saveSession(res.data);
    return res.toMap();
  }

  static Future<Map<String, dynamic>> verifyEmail(String code) async {
    final res = await ApiClient.post(
      '/auth/verify-email',
      body: {'code': code.trim()},
      auth: true,
    );
    if (res.success && res.data['user'] is Map<String, dynamic>) {
      await ApiClient.saveUser(res.data['user'] as Map<String, dynamic>);
    }
    return res.toMap();
  }

  static Future<Map<String, dynamic>> resendVerification() async {
    final res = await ApiClient.post('/auth/resend-verification', auth: true);
    return res.toMap();
  }

  /// [currentPassword] can be empty for Google accounts that never set one.
  /// Other devices are logged out; this one stays logged in.
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await ApiClient.post(
      '/auth/change-password',
      body: {
        if (currentPassword.isNotEmpty) 'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      auth: true,
    );
    if (res.success) await ApiClient.saveSession(res.data);
    return res.toMap();
  }

  // ---------------------------------------------------------------- profile

  /// Fetch User Profile
  static Future<Map<String, dynamic>> getProfile() async {
    if (!await isLoggedIn()) {
      final localUser = await getUser();
      if (localUser != null) return {'success': true, 'user': localUser};
      return {'success': false, 'message': 'Not logged in'};
    }
    final res = await ApiClient.get('/users/profile', auth: true);
    if (res.success && res.data['user'] is Map<String, dynamic>) {
      await ApiClient.saveUser(res.data['user'] as Map<String, dynamic>);
      return res.toMap();
    }
    // Offline: show the last saved copy instead of an empty profile.
    final localUser = await getUser();
    if (res.statusCode == 0 && localUser != null) {
      return {'success': true, 'user': localUser, 'offline': true};
    }
    return res.toMap();
  }

  /// Update User Profile. Only the fields given are changed.
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? agency,
    String? designation,
    String? location,
    String? profileImage,
  }) async {
    if (!await isLoggedIn()) {
      return {'success': false, 'message': 'Please log in to edit your profile.'};
    }
    final res = await ApiClient.put(
      '/users/profile',
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
        if (agency != null) 'agency': agency,
        if (designation != null) 'designation': designation,
        if (location != null) 'location': location,
        // Only web links are accepted; new photos go through uploadProfilePhoto.
        if (profileImage != null && profileImage.startsWith('http'))
          'profileImage': profileImage,
      },
      auth: true,
    );
    if (res.success && res.data['user'] is Map<String, dynamic>) {
      await ApiClient.saveUser(res.data['user'] as Map<String, dynamic>);
    }
    return res.toMap();
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto(XFile image) async {
    final res = await ApiClient.uploadImage('/users/profile/photo', image);
    if (res.success && res.data['user'] is Map<String, dynamic>) {
      await ApiClient.saveUser(res.data['user'] as Map<String, dynamic>);
    }
    return res.toMap();
  }

  static Future<Map<String, dynamic>> deleteProfilePhoto() async {
    final res = await ApiClient.delete('/users/profile/photo', auth: true);
    if (res.success && res.data['user'] is Map<String, dynamic>) {
      await ApiClient.saveUser(res.data['user'] as Map<String, dynamic>);
    }
    return res.toMap();
  }

  /// Saves account settings toggles: pushNotifications, emailInquiries,
  /// showPhoneNumber.
  static Future<Map<String, dynamic>> updateSettings(
    Map<String, bool> settings,
  ) async {
    final res = await ApiClient.patch('/users/settings', body: settings, auth: true);
    if (res.success && res.data['user'] is Map<String, dynamic>) {
      await ApiClient.saveUser(res.data['user'] as Map<String, dynamic>);
    }
    return res.toMap();
  }

  /// Permanently deletes the account. [confirmation] is the password, or
  /// the word DELETE for Google accounts without a password.
  static Future<Map<String, dynamic>> deleteAccount(String confirmation) async {
    final res = await ApiClient.delete(
      '/users/account',
      body: confirmation == 'DELETE'
          ? {'confirm': 'DELETE'}
          : {'password': confirmation},
      auth: true,
    );
    if (res.success) {
      await GoogleAuthService.signOut();
      await ApiClient.clearSession();
    }
    return res.toMap();
  }

  // ---------------------------------------------------------------- session

  static Future<String?> getToken() => ApiClient.accessToken();

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(ApiClient.userKey);
    if (userStr == null) return null;
    try {
      return jsonDecode(userStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final access = await ApiClient.accessToken();
    final refresh = await ApiClient.refreshToken();
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }

  /// Ends this device's session on the server (best effort) and clears it
  /// locally, even when offline.
  static Future<void> logout() async {
    final refresh = await ApiClient.refreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      await ApiClient.post(
        '/auth/logout',
        body: {'refreshToken': refresh},
        timeout: const Duration(seconds: 5),
      );
    }
    await GoogleAuthService.signOut();
    await ApiClient.clearSession();
  }
}
