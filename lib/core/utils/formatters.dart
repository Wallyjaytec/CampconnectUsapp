String formatCount(int count) {
  if (count >= 1000000) {
    // 1M+
    double value = count / 1000000;
    return "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}M";
  } else if (count >= 1000) {
    // 1K+
    double value = count / 1000;
    return "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}k";
  } else {
    return count.toString();
  }
}
