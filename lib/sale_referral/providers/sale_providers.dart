import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/sale_referral/data/datasources/sale_remote_datasource.dart';
import 'package:nano_app/sale_referral/data/datasources/supabase_sale_remote_datasource.dart';
import 'package:nano_app/sale_referral/data/device/sale_device_hash_store.dart';
import 'package:nano_app/sale_referral/data/repositories/sale_repository_impl.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/domain/repositories/sale_repository.dart';

final saleDeviceHashStoreProvider = Provider<SaleDeviceHashStore>((ref) {
  return SaleDeviceHashStore();
});

final saleDeviceHashProvider = FutureProvider<String>((ref) {
  return ref.watch(saleDeviceHashStoreProvider).readOrCreate();
});

final saleRemoteDatasourceProvider = Provider<SaleRemoteDatasource>((ref) {
  return const SupabaseSaleRemoteDatasource();
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepositoryImpl(
    datasource: ref.watch(saleRemoteDatasourceProvider),
  );
});

final saleStateProvider = FutureProvider<SaleState>((ref) {
  return ref.watch(saleRepositoryProvider).fetchSaleState();
});

final salePayoutProfileProvider = FutureProvider<SalePayoutProfile?>((
  ref,
) async {
  final state = await ref.watch(saleStateProvider.future);
  if (!state.isActive) {
    throw StateError('Sale payout profile requires active status.');
  }
  return ref.watch(saleRepositoryProvider).fetchPayoutProfile();
});

final saleDashboardProvider = FutureProvider<SaleDashboard>((ref) async {
  final state = await ref.watch(saleStateProvider.future);
  if (!state.isActive) {
    throw StateError('Sale dashboard requires active status.');
  }
  return ref.watch(saleRepositoryProvider).fetchDashboard();
});

final saleDirectCustomersProvider = FutureProvider<List<SaleDirectCustomer>>((
  ref,
) async {
  final state = await ref.watch(saleStateProvider.future);
  if (!state.isActive) {
    throw StateError('Sale direct customers require active status.');
  }
  return ref.watch(saleRepositoryProvider).fetchDirectCustomers();
});

final salePointLedgerProvider = FutureProvider<List<SalePointLedgerEntry>>((
  ref,
) async {
  final state = await ref.watch(saleStateProvider.future);
  if (!state.isActive) {
    throw StateError('Sale point ledger requires active status.');
  }
  return ref.watch(saleRepositoryProvider).fetchPointLedger();
});

final saleConversionsProvider = FutureProvider<List<SaleConversionRequest>>((
  ref,
) async {
  final state = await ref.watch(saleStateProvider.future);
  if (!state.isActive) {
    throw StateError('Sale conversions require active status.');
  }
  return ref.watch(saleRepositoryProvider).fetchConversionRequests();
});
