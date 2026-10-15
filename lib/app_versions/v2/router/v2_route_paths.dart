import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/constants/routes/wellness_rewards_route_paths.dart';

abstract class V2RoutePaths {
  static const home = '/v2';
  static const healthScore = '/v2/health-score';
  static const wellnessRewards = WellnessRewardsRoutePaths.page;
  static const payments = '/v2/payments';
  static const sale = '/v2/sale';
  static const authGate = AuthRoutePaths.authGate;
  static const login = AuthRoutePaths.login;
  static const register = AuthRoutePaths.register;
  static const forgotPassword = AuthRoutePaths.forgotPassword;
  static const resetPassword = AuthRoutePaths.resetPassword;
  static const authCallback = AuthRoutePaths.authCallback;
}
