import 'package:flutter/material.dart';

class SleepTrackingPage extends StatelessWidget {
  const SleepTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Mình đang chuẩn bị công cụ giúp bạn hiểu giấc ngủ của mình hơn. Chúng ta sẽ cùng ngủ ngon hơn nhé.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
