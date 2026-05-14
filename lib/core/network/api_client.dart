import 'dart:convert';
import 'dart:io';

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  static const String tenantId = 'EDB4E319-4CCE-49CE-B877-275C8A8E5568';

  ApiClient({
    required this.baseUrl,
    required this.tokenUrl,
    required this.dataCoreUrl,
    required this.snQueryUrl,
    required this.slsnBusinessUrl,
    required this.notificationUrl,
    required this.dfsBaseUrl,
    required this.originUrl,
    required this.storageServiceUrl,
    required this.dmsServiceUrl,
    required this.aggregatorUrl,
    required this.mailServiceUrl,
  });

  final String baseUrl;
  final String tokenUrl;
  final String dataCoreUrl;
  final String snQueryUrl;
  final String slsnBusinessUrl;
  final String notificationUrl;
  final String dfsBaseUrl;
  final String originUrl;
  final String storageServiceUrl;
  final String dmsServiceUrl;
  final String aggregatorUrl;
  final String mailServiceUrl;

  // Returns the new access token after a successful refresh, or null to skip retry.
  Future<String?> Function()? _onUnauthorized;

  String? resolveProfileImageUrl(String? imagePath) {
    final value = imagePath?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('data:image')) return value;
    if (value.startsWith('//')) return 'https:$value';

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final parts = value.split('/');
    final bucketBase = _storageBucketBaseUrl;
    if (bucketBase != null && parts.isNotEmpty && parts.first == tenantId) {
      return bucketBase + value;
    }

    return value;
  }

  String? get _storageBucketBaseUrl {
    final normalized = baseUrl.toLowerCase();
    if (normalized.contains('seliselocal')) {
      return 'https://slnfalcon.blob.core.windows.net/public-dev/';
    }
    if (normalized.contains('selisestage')) {
      return 'https://slnfalcon.blob.core.windows.net/public-stg/';
    }
    if (normalized.contains('seliseuat')) {
      return 'https://slnfalcon.blob.core.windows.net/public-uat/';
    }
    if (normalized.contains('filip.at')) {
      return 'https://slnfalcon.blob.core.windows.net/public-prod/';
    }
    return null;
  }

  void setUnauthorizedHandler(Future<String?> Function() handler) {
    _onUnauthorized = handler;
  }

  Future<int> putBytes({
    required String url,
    required List<int> bytes,
    String contentType = 'application/octet-stream',
    Map<String, String> extraHeaders = const <String, String>{},
  }) async {
    final client = HttpClient();
    client.connectionTimeout = _uploadTimeout;
    try {
      final request = await client.putUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      request.headers.set(HttpHeaders.contentLengthHeader, bytes.length);
      for (final entry in extraHeaders.entries) {
        request.headers.set(entry.key, entry.value);
      }
      request.add(bytes);
      final response = await request.close().timeout(_uploadTimeout);
      await response.drain<void>();
      return response.statusCode;
    } catch (_) {
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> getJson({
    required String url,
    Map<String, String> headers = const <String, String>{},
    bool suppressUnauthorizedHandling = false,
  }) async {
    final result = await _doGetJson(url: url, headers: headers);
    if (!suppressUnauthorizedHandling &&
        result['statusCode'] == HttpStatus.unauthorized) {
      final newToken = await _onUnauthorized?.call();
      if (newToken != null && newToken.isNotEmpty) {
        final retryHeaders = Map<String, String>.from(headers);
        retryHeaders['Authorization'] = 'bearer $newToken';
        return _doGetJson(url: url, headers: retryHeaders);
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> postForm({
    required String url,
    required Map<String, String> body,
    Map<String, String> headers = const <String, String>{},
    bool suppressUnauthorizedHandling = false,
  }) async {
    final result = await _doPostForm(url: url, body: body, headers: headers);
    if (!suppressUnauthorizedHandling &&
        result['statusCode'] == HttpStatus.unauthorized) {
      final newToken = await _onUnauthorized?.call();
      if (newToken != null && newToken.isNotEmpty) {
        final retryHeaders = Map<String, String>.from(headers);
        retryHeaders['Authorization'] = 'bearer $newToken';
        return _doPostForm(url: url, body: body, headers: retryHeaders);
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> postJson({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String> headers = const <String, String>{},
    bool suppressUnauthorizedHandling = false,
  }) async {
    final result = await _doPostJson(url: url, body: body, headers: headers);
    if (!suppressUnauthorizedHandling &&
        result['statusCode'] == HttpStatus.unauthorized) {
      final newToken = await _onUnauthorized?.call();
      if (newToken != null && newToken.isNotEmpty) {
        final retryHeaders = Map<String, String>.from(headers);
        retryHeaders['Authorization'] = 'bearer $newToken';
        return _doPostJson(url: url, body: body, headers: retryHeaders);
      }
    }
    return result;
  }

  // ── Internal request executors ──────────────────────────────────────────

  Future<Map<String, dynamic>> _doGetJson({
    required String url,
    required Map<String, String> headers,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = _requestTimeout;
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
      final response = await request.close().timeout(_requestTimeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      final dynamic decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const HttpException('Unexpected response format');
      }
      return <String, dynamic>{'statusCode': response.statusCode, 'body': decoded};
    } catch (_) {
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _doPostForm({
    required String url,
    required Map<String, String> body,
    required Map<String, String> headers,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = _requestTimeout;
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded',
      );
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
      request.write(Uri(queryParameters: body).query);
      final response = await request.close().timeout(_requestTimeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      final dynamic decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const HttpException('Unexpected response format');
      }
      return <String, dynamic>{'statusCode': response.statusCode, 'body': decoded};
    } catch (_) {
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _doPostJson({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = _requestTimeout;
    try {
      final request = await client.postUrl(Uri.parse(url));
      final bodyBytes = utf8.encode(jsonEncode(body));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.contentLengthHeader, bodyBytes.length);
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
      request.add(bodyBytes);
      final response = await request.close().timeout(_requestTimeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      final dynamic decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const HttpException('Unexpected response format');
      }
      return <String, dynamic>{'statusCode': response.statusCode, 'body': decoded};
    } catch (_) {
      rethrow;
    } finally {
      client.close(force: true);
    }
  }
}
