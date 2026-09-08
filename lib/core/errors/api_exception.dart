/// A failure the app can reason about, mapped from whatever the transport
/// threw.
///
/// Repositories surface these instead of `DioException`, so nothing above the
/// data layer has to know which HTTP client is in use.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// Wording safe to show a user.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No usable connection — DNS, socket or the device being offline.
class NetworkUnavailable extends ApiException {
  const NetworkUnavailable([
    super.message = 'No internet connection. Check your network and retry.',
  ]);
}

/// The server took too long to connect, send or respond.
class RequestTimeout extends ApiException {
  const RequestTimeout([
    super.message = 'The server took too long to respond. Please retry.',
  ]);
}

/// 401/403 — the session is missing, expired or not permitted.
class Unauthorized extends ApiException {
  const Unauthorized([
    super.message = 'Your session has expired. Sign in again.',
  ]);
}

/// 404 — the resource is not there.
class NotFound extends ApiException {
  const NotFound([super.message = 'That record no longer exists.']);
}

/// Any other 4xx: the request itself was wrong.
class BadRequest extends ApiException {
  const BadRequest(
    this.statusCode, [
    super.message = 'That request could not be completed.',
  ]);

  final int statusCode;
}

/// 5xx — the fault is at the other end.
class ServerError extends ApiException {
  const ServerError(
    this.statusCode, [
    super.message = 'Something went wrong at our end. Please retry.',
  ]);

  final int statusCode;
}

/// The caller cancelled the request; usually not worth showing.
class RequestCancelled extends ApiException {
  const RequestCancelled([super.message = 'Request cancelled.']);
}

/// The response arrived but was not the shape the app expected.
class MalformedResponse extends ApiException {
  const MalformedResponse([
    super.message = 'The server sent something unexpected.',
  ]);
}

/// Nothing above matched.
class UnknownApiException extends ApiException {
  const UnknownApiException([
    super.message = 'Something went wrong. Please retry.',
  ]);
}
