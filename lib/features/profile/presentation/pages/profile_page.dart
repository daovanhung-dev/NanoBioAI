import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Hồ sơ của bạn đang được mình sắp xếp lại cho thật dễ xem. Mình sẽ sớm quay lại nhé.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
