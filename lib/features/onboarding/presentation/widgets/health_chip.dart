import 'package:flutter/material.dart';

class HealthChip extends StatelessWidget {

  final String label;
  final bool selected;
  final VoidCallback onTap;

  const HealthChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4A90E2)
              : Colors.white,

          borderRadius: BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),

        child: Text(
          label,

          style: TextStyle(
            fontWeight: FontWeight.w600,
            color:
                selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}