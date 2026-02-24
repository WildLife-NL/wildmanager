import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_interaction_components/wildlifenl_interaction_components.dart';

import '../config/app_config.dart';
import '../models/interaction.dart';

const int _minRadiusMeters = 1;
const int _maxRadiusMeters = 10000;

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

  final list = <Interaction>[];
  for (final map in raw) {
    final i = Interaction.fromJson(map);
    if (i == null) continue;
    if (interactionTypeId != null && i.typeId != interactionTypeId) continue;
    list.add(i);
  }
  return list;
}
