import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_animal_components/wildlifenl_animal_components.dart';

import '../config/app_config.dart';

const int _minRadiusMeters = 1;
const int _maxRadiusMeters = 10000;

/// Haalt dieren op binnen het gegeven tijd-ruimtebereik (spatiotemporal span).
Future<List<Animal>> fetchAnimalsInSpan({
  required LatLng center,
  required int radiusMeters,
  required DateTime start,
  required DateTime end,
}) async {
  final radius = radiusMeters.clamp(_minRadiusMeters, _maxRadiusMeters);
  final baseUrl = AppConfig.loginBaseUrl;
  if (baseUrl.isEmpty) {
    if (kDebugMode) debugPrint('[Animals] baseUrl leeg – controleer .env DEV_BASE_URL');
    return [];
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
  final list = <Animal>[];
  for (final map in raw) {
    final a = Animal.fromJson(map);
    if (a != null) list.add(a);
  }
  return list;
}
