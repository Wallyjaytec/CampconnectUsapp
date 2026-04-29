import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;
  const StatusBadge({super.key, required this.text, required this.type});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(
      type,
      Theme.of(context).brightness == Brightness.dark,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 13)),
    );
  }

  (Color, Color) _colors(StatusType t, bool dark) {
    switch (t) {
      case StatusType.success:
        return (Colors.green.withValues(alpha: 0.15), Colors.green.shade700);
      case StatusType.warning:
        return (Colors.orange.withValues(alpha: 0.15), Colors.orange.shade700);
      case StatusType.info:
        return (Colors.blue.withValues(alpha: 0.15), Colors.blue.shade700);
      case StatusType.neutral:
        return (Colors.grey.withValues(alpha: 0.15), Colors.grey.shade700);
    }
  }
}

enum StatusType { success, warning, info, neutral }

StatusType paymentType(String label) {
  final v = label.toLowerCase();
  if (v == 'refunded' || v == 'paid') return StatusType.success;
  if (v == 'pending') return StatusType.info;
  return StatusType.neutral;
}

StatusType returnType(String label) {
  final v = label.toLowerCase();
  if (v == 'approved') return StatusType.success;
  if (v.contains('product received')) return StatusType.warning;
  if (v == 'processing' || v == 'requested') return StatusType.neutral;
  return StatusType.neutral;
}
