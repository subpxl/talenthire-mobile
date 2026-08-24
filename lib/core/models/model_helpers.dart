T enumFromString<T extends Enum>(List<T> values, String value, T fallback) {
  return values.firstWhere(
    (item) => item.name == value,
    orElse: () => fallback,
  );
}

DateTime? parseFlexibleDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    if (value is Object && value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate() as DateTime;
    }
    if (value is Map && value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as num).toInt() * 1000,
      );
    }
  } catch (_) {}
  return DateTime.tryParse(value.toString());
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
