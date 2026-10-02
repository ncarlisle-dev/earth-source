/// Thrown whenever a network request fails or an unexpected response is 
/// received.
class NetworkException implements Exception
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
  /// Indicates the client is in the process of checking their status with
  /// the server.
  pinging,
}

class ConnectionSpec {
  String ipAddress;
  int port;
  DateTime createdAt;
  DateTime? lastUsed;
  ConnectionStatus status;

  ConnectionSpec(
    this.ipAddress,
    this.port,
    this.createdAt,
    this.lastUsed,
    this.status
  );
}

class DirectoryItem {
  String name;
  bool isFile;
  int size;
  DateTime lastModified;

  DirectoryItem(
    this.name,
    this.isFile,
    this.size,
    this.lastModified,
  );
}