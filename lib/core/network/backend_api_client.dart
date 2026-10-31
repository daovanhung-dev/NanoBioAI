import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const defaultBackendApiBaseUrl = 'https://42.118.174.147';

class BackendApiException implements Exception {
  final int statusCode;
  final String businessCode;
  final String message;

  const BackendApiException({
    required this.statusCode,
    required this.businessCode,
    required this.message,
  });

  @override
  String toString() => message;
}

class BackendApiResponse {
  const BackendApiResponse({required this.statusCode, required this.data});

  final int statusCode;
  final Object? data;
}

class BackendAuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;
  final String? phone;
  final String? email;
  final bool mustChangePassword;
  final Set<String> roles;

  const BackendAuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    this.phone,
    this.email,
    this.mustChangePassword = false,
    this.roles = const {},
  });

  factory BackendAuthSession.fromApiData(
    Map<String, Object?> data, {
    BackendAuthSession? previous,
  }) {
    final rawUser = data['user'];
    final user = rawUser is Map
        ? Map<String, Object?>.from(rawUser)
        : const <String, Object?>{};
    final accessToken = data['access_token']?.toString().trim() ?? '';
    final refreshToken = data['refresh_token']?.toString().trim() ?? '';
    final userId = user['id']?.toString().trim() ?? previous?.userId ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty || userId.isEmpty) {
      throw const FormatException('Invalid backend authentication response.');
    }

    final expiresIn = _intValue(data['expires_in']) ?? 900;
    final rawRoles = user['roles'];
    final roles = rawRoles is List
        ? rawRoles.map((value) => value.toString()).toSet()
        : previous?.roles ?? const <String>{};

    return BackendAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
      userId: userId,
      phone: user['phone']?.toString() ?? previous?.phone,
      email: user['email']?.toString() ?? previous?.email,
      mustChangePassword:
          data['must_change_password'] == true ||
          (previous?.mustChangePassword == true &&
              data['must_change_password'] == null),
      roles: roles,
    );
  }

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'user_id': userId,
    'phone': phone,
    'email': email,
    'must_change_password': mustChangePassword,
    'roles': roles.toList(growable: false),
  };

  factory BackendAuthSession.fromJson(Map<String, Object?> json) {
    final accessToken = json['access_token']?.toString() ?? '';
    final refreshToken = json['refresh_token']?.toString() ?? '';
    final userId = json['user_id']?.toString() ?? '';
    final expiresAt = DateTime.tryParse(json['expires_at']?.toString() ?? '');
    if (accessToken.isEmpty ||
        refreshToken.isEmpty ||
        userId.isEmpty ||
        expiresAt == null) {
      throw const FormatException('Invalid stored authentication session.');
    }
    final rawRoles = json['roles'];
    return BackendAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt.toUtc(),
      userId: userId,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      mustChangePassword: json['must_change_password'] == true,
      roles: rawRoles is List
          ? rawRoles.map((value) => value.toString()).toSet()
          : const {},
    );
  }
}

int? _intValue(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

abstract interface class BackendSessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureBackendSessionStore implements BackendSessionStore {
  static const _key = 'nanobio_backend_session_v1';
  final FlutterSecureStorage storage;

  const SecureBackendSessionStore({
    this.storage = const FlutterSecureStorage(),
  });

  @override
  Future<String?> read() => storage.read(key: _key);

  @override
  Future<void> write(String value) => storage.write(key: _key, value: value);

  @override
  Future<void> clear() => storage.delete(key: _key);
}

class BackendApiClient {
  static BackendApiClient? _shared;

  static BackendApiClient get shared =>
      _shared ??= BackendApiClient(baseUrl: defaultBackendApiBaseUrl);

  static void configure({
    required String baseUrl,
    BackendSessionStore? sessionStore,
    http.Client? httpClient,
  }) {
    _shared?.close();
    _shared = BackendApiClient(
      baseUrl: baseUrl,
      sessionStore: sessionStore,
      httpClient: httpClient,
    );
  }

  final Uri _baseUri;
  final BackendSessionStore _sessionStore;
  final http.Client _httpClient;
  final StreamController<String?> _authChanges =
      StreamController<String?>.broadcast();
  BackendAuthSession? _session;
  Future<BackendAuthSession?>? _refreshInFlight;

  BackendApiClient({
    required String baseUrl,
    BackendSessionStore? sessionStore,
    http.Client? httpClient,
  }) : _baseUri = _validateBaseUrl(baseUrl),
       _sessionStore = sessionStore ?? const SecureBackendSessionStore(),
       _httpClient = httpClient ?? http.Client();

  BackendAuthSession? get session => _session;
  String? get currentUserId => _session?.userId;
  String? get currentAccessToken => _session?.accessToken;

  Stream<String?> get authChanges async* {
    yield _session?.userId;
    yield* _authChanges.stream;
  }

  Future<BackendAuthSession?> restoreSession() async {
    try {
      final raw = await _sessionStore.read();
      if (raw == null || raw.isEmpty) {
        _setSession(null);
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException();
      _session = BackendAuthSession.fromJson(
        Map<String, Object?>.from(decoded),
      );
      if (_session!.expiresAt.isBefore(
        DateTime.now().toUtc().add(const Duration(seconds: 20)),
      )) {
        return await _rotateRefreshToken();
      }
      _authChanges.add(_session!.userId);
      return _session;
    } catch (_) {
      await _clearSession();
      return null;
    }
  }

  Future<Object?> request(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final response = await _send(
      method,
      path,
      query: query,
      body: body,
      authenticated: authenticated,
    );
    if (response.statusCode == 401 &&
        authenticated &&
        _session?.refreshToken.isNotEmpty == true) {
      final refreshed = await _rotateRefreshToken();
      if (refreshed != null) {
        return _readResponse(
          await _send(
            method,
            path,
            query: query,
            body: body,
            authenticated: authenticated,
          ),
        );
      }
    }
    return _readResponse(response);
  }

  Future<Map<String, Object?>> requestMap(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final result = await request(
      method,
      path,
      query: query,
      body: body,
      authenticated: authenticated,
    );
    if (result is Map) return Map<String, Object?>.from(result);
    throw const FormatException('Backend response must be an object.');
  }

  Future<Map<String, Object?>> uploadBytes(
    String path, {
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String fieldName = 'file',
  }) async {
    var response = await _sendMultipart(
      path,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      fieldName: fieldName,
    );
    if (response.statusCode == 401 &&
        _session?.refreshToken.isNotEmpty == true) {
      if (await _rotateRefreshToken() != null) {
        response = await _sendMultipart(
          path,
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
          fieldName: fieldName,
        );
      }
    }
    final body = await http.Response.fromStream(response);
    final data = _readResponse(body);
    if (data is Map) return Map<String, Object?>.from(data);
    throw const FormatException('Backend upload response must be an object.');
  }

  Future<Uint8List> downloadBytes(String path) async {
    var response = await _sendBinary('GET', path);
    if (response.statusCode == 401 &&
        _session?.refreshToken.isNotEmpty == true) {
      if (await _rotateRefreshToken() != null) {
        response = await _sendBinary('GET', path);
      }
    }
    final body = await http.Response.fromStream(response);
    if (body.statusCode < 200 || body.statusCode >= 300) {
      _readResponse(body);
      throw const BackendApiException(
        statusCode: 502,
        businessCode: 'DOWNLOAD_FAILED',
        message: 'Chưa tải được tệp từ máy chủ.',
      );
    }
    return body.bodyBytes;
  }

  Future<BackendApiResponse> requestResponse(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final response = await _send(
      method,
      path,
      query: query,
      body: body,
      authenticated: authenticated,
    );
    return BackendApiResponse(
      statusCode: response.statusCode,
      data: _readResponse(response),
    );
  }

  Stream<Map<String, Object?>> streamEvents(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
  }) async* {
    if (!path.startsWith('/api/v1/')) {
      throw ArgumentError.value(path, 'path', 'Must use a versioned API path.');
    }
    var response = await _sendStream(
      method,
      path,
      body: body,
      authenticated: authenticated,
    );
    if (response.statusCode == 401 &&
        authenticated &&
        _session?.refreshToken.isNotEmpty == true) {
      final refreshed = await _rotateRefreshToken();
      if (refreshed != null) {
        response = await _sendStream(
          method,
          path,
          body: body,
          authenticated: authenticated,
        );
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _readResponse(await http.Response.fromStream(response));
      throw const BackendApiException(
        statusCode: 502,
        businessCode: 'INVALID_STREAM_RESPONSE',
        message: 'Máy chủ trả về phản hồi không hợp lệ.',
      );
    }

    var totalBytes = 0;
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      totalBytes += utf8.encode(line).length;
      if (totalBytes > 8 * 1024 * 1024 || line.length > 256 * 1024) {
        throw const BackendApiException(
          statusCode: 502,
          businessCode: 'STREAM_RESPONSE_TOO_LARGE',
          message: 'Câu trả lời vượt quá dung lượng cho phép.',
        );
      }
      if (line.trim().isEmpty) continue;
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        throw const BackendApiException(
          statusCode: 502,
          businessCode: 'INVALID_STREAM_RESPONSE',
          message: 'Máy chủ trả về phản hồi không hợp lệ.',
        );
      }
      yield Map<String, Object?>.from(decoded);
    }
  }

  Future<BackendAuthSession> establishSession(Object? responseData) async {
    if (responseData is! Map) {
      throw const FormatException(
        'Backend authentication response is invalid.',
      );
    }
    final session = BackendAuthSession.fromApiData(
      Map<String, Object?>.from(responseData),
    );
    await _setSession(session);
    return session;
  }

  Future<BackendAuthSession> changePassword(String newPassword) async {
    final data = await requestMap(
      'POST',
      '/api/v1/auth/change-password',
      body: {'new_password': newPassword},
    );
    return establishSession(data);
  }

  Future<void> signOut() async {
    final current = _session;
    try {
      if (current != null) {
        await requestMap(
          'POST',
          '/api/v1/auth/logout',
          body: {'refresh_token': current.refreshToken},
        );
      }
    } finally {
      await _clearSession();
    }
  }

  Future<BackendAuthSession?> _rotateRefreshToken() {
    final active = _refreshInFlight;
    if (active != null) return active;
    final future = _performRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<BackendAuthSession?> _performRefresh() async {
    final current = _session;
    if (current == null) return null;
    try {
      final response = await _send(
        'POST',
        '/api/v1/auth/refresh',
        body: {'refresh_token': current.refreshToken},
        authenticated: false,
      );
      final data = _readResponse(response);
      if (data is! Map) throw const FormatException();
      final refreshed = BackendAuthSession.fromApiData(
        Map<String, Object?>.from(data),
        previous: current,
      );
      await _setSession(refreshed);
      return refreshed;
    } catch (_) {
      await _clearSession();
      return null;
    }
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    required bool authenticated,
  }) async {
    if (!path.startsWith('/api/v1/')) {
      throw ArgumentError.value(path, 'path', 'Must use a versioned API path.');
    }
    final uri = _baseUri
        .resolve(path)
        .replace(
          queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
        );
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    if (authenticated && _session != null) {
      headers['Authorization'] = 'Bearer ${_session!.accessToken}';
    }
    final encodedBody = body == null ? null : jsonEncode(body);
    try {
      return switch (method.toUpperCase()) {
        'GET' => await _httpClient.get(uri, headers: headers),
        'POST' => await _httpClient.post(
          uri,
          headers: headers,
          body: encodedBody,
        ),
        'PUT' => await _httpClient.put(
          uri,
          headers: headers,
          body: encodedBody,
        ),
        'PATCH' => await _httpClient.patch(
          uri,
          headers: headers,
          body: encodedBody,
        ),
        'DELETE' => await _httpClient.delete(
          uri,
          headers: headers,
          body: encodedBody,
        ),
        _ => throw ArgumentError.value(
          method,
          'method',
          'Unsupported HTTP method.',
        ),
      };
    } on BackendApiException {
      rethrow;
    } catch (_) {
      throw const BackendApiException(
        statusCode: 0,
        businessCode: 'NETWORK_UNAVAILABLE',
        message:
            'Chưa kết nối được máy chủ. Bạn kiểm tra mạng rồi thử lại nhé.',
      );
    }
  }

  Future<http.StreamedResponse> _sendMultipart(
    String path, {
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String fieldName,
  }) async {
    if (!path.startsWith('/api/v1/')) {
      throw ArgumentError.value(path, 'path', 'Must use a versioned API path.');
    }
    final request = http.MultipartRequest('POST', _baseUri.resolve(path));
    request.headers['Accept'] = 'application/json';
    if (_session != null) {
      request.headers['Authorization'] = 'Bearer ${_session!.accessToken}';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );
    try {
      return await _httpClient.send(request);
    } on BackendApiException {
      rethrow;
    } catch (_) {
      throw const BackendApiException(
        statusCode: 0,
        businessCode: 'NETWORK_UNAVAILABLE',
        message: 'Chưa kết nối được với máy chủ. Vui lòng thử lại.',
      );
    }
  }

  Future<http.StreamedResponse> _sendBinary(String method, String path) async {
    if (!path.startsWith('/api/v1/')) {
      throw ArgumentError.value(path, 'path', 'Must use a versioned API path.');
    }
    final request = http.Request(method, _baseUri.resolve(path));
    request.headers['Accept'] = '*/*';
    if (_session != null) {
      request.headers['Authorization'] = 'Bearer ${_session!.accessToken}';
    }
    try {
      return await _httpClient.send(request);
    } catch (_) {
      throw const BackendApiException(
        statusCode: 0,
        businessCode: 'NETWORK_UNAVAILABLE',
        message: 'Chưa kết nối được với máy chủ. Vui lòng thử lại.',
      );
    }
  }

  Future<http.StreamedResponse> _sendStream(
    String method,
    String path, {
    Object? body,
    required bool authenticated,
  }) async {
    final uri = _baseUri.resolve(path);
    final request = http.Request(method.toUpperCase(), uri)
      ..headers['Accept'] = 'application/x-ndjson'
      ..headers['Cache-Control'] = 'no-cache';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    if (authenticated && _session != null) {
      request.headers['Authorization'] = 'Bearer ${_session!.accessToken}';
    }
    try {
      return await _httpClient.send(request);
    } catch (_) {
      throw const BackendApiException(
        statusCode: 0,
        businessCode: 'NETWORK_UNAVAILABLE',
        message:
            'Chưa kết nối được máy chủ. Bạn kiểm tra mạng rồi thử lại nhé.',
      );
    }
  }

  Object? _readResponse(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final envelope = decoded is Map
        ? Map<String, Object?>.from(decoded)
        : const <String, Object?>{};
    final success = envelope['success'] == true;
    if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
      throw BackendApiException(
        statusCode: response.statusCode,
        businessCode: envelope['businessCode']?.toString() ?? 'BACKEND_ERROR',
        message:
            envelope['message']?.toString() ??
            'Máy chủ chưa thể xử lý yêu cầu này. Bạn thử lại sau nhé.',
      );
    }
    return envelope['data'];
  }

  Future<void> _setSession(BackendAuthSession? session) async {
    _session = session;
    if (session == null) {
      await _sessionStore.clear();
    } else {
      await _sessionStore.write(jsonEncode(session.toJson()));
    }
    _authChanges.add(session?.userId);
  }

  Future<void> _clearSession() async => _setSession(null);

  void close() {
    _httpClient.close();
    unawaited(_authChanges.close());
  }
}

Uri _validateBaseUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !uri.hasAuthority ||
      uri.userInfo.isNotEmpty ||
      uri.query.isNotEmpty ||
      uri.fragment.isNotEmpty ||
      uri.path.isNotEmpty && uri.path != '/') {
    throw ArgumentError.value(value, 'baseUrl', 'Backend URL is invalid.');
  }
  final isLocal =
      uri.host == 'localhost' ||
      uri.host == '127.0.0.1' ||
      uri.host == '10.0.2.2' ||
      uri.host == '::1';
  if (uri.scheme != 'https' && !(isLocal && uri.scheme == 'http')) {
    throw ArgumentError.value(value, 'baseUrl', 'HTTPS is required.');
  }
  return uri.replace(path: '', query: '', fragment: '');
}
