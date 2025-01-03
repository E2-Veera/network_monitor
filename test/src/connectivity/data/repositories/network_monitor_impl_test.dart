import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:network_monitor/network_monitor_package.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mockito/mockito.dart';

import 'network_monitor_impl_test.mocks.dart';



@GenerateMocks([http.Client])

const List<ConnectivityResult> kCheckConnectivityResult = [
  ConnectivityResult.wifi
];

class MockConnectivityPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {
  @override
  Future<ConnectivityResult> checkConnectivity() async {
    return kCheckConnectivityResult.first;
  }
}

void main() {
    TestWidgetsFlutterBinding.ensureInitialized();
   late Connectivity mockConnectivity;
    MockConnectivityPlatform fakePlatform;
  late MockClient mockHttpClient;
  late NetworkMonitor networkMonitor;

  setUp(() {
    fakePlatform = MockConnectivityPlatform();
    ConnectivityPlatform.instance = fakePlatform;
    mockConnectivity = Connectivity();
    mockHttpClient = MockClient();
    networkMonitor = NetworkMonitor();
  });

  tearDown(() {
    networkMonitor.dispose();
  });

  group('getConnectionType', () {
    test('returns ConnectionType.wifi when connectivity result is wifi', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);

      final connectionType = await networkMonitor.getConnectionType();

      expect(connectionType, ConnectionType.wifi);
    });

    test('returns ConnectionType.none when connectivity result is none', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.none);

      final connectionType = await networkMonitor.getConnectionType();

      expect(connectionType, ConnectionType.none);
    });
  });

  group('hasInternetAccess', () {
    test('returns true if a test URL responds with status 200', () async {
      when(mockHttpClient.get('https://example.com' as Uri)).thenAnswer((_) async => http.Response('OK', 200));

      final hasInternet = await networkMonitor.hasInternetAccess(testUrls: ['https://example.com']);

      expect(hasInternet, true);
    });

    test('returns false if all test URLs fail', () async {
      when(mockHttpClient.get('https://example.com' as Uri)).thenThrow(Exception('Connection failed'));

      final hasInternet = await networkMonitor.hasInternetAccess(testUrls: ['https://example.com']);

      expect(hasInternet, false);
    });
  });

  group('getNetworkSpeed', () {
    test('calculates average speed for successful requests', () async {
      when(mockHttpClient.get('https://example.com' as Uri)).thenAnswer((_) async {
        return http.Response('OK', 200, headers: {'content-length': '10000'});
      });

      final speed = await networkMonitor.getNetworkSpeed(testUrls: ['https://example.com']);

      expect(speed, greaterThan(0));
    });

    test('returns 0 if no successful requests', () async {
      when(mockHttpClient.get('https://example.com' as Uri)).thenThrow(Exception('Connection failed'));

      final speed = await networkMonitor.getNetworkSpeed(testUrls: ['https://example.com']);

      expect(speed, 0.0);
    });
  });

  group('monitorNetwork', () {
    test('updates network status when connection type changes', () async {
      final controller = StreamController<ConnectivityResult>.broadcast();
      when(mockConnectivity.onConnectivityChanged).thenAnswer((_) => controller.stream);
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      when(mockHttpClient.get('https://example.com' as Uri)).thenAnswer((_) async => http.Response('OK', 200));

      final statusStream = networkMonitor.networkStatusStream;
      expectLater(
        statusStream,
        emits(predicate<NetworkStatus>((status) => status.connectionType == ConnectionType.wifi))
      );

      controller.add(ConnectivityResult.wifi);
    });
  });
}
