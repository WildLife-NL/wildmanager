import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

import '../config/app_config.dart';
import '../models/detection.dart';

const int _minRadiusMeters = 1;
const int _maxRadiusMeters = 50000;

const int _detectionApiMaxRadiusMeters = 1000;

List<LatLng> _gridCenters(LatLng center, int radiusMeters, int stepMeters) {
  const distance = Distance();
  final n = (radiusMeters / stepMeters).ceil().clamp(1, 5);
  final centers = <LatLng>[];
  final step = stepMeters.toDouble();
  for (var j = -n; j <= n; j++) {
    final north = distance.offset(center, step * j.abs(), j >= 0 ? 0.0 : 180.0);
    for (var i = -n; i <= n; i++) {
      final p = distance.offset(north, step * i.abs(), i >= 0 ? 90.0 : 270.0);
      centers.add(p);
    }
  }
  return centers;
}

Future<List<Detection>> _fetchDetectionsSingle({
  required HttpDetectionReadApi api,
  required LatLng center,
  required int radius,
  required DateTime start,
  required DateTime end,
  DetectionType? typeFilter,
}) async {
  final raw = await api.getDetectionsByFilter(
    start: start,
    end: end,
    latitude: center.latitude,
    longitude: center.longitude,
    radius: radius,
  );
  var list = <Detection>[];
  for (final map in raw) {
    final d = Detection.fromJson(map);
    if (d == null) continue;
    if (typeFilter != null && d.type != typeFilter) continue;
    list.add(d);
  }
  return list;
}

Future<List<Detection>> fetchDetections({
  required LatLng center,
  required int radiusMeters,
  required DateTime start,
  required DateTime end,
  DetectionType? typeFilter,
}) async {
  final requestedRadius = radiusMeters.clamp(_minRadiusMeters, _maxRadiusMeters);
  final baseUrl = AppConfig.loginBaseUrl;
  debugPrint('[Detections] fetch: center=(${center.latitude}, ${center.longitude}) radius=${requestedRadius}m start=$start end=$end baseUrl=$baseUrl');
  if (baseUrl.isEmpty) {
    debugPrint('[Detections] baseUrl leeg – controleer .env DEV_BASE_URL');
    return [];
  }

  final api = HttpDetectionReadApi(baseUrl: baseUrl);

  if (requestedRadius <= _detectionApiMaxRadiusMeters) {
    final list = await _fetchDetectionsSingle(
      api: api,
      center: center,
      radius: requestedRadius,
      start: start,
      end: end,
      typeFilter: typeFilter,
    );
    debugPrint('[Detections] API retourneerde ${list.length} detections');
    return list;
  }

  final stepMeters = 1800;
  final centers = _gridCenters(center, requestedRadius, stepMeters);
  debugPrint('[Detections] Grid met ${centers.length} punten (radius ${requestedRadius}m > ${_detectionApiMaxRadiusMeters}m)');
  final seenIds = <String>{};
  final merged = <Detection>[];
  for (final c in centers) {
    final list = await _fetchDetectionsSingle(
      api: api,
      center: c,
      radius: _detectionApiMaxRadiusMeters,
      start: start,
      end: end,
      typeFilter: typeFilter,
    );
    for (final d in list) {
      if (seenIds.add(d.id)) merged.add(d);
    }
  }
  debugPrint('[Detections] Samengevoegd: ${merged.length} unieke detections');
  return merged;
}
