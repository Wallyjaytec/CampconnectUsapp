import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Widget? suffix;
  final bool expands;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final String? errorText; // ADD THIS

  const CustomTextField({
    super.key,
    this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onTap,
    this.suffix,
    this.expands = false,
    this.readOnly = false,
    this.maxLines,
    this.minLines,
    this.errorText, // ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(10),
        border: errorText != null
            ? Border.all(color: Colors.red, width: 1.5)
            : null,
      ),
      child: Center(
        child: TextField(
          expands: expands,
          maxLines: maxLines,
          minLines: minLines,
          readOnly: readOnly,
          selectAllOnFocus: false,
          controller: controller,
          cursorColor: AppColors.primaryColor,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          textAlignVertical: TextAlignVertical.center,
          onChanged: onChanged,
          onTap: onTap,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark
                ? AppColors.darkCardColor
                : AppColors.lightCardColor,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.greyColor,
            ),
            prefixIcon: Icon(icon, size: 18),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 40,
            ),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 50,
              minHeight: 50,
            ),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
