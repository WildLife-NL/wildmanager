import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_interaction_components/wildlifenl_interaction_components.dart';

import '../config/app_config.dart';
import '../models/interaction.dart';

const int _minRadiusMeters = 1;
const int _maxRadiusMeters = 50000;

Future<List<Interaction>> fetchInteractions({
  required LatLng center,
  required int radiusMeters,
  DateTime? momentAfter,
  DateTime? momentBefore,
  int? interactionTypeId,
}) async {
  final radius = radiusMeters.clamp(_minRadiusMeters, _maxRadiusMeters);
  final api = HttpInteractionReadApi(baseUrl: AppConfig.loginBaseUrl);
  final raw = await api.queryInteractions(
    areaLatitude: center.latitude,
    areaLongitude: center.longitude,
    areaRadiusMeters: radius,
    momentAfter: momentAfter,
    momentBefore: momentBefore,
  );

  if (kDebugMode && raw.isNotEmpty) {
    debugPrint('[Interactions] API returned ${raw.length} item(s). First item keys: ${raw.first.keys.toList()}');
    _debugPrintSpeciesStructure(raw.first);
  }

  final list = <Interaction>[];
  for (final map in raw) {
    final i = Interaction.fromJson(map);
    if (i == null) continue;
    if (interactionTypeId != null && i.typeId != interactionTypeId) continue;
    list.add(i);
  }
  return list;
}

void _debugPrintSpeciesStructure(Map<String, dynamic> json) {
  final reportOfSighting = json['reportOfSighting'] ?? json['report_of_sighting'];
  if (reportOfSighting == null) {
    debugPrint('[Interactions] No reportOfSighting / report_of_sighting in first item');
    return;
  }
  final sighting = reportOfSighting is Map ? reportOfSighting as Map<String, dynamic> : null;
  if (sighting == null) return;
  debugPrint('[Interactions] reportOfSighting keys: ${sighting.keys.toList()}');
  final involved = sighting['involvedAnimals'] ?? sighting['involved_animals'];
  if (involved is List && involved.isNotEmpty) {
    final first = involved.first;
    if (first is Map<String, dynamic>) debugPrint('[Interactions] first involvedAnimal keys: ${first.keys.toList()}');
  }
  final species = sighting['species'];
  if (species is Map) debugPrint('[Interactions] sighting.species: $species');
}
