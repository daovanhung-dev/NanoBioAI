import 'package:flutter/material.dart';

class AIGeneratingPage extends StatelessWidget {
  const AIGeneratingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const CircularProgressIndicator(),

              const SizedBox(height: 24),

              const Text(
                'AI đang tạo dữ liệu...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Vui lòng đợi trong giây lát',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}