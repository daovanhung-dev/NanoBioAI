
import 'package:flutter/material.dart';
import '../../../shared/widgets/health_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BioAI Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: const [
            HealthCard(title: 'BMI', value: '22.1'),
            HealthCard(title: 'Sleep', value: '7.5h'),
            HealthCard(title: 'Stress', value: 'Low'),
            HealthCard(title: 'Calories', value: '1800'),
          ],
        ),
      ),
    );
  }
}
