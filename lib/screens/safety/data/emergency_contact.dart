import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String relationship;
  final String phone;
  final bool isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'isPrimary': isPrimary,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory EmergencyContact.fromMap(String id, Map<String, dynamic>? data) {
    final values = data ?? const <String, dynamic>{};
    return EmergencyContact(
      id: id,
      name: _safeText(values['name'], 'Unnamed contact'),
      relationship: _safeText(values['relationship'], 'Relationship unknown'),
      phone: _safeText(values['phone'], 'Phone unavailable'),
      isPrimary: values['isPrimary'] == true,
      createdAt: _readDate(values['createdAt']),
      updatedAt: _readDate(values['updatedAt']),
    );
  }

  factory EmergencyContact.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return EmergencyContact.fromMap(document.id, document.data());
  }
}

DateTime? _readDate(Object? value) => switch (value) {
  Timestamp timestamp => timestamp.toDate(),
  DateTime dateTime => dateTime,
  _ => null,
};

String _safeText(Object? value, String fallback) {
  if (value is! String || value.trim().isEmpty) return fallback;
  return value.trim();
}
