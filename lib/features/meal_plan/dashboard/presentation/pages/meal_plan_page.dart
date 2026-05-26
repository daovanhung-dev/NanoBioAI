import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';

// import controller provider của bạn
import 'package:nano_app/features/meal_plan/dashboard/presentation/controllers/meal_plan_controller.dart';

class MealPlanPage extends ConsumerWidget {
  const MealPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealState = ref.watch(mealPlanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(mealPlanControllerProvider.notifier).refreshMealPlans();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: mealState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Đã xảy ra lỗi:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (meals) {
          if (meals.isEmpty) {
            return const Center(
              child: Text('Chưa có dữ liệu meal plan'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(mealPlanControllerProvider.notifier)
                  .refreshMealPlans();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: meals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return MealPlanCard(meal: meal);
              },
            ),
          );
        },
      ),
    );
  }
}

class MealPlanCard extends StatelessWidget {
  final MealPlanModel meal;

  const MealPlanCard({
    super.key,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.mealName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip('Type: ${meal.mealType}'),
                          _chip('Date: ${meal.planDate}'),
                          _chip('Order: ${meal.mealOrder}'),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _statusChip(
                      label: meal.isCompleted ? 'Completed' : 'Pending',
                      color: meal.isCompleted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _statusChip(
                      label: meal.aiGenerated ? 'AI' : 'Manual',
                      color: meal.aiGenerated ? Colors.blue : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              meal.description,
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),
            const Divider(),

            _sectionTitle('Nutrition'),
            const SizedBox(height: 8),
            _nutritionGrid(meal),

            const SizedBox(height: 16),
            const Divider(),

            _sectionTitle('Water'),
            const SizedBox(height: 8),
            _infoRow('Water (ml)', '${meal.waterMl} ml'),

            const SizedBox(height: 16),
            const Divider(),

            _sectionTitle('Metadata'),
            const SizedBox(height: 8),
            _infoRow('ID', meal.id),
            _infoRow('User ID', meal.userId ?? 'null'),
            _infoRow('Created At', meal.createdAt),
            _infoRow('Updated At', meal.updatedAt),
          ],
        ),
      ),
    );
  }

  Widget _nutritionGrid(MealPlanModel meal) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;

        final items = [
          _nutritionItem('Calories', '${meal.calories} kcal'),
          _nutritionItem('Protein', '${meal.protein} g'),
          _nutritionItem('Carbs', '${meal.carbs} g'),
          _nutritionItem('Fat', '${meal.fat} g'),
          _nutritionItem('Fiber', '${meal.fiber} g'),
        ];

        if (isWide) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items
                .map(
                  (item) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: item,
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: item,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _nutritionItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _chip(String label) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _statusChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}