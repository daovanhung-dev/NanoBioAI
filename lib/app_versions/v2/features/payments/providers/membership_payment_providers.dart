import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/create_membership_payment_request.dart';
import '../data/datasources/membership_payment_remote_datasource.dart';
import '../data/repositories/supabase_membership_payment_repository.dart';
import '../domain/repositories/membership_payment_repository.dart';

final membershipPaymentRemoteDatasourceProvider =
    Provider<MembershipPaymentRemoteDatasource>((ref) {
      return const SupabaseMembershipPaymentRemoteDatasource();
    });

final membershipPaymentRepositoryProvider =
    Provider<MembershipPaymentRepository>((ref) {
      return SupabaseMembershipPaymentRepository(
        datasource: ref.watch(membershipPaymentRemoteDatasourceProvider),
      );
    });

final createMembershipPaymentRequestProvider =
    Provider<CreateMembershipPaymentRequest>((ref) {
      return CreateMembershipPaymentRequest(
        repository: ref.watch(membershipPaymentRepositoryProvider),
      );
    });
