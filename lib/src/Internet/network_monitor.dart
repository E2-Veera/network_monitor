part of '../../network_monitor_package.dart';

/// A utility class for checking internet connectivity status.
///
/// This class provides functionality to monitor and verify internet
/// connectivity by checking reachability to various [Uri]s. It relies on the
/// [connectivity_plus] package for listening to connectivity changes and the
/// [http][http_link] package for making network requests.
///
/// [connectivity_plus]: https://pub.dev/packages/connectivity_plus
/// [http_link]: https://pub.dev/packages/http
///
/// <br />
///
/// ## Usage
///
/// <hr />
///
/// ### Checking for internet connectivity
///
/// ```dart
/// import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
///
/// bool result = await InternetConnection().hasInternetAccess;
/// ```
///
/// <br />
///
/// ### Listening for internet connectivity changes
///
/// ```dart
/// import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
///
/// final listener = InternetConnection().onStatusChange.listen(
///   (InternetStatus status) {
///     switch (status) {
///       case InternetStatus.connected:
///         // The internet is now connected
///         break;
///       case InternetStatus.disconnected:
///         // The internet is now disconnected
///         break;
///     }
///   },
/// );
/// ```
///
/// Don't forget to cancel the subscription when it is no longer needed. This
/// will prevent memory leaks and free up resources.
///
/// ```dart
/// listener.cancel();
/// ```
class NetworkMonitor {

  factory NetworkMonitor() => _instance;


  /// The default check interval duration.
  static const _defaultCheckInterval = Duration(seconds: 10);

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
      uri: Uri.parse('https://reqres.in/api/users/1'),
    ),
  ];

  late List<NetworkRequestOption> _networkRequestOptions;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  static final _instance = NetworkMonitor.createInstance();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Duration _checkInterval;
  final bool enableStrictCheck;
  ConnectionStatus? _lastStatus;
  Timer? _timerHandle;


  NetworkMonitor.createInstance({
    Duration? checkInterval,
    List<NetworkRequestOption>? customCheckOptions,
    bool useDefaultOptions = true,
    this.enableStrictCheck = false,
  })  : _checkInterval = checkInterval ?? _defaultCheckInterval,
        assert(
        useDefaultOptions || customCheckOptions?.isNotEmpty == true,
        'You must provide a list of options if you are not using the '
            'default ones.',
        ) {
    _networkRequestOptions = [
      if (useDefaultOptions) ..._defaultCheckOptions,
      if (customCheckOptions != null) ...customCheckOptions,
    ];

    _statusController.onListen = _maybeEmitStatusUpdate;
    _statusController.onCancel = _handleStatusChangeCancel;
  }


  Future<NetworkRequestResult> _checkReachabilityFor(
      NetworkRequestOption option,
      ) async {
    try {
      final response = await http
          .head(option.uri, headers: option.headers)
          .timeout(option.timeout);

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
    _checkInterval = duration;
    _timerHandle?.cancel();
    _timerHandle = Timer(_checkInterval, _maybeEmitStatusUpdate);
  }

  Duration get checkInterval => _checkInterval;

  Future<bool> get hasInternetAccess async {
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

          if (!enableStrictCheck && result.isSuccess) {
            // Return true immediately if not in strict mode and a success is found.
            completer.complete(true);
          } else if (enableStrictCheck && remainingChecks == 0) {
            // In strict mode, complete only when all checks are done.
            completer.complete(successCount == _networkRequestOptions.length);
          } else if (!enableStrictCheck && remainingChecks == 0) {
            // In non-strict mode, complete as false if no success is found.
            completer.complete(false);
          }
        }),
      );
    }

    return completer.future;
  }

  Future<ConnectionStatus> get internetStatus async => await hasInternetAccess
      ? ConnectionStatus.connected
      : ConnectionStatus.disconnected;

  /// The result of the last attempt to check the internet status.
  ConnectionStatus? get lastTryResults => _lastStatus;

  /// Stream that emits internet connection status changes.
  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;

  Future<void> _maybeEmitStatusUpdate() async {
    _startListeningToConnectivityChanges();
    _timerHandle?.cancel();

    final currentStatus = await internetStatus;

    if (!_statusController.hasListener) return;

    if (_lastStatus != currentStatus && _statusController.hasListener) {
      _statusController.add(currentStatus);
    }

    _timerHandle = Timer(_checkInterval, _maybeEmitStatusUpdate);

    _lastStatus = currentStatus;
  }

  
  void _handleStatusChangeCancel() {
    if (_statusController.hasListener) return;

    _connectivitySubscription?.cancel().then((_) {
      _connectivitySubscription = null;
    });
    _timerHandle?.cancel();
    _timerHandle = null;
    _lastStatus = null;
  }

  /// Starts listening to connectivity changes.
  void _startListeningToConnectivityChanges() {
    if (_connectivitySubscription != null) return;
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (_) {
        if (_statusController.hasListener) {
          _maybeEmitStatusUpdate();
        }
      },
    );
  }
}
