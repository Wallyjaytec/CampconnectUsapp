import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
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
  final String? initialValue;

  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  const CustomTextFormField({
    super.key,
    required this.controller,
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

    this.validator,
    this.autovalidateMode,
    this.initialValue,
  });

  bool get _isMultilineLike {
    if (expands) return true;
    if ((maxLines ?? 1) > 1) return true;
    if ((minLines ?? 1) > 1) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double? containerHeight = _isMultilineLike ? null : 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: containerHeight,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: TextFormField(
              initialValue: initialValue,
              controller: controller,
              cursorColor: AppColors.primaryColor,
              keyboardType: keyboardType,
              obscureText: obscure,
              readOnly: readOnly,
              onChanged: onChanged,
              onTap: onTap,
              expands: expands,
              maxLines: maxLines,
              minLines: minLines,
              style: const TextStyle(fontSize: 16),
              textAlignVertical: TextAlignVertical.center,

              validator: validator,
              autovalidateMode: autovalidateMode,

              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkCardColor
                    : AppColors.lightCardColor,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: AppColors.greyColor,
                ),
                prefixIcon: Icon(icon, size: 18),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 50,
                  minHeight: 50,
                ),
                suffixIcon: suffix,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 50,
                  minHeight: 50,
                ),

                errorStyle: const TextStyle(
                  height: 1.2,
                  fontSize: 12,
                  color: Colors.red,
                ),
                contentPadding: _isMultilineLike
                    ? const EdgeInsets.symmetric(horizontal: 0, vertical: 8)
                    : const EdgeInsets.symmetric(vertical: 0),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
