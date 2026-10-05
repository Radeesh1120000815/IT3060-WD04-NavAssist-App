import 'package:cloud_firestore/cloud_firestore.dart';

// Small helpers that read one value from a Firestore map safely.
// If the value is missing or has the wrong type, the fallback is used,
// so a badly-formed document can never crash the app.

bool readBool(Map<String, dynamic> map, String key, bool fallback) {
  final value = map[key];
  return value is bool ? value : fallback;
}

double readDouble(Map<String, dynamic> map, String key, double fallback) {
  final value = map[key];
  return value is num ? value.toDouble() : fallback;
}

String readString(Map<String, dynamic> map, String key, String fallback) {
  final value = map[key];
  return value is String ? value : fallback;
}

// Firestore stores dates as Timestamp. A server timestamp that has just been
// written can be null for a moment, so this returns null instead of crashing.
DateTime? readDate(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
