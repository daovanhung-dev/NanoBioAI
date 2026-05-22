import 'package:flutter/material.dart';

class OnboardingTextField extends StatelessWidget {
  final String label;
  final String hint;
  final String initialValue;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const OnboardingTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}
