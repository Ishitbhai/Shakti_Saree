/// A failure the app can reason about, separate from whatever caused it.
///
/// Everything above the data layer catches these rather than something a
/// particular source throws: the in-memory repositories raise them for the
/// rules they enforce — a SKU already in use, a category that still holds
/// listings — and the tests raise the rest to put the failure and retry
/// states on screen.
///
/// The names borrow HTTP's vocabulary because it is a familiar way to say
/// what kind of failure something is, not because anything here makes a
/// request. Nothing in this app does.
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

/// Nothing above matched.
class UnknownApiException extends ApiException {
  const UnknownApiException([
    super.message = 'Something went wrong. Please retry.',
  ]);
}
