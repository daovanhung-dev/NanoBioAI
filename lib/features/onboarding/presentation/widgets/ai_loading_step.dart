import 'package:flutter/material.dart';

class AILoadingStep extends StatelessWidget {

  const AILoadingStep({super.key});

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: const [

          CircularProgressIndicator(),

          SizedBox(height: 30),

          Text(
            '🧠 BioAI đang phân tích sức khỏe...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}