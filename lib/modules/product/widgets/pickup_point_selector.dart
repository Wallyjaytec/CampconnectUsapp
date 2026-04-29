import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../model/pickup_point_model.dart';

class PickupPointSelector extends StatelessWidget {
  const PickupPointSelector({
    super.key,
    required this.title,
    required this.points,
    required this.selectedId,
    required this.onChanged,
  });

  final String title;
  final List<PickupPoint> points;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final TextStyle labelStyle = TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
    );
    const TextStyle valueStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    final TextStyle mutedStyle = TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton2<int>(
              isExpanded: true,
              value: selectedId,
              hint: Text('Select a pickup point'.tr),
              items: points.map((p) {
                final bool isSelected = selectedId == p.id;
                return DropdownMenuItem<int>(
                  value: p.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: isSelected
                                ? AppColors.primaryColor
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                        Expanded(
                          child: _PickupPointLines(
                            p: p,
                            labelStyle: labelStyle,
                            valueStyle: valueStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              selectedItemBuilder: (context) {
                return points.map((p) {
                  return _PickupPointSelectedPreview(
                    point: p,
                    valueStyle: valueStyle,
                    mutedStyle: mutedStyle,
                  );
                }).toList();
              },

              onChanged: onChanged,

              buttonStyleData: ButtonStyleData(
                height: 50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardColor
                      : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                  ),
                ),
              ),

              iconStyleData: IconStyleData(
                icon: Icon(
                  Iconsax.arrow_down_1_copy,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
                openMenuIcon: Icon(
                  Iconsax.arrow_up_2_copy,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),

              dropdownStyleData: DropdownStyleData(
                maxHeight: 360,
                elevation: 2,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkProductCardColor
                      : AppColors.lightBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.zero,
                height: 100,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _PickupPointLines extends StatelessWidget {
  const _PickupPointLines({
    required this.p,
    required this.labelStyle,
    required this.valueStyle,
  });

  final PickupPoint p;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _kv('Name', p.name),
        _kv('Address', p.location),
        if (p.phone.isNotEmpty) _kv('Phone', p.phone),
        if (p.zoneName.isNotEmpty) _kv('Zone', p.zoneName),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          style: labelStyle,
          children: [
            TextSpan(text: '$k: '),
            TextSpan(text: v, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

class _PickupPointSelectedPreview extends StatelessWidget {
  const _PickupPointSelectedPreview({
    required this.point,
    required this.valueStyle,
    required this.mutedStyle,
  });

  final PickupPoint point;
  final TextStyle valueStyle;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final List<String> addressParts = [
      point.location,
      point.zoneName,
      if (point.phone.isNotEmpty) '${'Phone'.tr}: ${point.phone}',
    ].where((e) => e.trim().isNotEmpty).toList();

    final restLine = addressParts.isNotEmpty ? addressParts.join(' • ') : '';

    return Row(
      children: [
        const Icon(Iconsax.location_copy, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            restLine,
            style: mutedStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
