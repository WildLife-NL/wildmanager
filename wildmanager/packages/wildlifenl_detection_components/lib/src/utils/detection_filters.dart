import '../models/detection_type.dart';

List<Map<String, dynamic>> filterDetectionsByType(
  List<Map<String, dynamic>> detections,
  DetectionType? type,
) {
  if (type == null) return detections;
  return detections.where((d) {
    final t = detectionTypeFromString(d['sensorType'] as String? ?? d['type'] as String?);
    return t == type;
  }).toList();
}

List<Map<String, dynamic>> filterDetectionsByTimePeriod(
  List<Map<String, dynamic>> detections, {
  DateTime? start,
  DateTime? end,
  String momentKey = 'moment',
}) {
  if (start == null && end == null) return detections;
  return detections.where((d) {
    final m = d[momentKey];
    if (m == null) return false;
    DateTime moment;
    if (m is DateTime) {
      moment = m;
    } else if (m is String) {
      moment = DateTime.tryParse(m) ?? DateTime(0);
    } else {
      return false;
    }
    if (start != null && moment.isBefore(start)) return false;
    if (end != null && moment.isAfter(end)) return false;
    return true;
  }).toList();
}

bool detectionHasLocation(Map<String, dynamic> d) {
  final loc = d['location'] as Map<String, dynamic>?;
  final map = loc ?? d;
  final lat = map['latitude'] ?? map['lat'];
  final lng = map['longitude'] ?? map['lng'] ?? map['lon'];
  if (lat == null || lng == null) return false;
  return (lat is num && lng is num) || (lat is String && lng is String);
}

double? detectionLatitude(Map<String, dynamic> d) {
  final loc = d['location'] as Map<String, dynamic>?;
  final map = loc ?? d;
  final lat = map['latitude'] ?? map['lat'];
  if (lat == null) return null;
  if (lat is num) return lat.toDouble();
  if (lat is String) return double.tryParse(lat);
  return null;
}

double? detectionLongitude(Map<String, dynamic> d) {
  final loc = d['location'] as Map<String, dynamic>?;
  final map = loc ?? d;
  final lng = map['longitude'] ?? map['lng'] ?? map['lon'];
  if (lng == null) return null;
  if (lng is num) return lng.toDouble();
  if (lng is String) return double.tryParse(lng);
  return null;
}
