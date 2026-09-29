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

typedef ConnectionEntry = ({
  String ipAddress,
  int port,
  DateTime createdAt,
  DateTime lastUsed,
  ConnectionStatus status,
});

typedef DirectoryItem = ({
  String name,
  bool isFile,
});