import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    textField: true,
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
      ),
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      textInputAction: textInputAction,
    ),
  );
}
