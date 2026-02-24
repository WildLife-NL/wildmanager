import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

import '../config/app_config.dart';
import '../models/detection.dart';

const int _minRadiusMeters = 1;
const int _maxRadiusMeters = 10000;

Future<List<Detection>> fetchDetections({
  required LatLng center,
  required int radiusMeters,
  required DateTime start,
  required DateTime end,
  DetectionType? typeFilter,
}) async {
  final radius = radiusMeters.clamp(_minRadiusMeters, _maxRadiusMeters);
  final baseUrl = AppConfig.loginBaseUrl;
  debugPrint('[Detections] fetch: center=(${center.latitude}, ${center.longitude}) radius=${radius}m start=$start end=$end baseUrl=$baseUrl');
  if (baseUrl.isEmpty) {
    debugPrint('[Detections] baseUrl leeg – controleer .env DEV_BASE_URL');
    return [];
  }

  final api = HttpDetectionReadApi(baseUrl: baseUrl);
  final raw = await api.getDetectionsByFilter(
    start: start,
    end: end,
    latitude: center.latitude,
    longitude: center.longitude,
    radius: radius,
  );

  debugPrint('[Detections] API retourneerde ${raw.length} raw items');
  if (raw.isNotEmpty) {
    debugPrint('[Detections] Eerste item keys: ${raw.first.keys.toList()}');
  }

  var list = <Detection>[];
  for (final map in raw) {
    final d = Detection.fromJson(map);
    if (d == null) continue;
    if (typeFilter != null && d.type != typeFilter) continue;
    list.add(d);
  }
  debugPrint('[Detections] Geparsed: ${list.length} detections');
  return list;
}
