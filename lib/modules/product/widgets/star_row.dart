import 'package:flutter/material.dart';

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    final empty = 5 - full - (hasHalf ? 1 : 0);

    final iconColor = Colors.amber[700];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < full; i++)
          Icon(Icons.star_rounded, size: 16, color: iconColor),
        if (hasHalf) Icon(Icons.star_half_rounded, size: 16, color: iconColor),
        for (int i = 0; i < empty; i++)
          Icon(
            Icons.star_outline_rounded,
            size: 16,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: .35),
          ),
      ],
    );
  }
}
