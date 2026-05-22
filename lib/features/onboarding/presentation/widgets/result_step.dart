import 'package:flutter/material.dart';

class ResultStep extends StatelessWidget {

  const ResultStep({super.key});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(24),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Container(
            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(24),
            ),

            child: const Column(
              children: [

                Text(
                  'Health Score',
                  style: TextStyle(fontSize: 20),
                ),

                SizedBox(height: 12),

                Text(
                  '78/100',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90E2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          const Text(
            '🎉 BioAI đã sẵn sàng đồng hành cùng bạn',
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}