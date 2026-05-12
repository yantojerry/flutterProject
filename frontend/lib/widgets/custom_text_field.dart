import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final AutovalidateMode autovalidateMode;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: autovalidateMode,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AppColors.primary),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
