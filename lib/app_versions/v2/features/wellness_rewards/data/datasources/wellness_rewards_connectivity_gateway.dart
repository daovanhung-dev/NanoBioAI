import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class WellnessRewardsConnectivityGateway {
  Future<bool> hasNetworkTransport();

  Stream<bool> get networkAvailable;
}

class ConnectivityPlusWellnessRewardsConnectivityGateway
    implements WellnessRewardsConnectivityGateway {
  ConnectivityPlusWellnessRewardsConnectivityGateway({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hasNetworkTransport() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((value) => value != ConnectivityResult.none);
  }

  @override
  Stream<bool> get networkAvailable async* {
    yield await hasNetworkTransport();
    yield* _connectivity.onConnectivityChanged.map(
      (results) => results.any((value) => value != ConnectivityResult.none),
    );
  }
}
