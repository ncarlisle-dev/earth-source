/// Thrown whenever a network request fails or an unexpected response is 
/// received.
abstract class NetworkException implements Exception
{
  /// The error message.
  final String message;

  /// The status code sent back by the server, if applicable.
  final int? statusCode;

  const NetworkException(this.message, this.statusCode);

  @override
  String toString()
    => message;
}

class ApiNetworkException extends NetworkException {
  const ApiNetworkException(super.message, super.statusCode);
}

class AirdroidNetworkException extends NetworkException {
  const AirdroidNetworkException(super.message, super.statusCode);
}

/// The current state of a connection.
enum ConnectionStatus {
  /// Indicates the connection is heading towards [disconnected].
  disconnecting,
  /// Indicates that there is no connection and no server calls may be made.
  disconnected,
  /// Indicates the connection is heading toward [connected].
  connecting,
  /// Indicates the connection is up and running; server calls may be made.
  connected,
}