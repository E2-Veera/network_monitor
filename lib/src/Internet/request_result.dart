part of '../../network_monitor_package.dart';

class NetworkRequestResult {

  NetworkRequestResult({
    required this.option,
    required this.isSuccess,
  });

  final NetworkRequestOption option;
  final bool isSuccess;

  @override
  String toString() {
    return 'InternetCheckResult(\n'
        '  option: ${option.toString().replaceAll('\n', '\n  ')},\n'
        '  isSuccess: $isSuccess\n'
        ')';
  }
}
