import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isValid;
  final String? validationMessage;
  final VoidCallback? onPaste;
  final String? Function(String)? validator;
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isValid,
    this.validationMessage,
    this.onPaste,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? colorScheme.primary : colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: colorScheme.surface,
            suffixIcon: onPaste != null
                ? IconButton(
                    icon: Icon(
                      Icons.paste,
                      color: isValid ? colorScheme.primary : colorScheme.outline,
                    ),
                    onPressed: onPaste,
                    tooltip: 'Paste from clipboard',
                  )
                : null,
          ),
        ),
        if (validationMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                validationMessage!,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}