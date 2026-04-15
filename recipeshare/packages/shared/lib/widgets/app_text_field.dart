import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.autofillHints,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.forceShowSoftKeyboardOnTap = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Iterable<String>? autofillHints;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool forceShowSoftKeyboardOnTap;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      validator: validator,
      onChanged: onChanged,
      autofillHints: autofillHints,
      enabled: enabled,
      onTap: forceShowSoftKeyboardOnTap
          ? () => SystemChannels.textInput.invokeMethod<void>('TextInput.show')
          : null,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
