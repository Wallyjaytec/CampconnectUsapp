import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../account/model/address_model.dart';

class AddressSelector extends StatefulWidget {
  const AddressSelector({
    super.key,
    required this.title,
    required this.addresses,
    required this.selectedId,
    required this.onChanged,
    required this.onAddAddress,
    this.formatLines,
  });

  final String title;
  final List<CustomerAddress> addresses;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final VoidCallback onAddAddress;

  final List<String> Function(CustomerAddress address)? formatLines;

  @override
  State<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends State<AddressSelector> {
  late final TextStyle _labelStyle;
  late final TextStyle _valueStyle;
  late final TextStyle _mutedStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _labelStyle = TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    _valueStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    _mutedStyle = TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
      height: 1.15,
    );
  }

  List<String> _defaultLines(CustomerAddress a) {
    final locationParts = [
      a.city?.name ?? '',
      a.state?.name ?? '',
      a.country?.name ?? '',
    ].where((e) => e.trim().isNotEmpty).toList();

    return [
      'Name: ${a.name}',
      if (a.address.trim().isNotEmpty) 'Address: ${a.address}',
      if (a.phone.trim().isNotEmpty) 'Phone: ${a.phone}',
      if (a.postalCode.trim().isNotEmpty) 'Postal Code: ${a.postalCode}',
      if (locationParts.isNotEmpty) locationParts.join(' , '),
    ];
  }

  List<String> _linesOf(CustomerAddress a) =>
      (widget.formatLines?.call(a) ?? _defaultLines(a))
          .where((e) => e.trim().isNotEmpty)
          .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addresses = widget.addresses;

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: widget.onAddAddress,
                child: const Icon(Iconsax.add_circle_copy, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),

          DropdownButtonHideUnderline(
            child: DropdownButton2<int>(
              value: widget.selectedId,
              isExpanded: true,
              hint: Text(
                'Add Address'.tr,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              items: addresses.map((a) {
                final isSelected = a.id == widget.selectedId;
                final lines = _linesOf(a);

                return DropdownMenuItem<int>(
                  value: a.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: _AddressMenuTile(
                      lines: lines,
                      isSelected: isSelected,
                      labelStyle: _labelStyle,
                      valueStyle: _valueStyle,
                      mutedStyle: _mutedStyle,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) => widget.onChanged(v),

              buttonStyleData: ButtonStyleData(
                height: 54,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkCardColor
                      : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                  ),
                ),
              ),

              iconStyleData: const IconStyleData(
                icon: Icon(Iconsax.arrow_down_1_copy, size: 18),
                openMenuIcon: Icon(Iconsax.arrow_up_2_copy, size: 18),
              ),

              dropdownStyleData: DropdownStyleData(
                maxHeight: 360,
                elevation: 2,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkProductCardColor
                      : AppColors.lightBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.zero,
                height: 100,
              ),

              selectedItemBuilder: (_) {
                return addresses.map((a) {
                  final lines = _linesOf(a);
                  return _AddressSelectedPreview(
                    lines: lines,
                    mutedStyle: _mutedStyle,
                    valueStyle: _valueStyle,
                  );
                }).toList();
              },
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _AddressMenuTile extends StatelessWidget {
  const _AddressMenuTile({
    required this.lines,
    required this.isSelected,
    required this.labelStyle,
    required this.valueStyle,
    required this.mutedStyle,
  });

  final List<String> lines;
  final bool isSelected;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          size: 18,
          color: isSelected
              ? AppColors.primaryColor
              : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lines.isNotEmpty)
                Text(
                  lines.first,
                  style: valueStyle.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ...lines
                  .skip(1)
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        t,
                        style: mutedStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddressSelectedPreview extends StatelessWidget {
  const _AddressSelectedPreview({
    required this.lines,
    required this.mutedStyle,
    required this.valueStyle,
  });

  final List<String> lines;
  final TextStyle mutedStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    final first = lines.isNotEmpty ? lines.first : '—';
    final rest = lines.skip(1).toList();

    return Row(
      children: [
        const Icon(Iconsax.location_copy, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                first,
                style: valueStyle.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (rest.isNotEmpty)
                Text(
                  rest.join(' • '),
                  style: mutedStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
