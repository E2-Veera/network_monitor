
import '../../../../network_monitor.dart';

/// Represents the status of the network connection.
///
/// Creates a new instance of [NetworkStatus].
///
/// The parameters are:
/// * [connectionType]: The type of the network connection.
/// * [hasInternet]: Indicates whether the device has internet connectivity.
/// * [speedMbps]: The speed of the network connection in megabits per second.
/// * [quality]: The quality of the network connection.
class NetworkStatus {
  /// The type of the network connection.
  final ConnectionType connectionType;

  /// Indicates whether the device has internet connectivity.
  final bool hasInternet;

  /// The speed of the network connection in megabits per second.
  final double speedMbps;

  /// The quality of the network connection.
  final NetworkQuality quality;

  NetworkStatus({
    required this.connectionType,
    required this.hasInternet,
    required this.speedMbps,
    required this.quality,
  });



  static NetworkStatus initial() {
    return NetworkStatus(
      connectionType: ConnectionType.none,
      hasInternet: false,
      speedMbps: 0.0,
      quality: NetworkQuality.none,
    );
  }
}
