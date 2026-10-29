/// Formatos de fecha y tamaño en español, sin dependencias extra.
class Formatters {
  Formatters._();

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const _monthsLong = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// "Hoy, 14:32" · "Ayer, 09:10" · "12 oct 2026, 08:00"
  static String relativeDateTime(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfDate = DateTime(date.year, date.month, date.day);
    final days = startOfToday.difference(startOfDate).inDays;
    if (days == 0) return 'Hoy, ${time(date)}';
    if (days == 1) return 'Ayer, ${time(date)}';
    return '${date.day} ${_months[date.month - 1]} ${date.year}, ${time(date)}';
  }

  /// "octubre de 2026"
  static String monthYear(DateTime date) => '${_monthsLong[date.month - 1]} de ${date.year}';

  /// "1,2 MB" · "850 KB"
  static String bytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
    }
    return '${(bytes / 1024).round()} KB';
  }
}
