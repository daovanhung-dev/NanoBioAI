import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/models/user_model.dart';

void main() {
  test('UserModel maps subscription tier with default fallback', () {
    final model = UserModel.fromMap({
      'id': 'u1',
      'email': 'user@example.com',
      'full_name': 'User One',
      'subscription_tier': 'premium',
    });

    expect(model.subscriptionTier, 'premium');
    expect(model.toMap()['subscription_tier'], 'premium');

    final fallback = UserModel.fromMap({'id': 'u2'});
    expect(fallback.subscriptionTier, 'free');
  });
}
