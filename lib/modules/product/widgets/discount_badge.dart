import 'package:flutter/material.dart';

class DiscountBadge extends StatelessWidget {
  final int percent;
  const DiscountBadge(this.percent, {super.key});

  @override
  Widget build(BuildContext context) {
    if (percent <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6CEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
