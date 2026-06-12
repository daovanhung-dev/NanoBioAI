import 'package:flutter/material.dart';

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Mình đang chuẩn bị một góc trò chuyện riêng để lắng nghe bạn. Hẹn bạn sớm nhé.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
