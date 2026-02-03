import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String programId;
  final String wardId;
  final DateTime timestamp;
  final Map<String, dynamic> data; // Dynamic form data derived from validation keys
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String submittedBy;

  SubmissionModel({
    required this.id,
    required this.programId,
    required this.wardId,
    required this.timestamp,
    required this.data,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.submittedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programId': programId,
      'wardId': wardId,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'location': latitude != null && longitude != null
          ? GeoPoint(latitude!, longitude!)
          : null,
      'imageUrl': imageUrl,
      'submittedBy': submittedBy,
    };
  }

  factory SubmissionModel.fromMap(Map<String, dynamic> map, String id) {
    GeoPoint? gp = map['location'] as GeoPoint?;
    return SubmissionModel(
      id: id,
      programId: map['programId'] ?? '',
      wardId: map['wardId'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      data: map['data'] ?? {},
      latitude: gp?.latitude,
      longitude: gp?.longitude,
      imageUrl: map['imageUrl'],
      submittedBy: map['submittedBy'] ?? '',
    );
  }
}
