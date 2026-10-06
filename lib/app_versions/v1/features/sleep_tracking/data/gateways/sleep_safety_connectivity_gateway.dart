import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class SleepSafetyConnectivityGateway {
  Future<bool> hasNetworkTransport();
  Stream<bool> get networkAvailable;
}

class ConnectivityPlusSleepSafetyGateway
    implements SleepSafetyConnectivityGateway {
  ConnectivityPlusSleepSafetyGateway({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hasNetworkTransport() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((value) => value != ConnectivityResult.none);
  }

  @override
  Stream<bool> get networkAvailable => _connectivity.onConnectivityChanged.map(
    (results) => results.any((value) => value != ConnectivityResult.none),
  );
}
