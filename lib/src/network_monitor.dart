part of '../network_monitor_package.dart';

class NetworkMonitor {
  // Singleton Pattern
  factory NetworkMonitor() => _instance;
  static final _instance = NetworkMonitor.createInstance();

  /// Default intervals
  static const _defaultStatusCheckInterval = Duration(seconds: 10);
  static const _defaultSpeedCheckInterval = Duration(seconds: 5);

  /// Network Request Options
  final List<NetworkRequestOption> _defaultCheckOptions = [
    NetworkRequestOption(uri: Uri.parse('https://one.one.one.one')),
    NetworkRequestOption(uri: Uri.parse('https://icanhazip.com/')),
    NetworkRequestOption(uri: Uri.parse('https://jsonplaceholder.typicode.com/todos/1')),
    NetworkRequestOption(uri: Uri.parse('https://reqres.in/api/users/1')),
  ];
  late List<NetworkRequestOption> _networkRequestOptions;
  final _urls = const [
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
  ];

  // Controllers and Timers
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  late final StreamController<SpeedAndQuality> _networkSpeedController = StreamController<SpeedAndQuality>.broadcast();
  Timer? _internetSpeedTimer;
  Timer? _internetStatusTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Configuration Variables
  Duration _internetStatusInterval;
  Duration _internetSpeedInterval;
  final bool enableStrictMode;
  final bool networkSpeedEnabled;
  ConnectionStatus? _lastStatus;

  // Constructor
  NetworkMonitor.createInstance({
    Duration? internetStatusInterval,
    Duration? networkSpeedInterval,
    List<NetworkRequestOption>? customCheckOptions,
    bool useDefaultOptions = true,
    this.enableStrictMode = false,
    this.networkSpeedEnabled = false,
  })  : _internetStatusInterval = internetStatusInterval ?? _defaultStatusCheckInterval,
        _internetSpeedInterval = networkSpeedInterval ?? _defaultSpeedCheckInterval,
        assert(
          useDefaultOptions || customCheckOptions?.isNotEmpty == true,
          'You must provide a list of options if you are not using the default ones.',
        ) {
    _networkRequestOptions = [
      if (useDefaultOptions) ..._defaultCheckOptions,
      if (customCheckOptions != null) ...customCheckOptions,
    ];

    _initializeControllers();
  }

  // Initialization Methods
  void _initializeControllers() {
    if (networkSpeedEnabled) {
      _networkSpeedController.onListen = _startSpeedMonitoring;
      _networkSpeedController.onCancel = disposeSpeed;
    }
    _statusController.onListen = _updateInternetStatus;
    _statusController.onCancel = _cancelStatusListener;
  }

  // Connectivity Monitoring
  Future<ConnectionType> get connectionType async {
    final result = await Connectivity().checkConnectivity();
    return _mapConnectivityResultToConnectionType(result);
  }

  Future<bool> get isOnline async {
    final completer = Completer<bool>();
    int remainingChecks = _networkRequestOptions.length;
    int successCount = 0;

    for (final option in _networkRequestOptions) {
      unawaited(
        _checkReachabilityFor(option).then((result) {
          if (result.isSuccess) successCount += 1;
          remainingChecks -= 1;

          if (!completer.isCompleted) {
            if (!enableStrictMode && result.isSuccess) completer.complete(true);
            if (enableStrictMode && remainingChecks == 0) completer.complete(successCount == _networkRequestOptions.length);
            if (!enableStrictMode && remainingChecks == 0) completer.complete(false);
          }
        }),
      );
    }

    return completer.future;
  }

  // Speed Monitoring
  Stream<SpeedAndQuality> get onChange {
    if (!networkSpeedEnabled) {
      throw StateError(
        'Network speed monitoring is disabled. Enable it by setting networkSpeedEnabled: true.',
      );
    }
    return _networkSpeedController.stream;
  }

  Future<SpeedAndQuality> currentSpeedAndQuality({required Duration interval}) async {
    SpeedAndQuality currentValue;

    final speed = await _averageSpeedOverInterval(urls: _urls, interval: interval);
    final quality = _calculateQualityOfInternet(speed);
    currentValue = SpeedAndQuality(speed: speed, quality: quality);
    return currentValue;
  }

  Future<double> _networkSpeed({required List<String> urls}) async {
    double totalSpeed = 0.0;
    int successfulTests = 0;

    for (String url in urls) {
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

  void _startSpeedMonitoring() {
    _internetSpeedTimer?.cancel();
    _internetSpeedTimer = Timer.periodic(_internetSpeedInterval, (_) async => await _updateSpeed());
  }

  Future<void> _updateSpeed() async {
    if (networkSpeedEnabled && _networkSpeedController.hasListener) {
      final speed = await _networkSpeed(urls: _urls);
      final quality = _calculateQualityOfInternet(speed);
      final speedAndQualtiy = SpeedAndQuality(speed: speed, quality: quality);
      _networkSpeedController.add(speedAndQualtiy);
    }
  }


  Future<double> _averageSpeedOverInterval({
  required List<String> urls,
  required Duration interval,
}) async {
  final stopwatch = Stopwatch()..start();
  final List<double> speedMeasurements = [];

  while (stopwatch.elapsed < interval) {
    final speed = await _networkSpeed(urls: urls);
    speedMeasurements.add(speed);
    await Future.delayed(const Duration(seconds: 1)); // Wait 1 second before the next measurement
  }

  stopwatch.stop();

  if (speedMeasurements.isNotEmpty) {
    final totalSpeed = speedMeasurements.reduce((a, b) => a + b);
    final averageSpeed = totalSpeed / speedMeasurements.length;
    return double.parse(averageSpeed.toStringAsFixed(2)); // Round to 2 decimal places
  }

  return 0.0; // Return 0 if no speed measurements were collected
}

InternetQuality _calculateQualityOfInternet(double speed) {
  switch (speed) {
    case double value when value > 15:
      return InternetQuality.excellent;
    case double value when value >= 10:
      return InternetQuality.good;
    case double value when value >= 5:
      return InternetQuality.average;
    case double value when value <= 0.5:
      return InternetQuality.poor;
    case 0:
      return InternetQuality.none;
    default:
      return InternetQuality.none;
  }
}


  // Status Updates
  Future<ConnectionStatus> get internetStatus async => await isOnline ? ConnectionStatus.connected : ConnectionStatus.disconnected;

  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;

  Future<void> _updateInternetStatus() async {
    _startListeningToConnectivityChanges();
    _internetStatusTimer?.cancel();

    final currentStatus = await internetStatus;
    if (_lastStatus != currentStatus && _statusController.hasListener) {
      _statusController.add(currentStatus);
    }

    _internetStatusTimer = Timer(_internetStatusInterval, _updateInternetStatus);
    _lastStatus = currentStatus;
  }

  void _cancelStatusListener() {
    if (!_statusController.hasListener) {
      _connectivitySubscription?.cancel();
      _connectivitySubscription = null;
      _internetStatusTimer?.cancel();
      _internetStatusTimer = null;
      _lastStatus = null;
    }
  }

  void _startListeningToConnectivityChanges() {
    if (_connectivitySubscription != null) return;
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((_) => _updateInternetStatus());
  }

  // Utility Methods
  Future<NetworkRequestResult> _checkReachabilityFor(NetworkRequestOption option) async {
    try {
      final response = await http.head(option.uri, headers: option.headers).timeout(option.timeout);
      return NetworkRequestResult(option: option, isSuccess: option.responseStatusFn(response));
    } catch (_) {
      return NetworkRequestResult(option: option, isSuccess: false);
    }
  }

  ConnectionType _mapConnectivityResultToConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.bluetooth:
        return ConnectionType.bluetooth;
      case ConnectivityResult.vpn:
        return ConnectionType.vpn;
      case ConnectivityResult.other:
        return ConnectionType.other;
      default:
        return ConnectionType.none;
    }
  }

  void disposeStatus() {
    _internetStatusTimer?.cancel();
    _statusController.close();
    _connectivitySubscription?.cancel();
  }

  void disposeSpeed() {
    _internetSpeedTimer?.cancel();
    _networkSpeedController.close();
  }
}
