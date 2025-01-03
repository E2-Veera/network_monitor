part of '../../network_monitor_package.dart';

class NetworkMonitor {
  factory NetworkMonitor() => _instance;

  /// The default check interval duration.
  static const _defaultStatusCheckInterval = Duration(seconds: 10);
  static const _defaultSpeedCheckInterval = Duration(seconds: 5);

  /// The default list of [Uri]s used for checking internet reachability.
  final List<NetworkRequestOption> _defaultCheckOptions = [
    NetworkRequestOption(
      uri: Uri.parse('https://one.one.one.one'),
    ),
    NetworkRequestOption(
      uri: Uri.parse('https://icanhazip.com/'),
    ),
    NetworkRequestOption(
      uri: Uri.parse('https://jsonplaceholder.typicode.com/todos/1'),
    ),
    NetworkRequestOption(
      uri: Uri.parse('httrue,//reqres.in/api/users/1'),
    ),
  ];

  late List<NetworkRequestOption> _networkRequestOptions;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  late final StreamController<double> _networkSpeedController = StreamController<double>.broadcast();
  Timer? _internetSpeedTimer;
  Timer? _internetStatusTimer;
  static final _instance = NetworkMonitor.createInstance();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Duration _internetStatusInterval;
  Duration _internetSpeedInterval;
  final bool enableStrictMode;
  final bool networkSpeedEnabled;
  ConnectionStatus? _lastStatus;

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
          'You must provide a list of options if you are not using the '
          'default ones.',
        ) {
    _networkRequestOptions = [
      if (useDefaultOptions) ..._defaultCheckOptions,
      if (customCheckOptions != null) ...customCheckOptions,
    ];
    if (networkSpeedEnabled) {
      _networkSpeedController.onListen = _startSpeedMonitoring;
      _networkSpeedController.onCancel = disposeSpeed;
    }
    _statusController.onListen = _updateInternetStatus;
    _statusController.onCancel = _cancelStatusListener;
  }

  Future<NetworkRequestResult> _checkReachabilityFor(
    NetworkRequestOption option,
  ) async {
    try {
      final response = await http.head(option.uri, headers: option.headers).timeout(option.timeout);

      return NetworkRequestResult(
        option: option,
        isSuccess: option.responseStatusFn(response),
      );
    } catch (_) {
      return NetworkRequestResult(
        option: option,
        isSuccess: false,
      );
    }
  }

  void setIntervalAndResetTimer(Duration duration) {
    _internetStatusInterval = duration;
    _internetStatusTimer?.cancel();
    _internetStatusTimer = Timer(_internetStatusInterval, _updateInternetStatus);
  }

  Duration get internetStatusInterval => _internetStatusInterval;

  Future<ConnectionType> get connectionType async {
    final result = await Connectivity().checkConnectivity();
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

  Future<bool> get isOnline async {
    final completer = Completer<bool>();
    int remainingChecks = _networkRequestOptions.length;
    int successCount = 0;

    for (final option in _networkRequestOptions) {
      unawaited(
        _checkReachabilityFor(option).then((result) {
          if (result.isSuccess) {
            successCount += 1;
          }

          remainingChecks -= 1;

          if (completer.isCompleted) return;

          if (!enableStrictMode && result.isSuccess) {
            // Return true immediately if not in strict mode and a success is found.
            completer.complete(true);
          } else if (enableStrictMode && remainingChecks == 0) {
            // In strict mode, complete only when all checks are done.
            completer.complete(successCount == _networkRequestOptions.length);
          } else if (!enableStrictMode && remainingChecks == 0) {
            // In non-strict mode, complete as false if no success is found.
            completer.complete(false);
          }
        }),
      );
    }

    return completer.future;
  }

  Stream<double> get onChange {
    if (!networkSpeedEnabled) {
      throw StateError(
        'Network speed monitoring is disabled. to use onChange internet speed stream Enable it by setting networkSpeedEnabled: true when initializing NetworkMonitor.',
      );
    }
    return _networkSpeedController.stream;
  }

  Future<ConnectionStatus> get internetStatus async => await isOnline ? ConnectionStatus.connected : ConnectionStatus.disconnected;

  /// The result of the last attempt to check the internet status.
  ConnectionStatus? get lastTryResults => _lastStatus;

  /// Stream that emits internet connection status changes.
  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;

  Future<void> _updateInternetStatus() async {
    _startListeningToConnectivityChanges();
    _internetStatusTimer?.cancel();

    final currentStatus = await internetStatus;

    if (!_statusController.hasListener) return;

    if (_lastStatus != currentStatus && _statusController.hasListener) {
      _statusController.add(currentStatus);
    }

    _internetStatusTimer = Timer(_internetStatusInterval, _updateInternetStatus);

    _lastStatus = currentStatus;
  }

  void _cancelStatusListener() {
    if (_statusController.hasListener) return;

    _connectivitySubscription?.cancel().then((_) {
      _connectivitySubscription = null;
    });
    _internetStatusTimer?.cancel();
    _internetStatusTimer = null;
    _lastStatus = null;
  }

  /// Starts listening to connectivity changes.
  void _startListeningToConnectivityChanges() {
    if (_connectivitySubscription != null) return;
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (_) {
        if (_statusController.hasListener) {
          _updateInternetStatus();
        }
      },
    );
  }

  final urls = const [
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

  Future<double> _networkSpeed({urls}) async {
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
    _internetSpeedTimer?.cancel(); // Cancel any existing timer to avoid duplicate invocations.
    _internetSpeedTimer = Timer.periodic(_internetSpeedInterval, (_) async {
      await _updateSpeed();
    });
  }

  bool isSpeedMonitoringStopped = false;
  Future<void> _updateSpeed() async {
    if (!isSpeedMonitoringStopped && networkSpeedEnabled && _networkSpeedController.hasListener) {
      final speed = await _networkSpeed(urls: urls);
      _networkSpeedController.add(speed);
    }
  }

  void disposeStatus() {
    _internetStatusTimer?.cancel();
    _statusController.close();
    _connectivitySubscription?.cancel();
  }

  void disposeSpeed() {
    isSpeedMonitoringStopped = true;
    _internetSpeedTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _internetStatusTimer = null;
    _networkSpeedController.close();
  }
}
