import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

/// Supplies the bearer token for outgoing requests, or null when signed out.
///
/// A callback rather than a stored string, so the client always reads the
/// current session instead of one captured at construction.
typedef TokenReader = String? Function();

/// The app's single configured HTTP client.
///
/// Everything network goes through here: one base URL, one set of timeouts,
/// one place that attaches the auth header, and one place that turns
/// transport errors into [ApiException]. Repositories call the helpers below
/// and map the decoded JSON onto their own models — nothing outside
/// `core/network` should import `package:dio`.
class DioClient {
  DioClient({String? baseUrl, TokenReader? readToken, Dio? dio})
    : _readToken = readToken,
      dio = dio ?? Dio() {
    this.dio.options = this.dio.options.copyWith(
      baseUrl: baseUrl ?? defaultBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      // Let every status through so the mapping below decides what is a
      // failure, rather than Dio throwing on some codes and not others.
      validateStatus: (_) => true,
    );

    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _readToken?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    if (kDebugMode) {
      this.dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  /// Override at build time:
  /// `flutter run --dart-define=API_BASE_URL=https://api.example.com/v1`
  ///
  /// The default is a placeholder — there is no backend yet, so any real call
  /// will fail until this is pointed somewhere.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.shaktisaree.local/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  /// Shared instance. Features that need their own (tests, a second host)
  /// construct a [DioClient] directly.
  static final DioClient shared = DioClient();

  final Dio dio;
  final TokenReader? _readToken;

  /// GET returning a JSON object.
  Future<Map<String, Object?>> getObject(
    String path, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) async {
    final data = await _send(
      () => dio.get<Object?>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
      ),
    );
    return _asObject(data);
  }

  /// GET returning a JSON array of objects.
  Future<List<Map<String, Object?>>> getList(
    String path, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) async {
    final data = await _send(
      () => dio.get<Object?>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
      ),
    );
    return _asList(data);
  }

  /// POST returning a JSON object.
  Future<Map<String, Object?>> postObject(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    final data = await _send(
      () => dio.post<Object?>(path, data: body, cancelToken: cancelToken),
    );
    return _asObject(data);
  }

  /// PATCH returning a JSON object.
  Future<Map<String, Object?>> patchObject(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    final data = await _send(
      () => dio.patch<Object?>(path, data: body, cancelToken: cancelToken),
    );
    return _asObject(data);
  }

  /// DELETE; the body is discarded.
  Future<void> delete(String path, {CancelToken? cancelToken}) async {
    await _send(() => dio.delete<Object?>(path, cancelToken: cancelToken));
  }

  /// Runs a request and reduces everything that can go wrong to an
  /// [ApiException], so no caller ever sees a [DioException].
  Future<Object?> _send(Future<Response<Object?>> Function() request) async {
    try {
      final response = await request();
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) return response.data;
      throw statusToException(status);
    } on DioException catch (error) {
      throw dioErrorToException(error);
    }
  }

  /// Maps an HTTP status onto the matching failure.
  @visibleForTesting
  static ApiException statusToException(int status) => switch (status) {
    401 || 403 => const Unauthorized(),
    404 => const NotFound(),
    >= 500 => ServerError(status),
    >= 400 => BadRequest(status),
    _ => const UnknownApiException(),
  };

  /// Maps a transport-level failure onto the matching [ApiException].
  @visibleForTesting
  static ApiException dioErrorToException(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const RequestTimeout(),
      DioExceptionType.connectionError => const NetworkUnavailable(),
      DioExceptionType.cancel => const RequestCancelled(),
      DioExceptionType.badCertificate => const NetworkUnavailable(
        'The server certificate could not be trusted.',
      ),
      DioExceptionType.badResponse => statusToException(
        error.response?.statusCode ?? 0,
      ),
      DioExceptionType.unknown =>
        error.error is FormatException
            ? const MalformedResponse()
            : const NetworkUnavailable(),
    };
  }

  static Map<String, Object?> _asObject(Object? data) {
    if (data is Map<String, Object?>) return data;
    if (data is Map) return data.cast<String, Object?>();
    throw const MalformedResponse('Expected a JSON object.');
  }

  static List<Map<String, Object?>> _asList(Object? data) {
    if (data is! List) {
      throw const MalformedResponse('Expected a JSON array.');
    }
    return [for (final item in data) _asObject(item)];
  }
}
