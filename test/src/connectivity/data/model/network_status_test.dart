import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/network_monitor.dart';

void main() {
  group('NetworkStatus', () {
    test('should create an instance with given parameters', () {
      final networkStatus = NetworkStatus(
        connectionType: ConnectionType.wifi,
        hasInternet: true,
        speedMbps: 50.0,
        quality: NetworkQuality.good,
      );

      expect(networkStatus.connectionType, ConnectionType.wifi);
      expect(networkStatus.hasInternet, true);
      expect(networkStatus.speedMbps, 50.0);
      expect(networkStatus.quality, NetworkQuality.good);
    });

    test('initial should return a default instance', () {
      final networkStatus = NetworkStatus.initial();

      expect(networkStatus.connectionType, ConnectionType.none);
      expect(networkStatus.hasInternet, false);
      expect(networkStatus.speedMbps, 0.0);
      expect(networkStatus.quality, NetworkQuality.none);
    });
  });
}