import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitor/network_monitor.dart';

final globalNetworkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
  NetworkMonitorPlugin monitor = NetworkMonitor();
  return NetworkStatusNotifier(monitor);
});

class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  final   NetworkMonitorPlugin _networkMonitor;
  StreamSubscription<NetworkStatus>? _subscription;

  NetworkStatusNotifier(this._networkMonitor) : super(NetworkStatus.initial()) {
    _subscription = _networkMonitor.networkStatusStream.listen((status) {
      state = status;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}