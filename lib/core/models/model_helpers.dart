T enumFromString<T extends Enum>(List<T> values, String value, T fallback) {
  return values.firstWhere(
    (item) => item.name == value,
    orElse: () => fallback,
  );
}

DateTime? parseFlexibleDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is num) return _dateFromEpoch(value);
  if (value is Map) {
    final seconds = value['seconds'] ?? value['_seconds'];
    if (seconds is num) {
      final nanos = value['nanoseconds'] ?? value['_nanoseconds'] ?? 0;
      final extraMs = nanos is num ? nanos.toInt() ~/ 1000000 : 0;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds.toInt() * 1000 + extraMs,
        isUtc: true,
      );
    }
  }
  try {
    final toDate = (value as dynamic).toDate;
    if (toDate is Function) {
      final date = toDate();
      if (date is DateTime) return date;
    }
  } catch (_) {}
  try {
    final seconds = (value as dynamic).seconds;
    if (seconds is num) return _dateFromEpoch(seconds);
  } catch (_) {}
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return DateTime.tryParse(text);
}

DateTime? _dateFromEpoch(num value) {
  final n = value.toInt();
  if (n >= 100000000000000) {
    return DateTime.fromMicrosecondsSinceEpoch(n, isUtc: true);
  }
  if (n >= 100000000000) {
    return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
  }
  if (n >= 1000000000) {
    return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true);
  }
  return null;
}

Map<String, dynamic> mapFrom(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<String> stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
