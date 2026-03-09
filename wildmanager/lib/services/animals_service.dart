import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_animal_components/wildlifenl_animal_components.dart';

import '../config/app_config.dart';

const int _minRadiusMeters = 1;
const int _maxRadiusMeters = 50000;

/// Result of fetching animals in a spatiotemporal span, including movement trails.
class AnimalsWithTrails {
  const AnimalsWithTrails({
    required this.animals,
    required this.trailsByAnimalId,
  });
  final List<Animal> animals;
  final Map<String, List<LatLng>> trailsByAnimalId;
}

/// Parses movement trail points from animal JSON (borneSensorDeployments -> borneSensorReadings).
/// Only includes points within [start, end], sorted by timestamp.
List<LatLng> _parseTrailFromAnimalMap(
  Map<String, dynamic> map,
  DateTime start,
  DateTime end,
) {
  final points = <({DateTime time, double lat, double lng})>[];
  final deployments = map['borneSensorDeployments'] as List<dynamic>? ?? [];
  for (final dep in deployments) {
    if (dep is! Map<String, dynamic>) continue;
    final readings = dep['borneSensorReadings'] as List<dynamic>? ?? [];
    for (final r in readings) {
      if (r is! Map<String, dynamic>) continue;
      final loc = r['location'] as Map<String, dynamic>?;
      if (loc == null) continue;
      final lat = (loc['latitude'] as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final tsStr = r['timestamp'] as String?;
      if (tsStr == null) continue;
      final ts = DateTime.tryParse(tsStr);
      if (ts == null || ts.isBefore(start) || ts.isAfter(end)) continue;
      points.add((time: ts, lat: lat, lng: lng));
    }
  }
  points.sort((a, b) => a.time.compareTo(b.time));
  return points.map((p) => LatLng(p.lat, p.lng)).toList();
}

Future<AnimalsWithTrails> fetchAnimalsInSpan({
  required LatLng center,
  required int radiusMeters,
  required DateTime start,
  required DateTime end,
}) async {
  final radius = radiusMeters.clamp(_minRadiusMeters, _maxRadiusMeters);
  final baseUrl = AppConfig.loginBaseUrl;
  if (baseUrl.isEmpty) {
    if (kDebugMode) debugPrint('[Animals] baseUrl leeg – controleer .env DEV_BASE_URL');
    return const AnimalsWithTrails(animals: [], trailsByAnimalId: {});
  }

  final api = HttpAnimalReadApi(baseUrl: baseUrl);
  final raw = await api.getAnimalsInSpan(
    start: start,
    end: end,
    latitude: center.latitude,
    longitude: center.longitude,
    radius: radius,
  );

  if (kDebugMode) debugPrint('[Animals] API retourneerde ${raw.length} items');
  final animals = <Animal>[];
  final trailsByAnimalId = <String, List<LatLng>>{};
  for (final map in raw) {
    final a = Animal.fromJson(map);
    if (a != null) {
      animals.add(a);
      final trail = _parseTrailFromAnimalMap(map, start, end);
      if (trail.length >= 2) trailsByAnimalId[a.id] = trail;
    }
  }
  return AnimalsWithTrails(animals: animals, trailsByAnimalId: trailsByAnimalId);
}
