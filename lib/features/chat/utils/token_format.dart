// Compact formatting for token counts: <1k raw, <1M with k suffix, >=1M with M.
String formatTokenCount(int n) {
  if (n < 1000) {
    return n.toString();
  }
  if (n < 1000000) {
    final value = n / 1000;
    final formatted = value.toStringAsFixed(value >= 100 ? 0 : 1);
    final stripped = formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
    return '${stripped}k';
  }
  final value = n / 1000000;
  final formatted = value.toStringAsFixed(1);
  final stripped = formatted.endsWith('.0')
      ? formatted.substring(0, formatted.length - 2)
      : formatted;
  return '${stripped}M';
}
