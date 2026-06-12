import 'package:flutter/material.dart';

class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mình ở đây để lắng nghe')),
      body: const Center(
        child: Text(
          'Bạn sẽ sớm có thể trò chuyện với mình ngay tại đây.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
