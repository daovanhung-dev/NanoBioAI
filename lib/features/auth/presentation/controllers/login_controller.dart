import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/repositories/auth_repository.dart';

class LoginController
    extends StateNotifier<AsyncValue<void>> {

  final AuthRepository repository;

  LoginController(this.repository)
      : super(const AsyncData(null));

  Future<void> login({
    required String email,
    required String password,
  }) async {

    state = const AsyncLoading();

    try {

      await repository.login(
        email: email,
        password: password,
      );

      state = const AsyncData(null);

    } catch (e, st) { 

      state = AsyncError(e, st);

    }
  }
}