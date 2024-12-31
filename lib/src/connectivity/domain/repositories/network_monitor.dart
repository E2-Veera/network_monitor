import '../../../enum/enums.dart';
import '../../data/model/network_status.dart';

abstract class NetworkMonitorPlugin {
  /// A stream that emits [NetworkStatus] whenever the network status changes.
  Stream<NetworkStatus> get networkStatusStream;

  /// Starts monitoring the network status and invokes the provided [onData] callback whenever the status changes.
  void start(void Function(NetworkStatus) onData);

  /// Stops monitoring the network status.
  void stop();

  /// Disposes any resources used by the network monitor.
  void dispose();

  /// Initiates a network monitoring process.
  void monitorNetwork();

  /// Retrieves the current connection type.
  Future<ConnectionType> getConnectionType();

  /// Checks if there is internet access by performing a connectivity test to the specified [testUrls].
  Future<bool> hasInternetAccess({List<String> testUrls});

  /// Measures the network speed by performing speed tests to the specified [testUrls].
  Future<double> getNetworkSpeed({List<String> testUrls});

  /// Determines the network quality based on the provided [speedMbps].
  NetworkQuality getNetworkQuality(double speedMbps);
}
