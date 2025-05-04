import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool isValid;
  final String? validationMessage;
  final VoidCallback? onPaste;
  final String? Function(String)? validator;
  final bool obscureText;
  final int? maxLines;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool isPassword;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    required this.isValid,
    this.validationMessage,
    this.onPaste,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: isValid ? colorScheme.primary : colorScheme.outline,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                      color: isValid ? colorScheme.primary : colorScheme.outline,
                    ),
                    onPressed: onSuffixIconPressed ?? onPaste,
                    tooltip: onSuffixIconPressed != null ? 'Paste from clipboard' : null,
                  )
                : null,
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