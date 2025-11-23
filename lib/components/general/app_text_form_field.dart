import 'package:flutter/material.dart';

typedef AppValidator = String? Function(String? value);
typedef AppFieldSubmitted = void Function(String value);

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onFieldSubmitted,
    this.validator,
    this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final AppFieldSubmitted? onFieldSubmitted;
  final AppValidator? validator;
  final String? label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(15);
    final outline = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );
    final focusedOutline = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: colorScheme.secondary,
        width: 2,
      ),
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      decoration: InputDecoration(
        floatingLabelStyle: TextStyle(
          color: colorScheme.secondary,
        ),
        enabledBorder: outline,
        focusedBorder: focusedOutline,
        labelText: label,
        hintText: hint,
        prefixIcon:
            icon != null ? Icon(icon, color: colorScheme.secondary) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
