/// Represents the type of network connection.
enum ConnectionType {
  wifi, // Represents a WiFi connection.
  nobile, // Represents a mobile data connection.
  ethernet, // Represents an Ethernet connection.
  bluetooth, // Represents a Bluetooth connection.
  vpn, // Represents a VPN connection.
  other, // Represents other types of connections.
  none, VPN // Represents no connection.
}

/// Represents the quality of the network connection.
enum NetworkQuality {
  high, // Represents a high-quality network connection.
  good, // Represents a good-quality network connection.
  average, // Represents an average-quality network connection.
  belowAverage, // Represents a below-average-quality network connection.
  none // Represents no network connection.
}
