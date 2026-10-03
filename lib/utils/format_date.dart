String formatDate(dynamic value) {
  final date = DateTime.tryParse((value ?? '').toString())?.toLocal();
  if (date == null) return 'Data não informada';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} às $hour:$minute';
}
