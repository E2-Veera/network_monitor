import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../enum/enums.dart';
import '../../domain/repositories/network_monitor.dart';
import '../model/network_status.dart';
import 'package:http/http.dart' as http;

class NetworkMonitor implements NetworkMonitorPlugin {
  // Singleton instance
  static final NetworkMonitor _instance = NetworkMonitor._internal();

  // Factory constructor
  factory NetworkMonitor({int intervalSeconds = 3}) {
    _instance._intervalSeconds = intervalSeconds;
    return _instance;
  }

  // Private constructor
  NetworkMonitor._internal() {
    _networkStatusController = StreamController<NetworkStatus>.broadcast();
    monitorNetwork();
  }
  @override
  Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;

  final Connectivity _connectivity = Connectivity();
  late final StreamController<NetworkStatus> _networkStatusController;
  StreamSubscription<NetworkStatus>? _networkStatusSubscription;
  Timer? _updateTimer;
  ConnectionType _lastConnectionType = ConnectionType.none;
  bool _lastHasInternet = false;
  int _intervalSeconds = 3;

  /// The `monitorNetwork` function updates the network status periodically and listens for connectivity
  /// changes.
  @override
  void monitorNetwork() {
    _updateNetworkStatus();

    _connectivity.onConnectivityChanged.listen((result) {
      _updateNetworkStatus();
    });

    _updateTimer = Timer.periodic(Duration(seconds: _intervalSeconds), (_) {
      _updateNetworkStatus();
    });
  }

  /// The `_updateNetworkStatus` function checks for changes in network status and updates the network
  /// status controller if there are any changes.
  Future<void> _updateNetworkStatus() async {
    final connectionType = await getConnectionType();
    final hasInternet = await hasInternetAccess();
    final speedMbps = await getNetworkSpeed();
    final quality = getNetworkQuality(speedMbps);

    if (connectionType != _lastConnectionType || hasInternet != _lastHasInternet || speedMbps > 0) {
      _lastConnectionType = connectionType;
      _lastHasInternet = hasInternet;

      _networkStatusController.add(NetworkStatus(
        connectionType: connectionType,
        hasInternet: hasInternet,
        speedMbps: speedMbps,
        quality: quality,
      ));
    }
  }

  /// Returns the current connection type.
  ///
  /// This method uses the [_connectivity] plugin to check the current connectivity status.
  /// It returns a [Future] that resolves to a [ConnectionType] enum value representing the connection type.
  /// The possible connection types are:
  ///   - [ConnectionType.wifi]: Represents a Wi-Fi connection.
  ///   - [ConnectionType.mobile]: Represents a mobile data connection.
  ///   - [ConnectionType.ethernet]: Represents an Ethernet connection.
  ///   - [ConnectionType.bluetooth]: Represents a Bluetooth connection.
  ///   - [ConnectionType.VPN]: Represents a VPN connection.
  ///   - [ConnectionType.other]: Represents any other type of connection.
  ///   - [ConnectionType.none]: Represents no connection.
  ///
  /// Example usage:
  /// ```dart
  /// final connectionType = await getConnectionType();
  /// print(connectionType); // ConnectionType.wifi
  /// ```
  @override
  Future<ConnectionType> getConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.nobile;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.bluetooth:
        return ConnectionType.bluetooth;
      case ConnectivityResult.vpn:
        return ConnectionType.VPN;
      case ConnectivityResult.other:
        return ConnectionType.other;
      default:
        return ConnectionType.none;
    }
  }

  /// Checks if the device has internet access by making HTTP GET requests to a list of test URLs.
  /// Returns true if any of the requests receive a successful response (status code 200), otherwise returns false.
  /// The default test URLs are "https://www.google.com" and "https://www.microsoft.com", but you can provide custom URLs.
  /// Throws an exception if a request times out after 5 seconds.
  Future<bool> hasInternetAccess({List<String> testUrls = const ["https://www.google.com", "https://www.microsoft.com"]}) async {
    for (String url in testUrls) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          return true;
        }
      } catch (_) {
        // Continue to the next URL
      }
    }
    return false;
  }

  /// Calculates the average network speed by performing HTTP GET requests to a list of test URLs.
  /// The test URLs are provided as an optional parameter, with a default list of popular websites.
  /// The function measures the time taken to receive a response from each URL and calculates the speed in Mbps.
  /// The average speed is then calculated by summing up the speeds of all successful tests and dividing by the number of successful tests.
  /// If no successful tests are performed, the function returns 0.0.
  ///
  /// Example usage:
  /// ```dart
  /// double speed = await getNetworkSpeed();
  /// print('Average network speed: $speed Mbps');
  /// ```
  @override
  Future<double> getNetworkSpeed(
      {List<String> testUrls = const [
        "https://www.google.com",
        "https://www.microsoft.com",
        "https://www.apple.com",
        "https://www.cloudflare.com",
        "https://www.amazon.com",
        "https://www.facebook.com",
        "https://www.wikipedia.org",
        "https://www.youtube.com",
        "https://www.twitter.com",
        "https://www.linkedin.com",
      ]}) async {
    double totalSpeed = 0.0;
    int successfulTests = 0;

    for (String url in testUrls) {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        stopwatch.stop();
        if (response.statusCode == 200) {
          int bytes = response.contentLength ?? response.bodyBytes.length;
          double seconds = stopwatch.elapsedMilliseconds / 1000;
          double speedMbps = (bytes * 8) / (seconds * 1000000); // Convert to Mbps
          totalSpeed += speedMbps;
          successfulTests++;
        }
      } catch (_) {
        // Ignore errors
      }
    }

    if (successfulTests > 0) {
      double averageSpeed = totalSpeed / successfulTests;
      return double.parse(averageSpeed.toStringAsFixed(2)); // Round to 2 decimal places
    }

    return 0.0;
  }

  /// Determines the network quality based on the provided speed in Mbps.
  ///
  /// Returns [NetworkQuality.high] if the speed is greater than 50 Mbps.
  /// Returns [NetworkQuality.good] if the speed is greater than 20 Mbps.
  /// Returns [NetworkQuality.average] if the speed is greater than 5 Mbps.
  /// Returns [NetworkQuality.belowAverage] if the speed is greater than 0 Mbps.
  /// Returns [NetworkQuality.none] if the speed is 0 Mbps or lower.
  @override
  NetworkQuality getNetworkQuality(double speedMbps) {
    if (speedMbps > 50) {
      return NetworkQuality.high;
    } else if (speedMbps > 20) {
      return NetworkQuality.good;
    } else if (speedMbps > 5) {
      return NetworkQuality.average;
    } else if (speedMbps > 0) {
      return NetworkQuality.belowAverage;
    } else {
      return NetworkQuality.none;
    }
  }

  /// Start listening to the network status stream
  @override
  void start(void Function(NetworkStatus) onData) {
    stop(); // Ensure any previous subscription is canceled
    _networkStatusSubscription = networkStatusStream.listen(onData);
  }

  /// Stop listening to the network status stream
  @override
  void stop() {
    _networkStatusSubscription?.cancel();
    _networkStatusSubscription = null;
  }

  /// Disposes the network monitor by closing the network status controller,
  /// canceling the update timer, and stopping the subscription.
  @override
  void dispose() {
    _networkStatusController.close();
    _updateTimer?.cancel();
    stop(); // Clean up the subscription
  }
}
