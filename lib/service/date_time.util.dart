/// Utilities for normalizing and formatting PocketBase datetime strings.

/// Parses PocketBase datetime strings that may use either
/// "YYYY-MM-DD HH:MM:SS(.sss)Z" or "YYYY-MM-DDTHH:MM:SS(.sss)Z".
/// Returns null if parsing fails.
DateTime? parsePocketbaseDate(String value) {
  String s = value.trim();
  if (!s.contains('T') && s.contains(' ')) {
    // Normalize single space separator between date and time to 'T'.
    s = s.replaceFirst(' ', 'T');
  }
  try {
    return DateTime.parse(s);
  } catch (_) {
    // Try appending 'Z' if timezone marker is missing.
    if (!s.endsWith('Z') && !s.contains('+')) {
      try {
        return DateTime.parse('${s}Z');
      } catch (_) {}
    }
    return null;
  }
}

/// Formats a DateTime in local timezone as: "Dom, 14 Nov · 21:56".
String formatLocalShort(DateTime dt) {
  const dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  const meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];
  final diaSemana = dias[dt.weekday % 7];
  final dia = dt.day;
  final mes = meses[dt.month - 1];
  final hora = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$diaSemana, $dia $mes · $hora:$min';
}

/// Convenience to format a PocketBase datetime string to a local short label.
String formatPocketbaseDateLocalShort(String value) {
  final parsed = parsePocketbaseDate(value);
  if (parsed == null) return value;
  return formatLocalShort(parsed.toLocal());
}

/// Formats a DateTime as PocketBase UTC string with optional space separator.
/// Example with space:  "2022-01-01 10:00:00.123Z"
/// Example with 'T':   "2022-01-01T10:00:00.123Z"
String formatAsPocketbaseUtc(DateTime dt, {bool useSpaceSeparator = true}) {
  final u = dt.toUtc();
  final y = u.year.toString().padLeft(4, '0');
  final mo = u.month.toString().padLeft(2, '0');
  final d = u.day.toString().padLeft(2, '0');
  final h = u.hour.toString().padLeft(2, '0');
  final mi = u.minute.toString().padLeft(2, '0');
  final s = u.second.toString().padLeft(2, '0');
  final ms = (u.millisecond).toString().padLeft(3, '0');
  final sep = useSpaceSeparator ? ' ' : 'T';
  return '$y-$mo-$d$sep$h:$mi:$s.${ms}Z';
}

/// Normalizes an incoming PocketBase datetime string to
/// "YYYY-MM-DD HH:MM:SS.mmmZ" or with 'T' if requested.
String normalizePocketbaseString(String value, {bool useSpaceSeparator = true}) {
  final parsed = parsePocketbaseDate(value);
  if (parsed == null) return value;
  return formatAsPocketbaseUtc(parsed, useSpaceSeparator: useSpaceSeparator);
}

/// Returns only HH:mm from a PocketBase datetime string.
/// If useLocal is true, converts to local timezone before formatting.
String formatPocketbaseHHmm(String value, {bool useLocal = false}) {
  final parsed = parsePocketbaseDate(value);
  if (parsed == null) return value;
  final dt = useLocal ? parsed.toLocal() : parsed.toUtc();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Returns "Dom, 14 Nov · HH:mm" using UTC by default (to match PB exactly).
String formatPocketbaseDayAndHHmm(String value, {bool useLocal = false}) {
  final parsed = parsePocketbaseDate(value);
  if (parsed == null) return value;
  final dt = useLocal ? parsed.toLocal() : parsed.toUtc();
  const dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  const meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];
  final diaSemana = dias[dt.weekday % 7];
  final dia = dt.day;
  final mes = meses[dt.month - 1];
  final hhmm = formatPocketbaseHHmm(value, useLocal: useLocal);
  return '$diaSemana, $dia $mes · $hhmm';
}

/// Day in local like before, but HH:mm exactly as in PB (UTC).
String formatDayLocalAndHHmmUtc(String value) {
  final parsed = parsePocketbaseDate(value);
  if (parsed == null) return value;
  // Local for day label
  final local = parsed.toLocal();
  const dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  const meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];
  final diaSemana = dias[local.weekday % 7];
  final dia = local.day;
  final mes = meses[local.month - 1];
  // Extract HH:mm from PB (UTC) without converting
  final normalized = normalizePocketbaseString(value, useSpaceSeparator: true);
  // normalized is YYYY-MM-DD HH:MM:SS.mmmZ
  String hhmm = normalized;
  final spaceIndex = normalized.indexOf(' ');
  if (spaceIndex != -1 && normalized.length >= spaceIndex + 6) {
    hhmm = normalized.substring(spaceIndex + 1, spaceIndex + 6);
  }
  return '$diaSemana, $dia $mes · $hhmm';
}

/// Formats a local DateTime as "YYYY-MM-DD HH:MM" (no seconds, no TZ).
String formatLocalYmdHHmm(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final mo = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final mi = local.minute.toString().padLeft(2, '0');
  return '$y-$mo-$d $h:$mi';
}
