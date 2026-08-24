abstract class AdminRoutePaths {
  static const root = '/admin';
  static const login = '/admin/login';

  static const accounts = '/admin/accounts';
  static const createAccount = '/admin/accounts/create';
  static const upgradeAccount = '/admin/accounts/upgrade';
  static const saleReview = '/admin/sales/review';
  static const salePayouts = '/admin/sales/payouts';
  static const membershipReview = '/admin/memberships/review';

  // Legacy deep-links kept only for redirect compatibility.
  static const dashboard = '/admin/dashboard';
  static const users = '/admin/users';
  static const payments = '/admin/payments';
  static const sales = '/admin/sales';
  static const saleConversions = '/admin/sale-conversions';
  static const wellnessRewards = '/admin/wellness-rewards';
  static const reconciliation = '/admin/reconciliation';
  static const plans = '/admin/plans';
  static const reports = '/admin/reports';
  static const audit = '/admin/audit';
  static const config = '/admin/config';
}
