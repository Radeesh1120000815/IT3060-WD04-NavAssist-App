import 'package:cloud_firestore/cloud_firestore.dart';

enum HazardSeverity { high, medium, low }

extension HazardSeverityDetails on HazardSeverity {
  String get label => switch (this) {
    HazardSeverity.high => 'HIGH',
    HazardSeverity.medium => 'MEDIUM',
    HazardSeverity.low => 'LOW',
  };

  String get firestoreValue => name;

  static HazardSeverity fromFirestore(Object? value) {
    return HazardSeverity.values.firstWhere(
      (severity) => severity.name == value,
      orElse: () => HazardSeverity.medium,
    );
  }
}

class Hazard {
  const Hazard({
    required this.id,
    required this.type,
    required this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.reporterId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String description;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final HazardSeverity severity;
  final String reporterId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Hazard.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return Hazard(
      id: document.id,
      type: (data['type'] as String?)?.trim().isNotEmpty == true
          ? data['type'] as String
          : 'Other hazard',
      description: data['description'] as String? ?? '',
      locationName: data['locationName'] as String? ?? 'Location unavailable',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      severity: HazardSeverityDetails.fromFirestore(data['severity']),
      reporterId: data['reporterId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
