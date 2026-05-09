String formatMb(int bytes) {
  if (bytes <= 0) return '0 MB';
  final mb = bytes / (1024 * 1024);
  if (mb >= 100) return '${mb.toStringAsFixed(0)} MB';
  if (mb >= 10) return '${mb.toStringAsFixed(1)} MB';
  return '${mb.toStringAsFixed(2)} MB';
}
