part of '../network_monitor_package.dart';

enum ConnectionStatus {
  connected,
  disconnected,
}

enum InternetQuality { excellent, good, average, poor, none }

class SpeedAndQuality {
  final double speed;
  final InternetQuality quality;
  SpeedAndQuality({required this.speed, required this.quality});
}
