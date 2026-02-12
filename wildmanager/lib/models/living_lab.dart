import 'package:latlong2/latlong.dart';

/// Living lab from the API (GET /livinglabs/).
class LivingLab {
  const LivingLab({
    required this.id,
    required this.name,
    this.definition,
  });

  final String id;
  final String name;
  /// Polygon points (latitude, longitude). Null or &lt; 3 points = no area to draw.
  final List<LatLng>? definition;

  static LivingLab fromJson(Map<String, dynamic> json) {
    final raw = json['definition'] as List<dynamic>?;
    List<LatLng>? definition;
    if (raw != null && raw.isNotEmpty) {
      definition = raw
          .map((e) {
            final m = e as Map<String, dynamic>;
            final lat = (m['latitude'] as num?)?.toDouble();
            final lon = (m['longitude'] as num?)?.toDouble();
            if (lat == null || lon == null) return null;
            return LatLng(lat, lon);
          })
          .whereType<LatLng>()
          .toList();
      if (definition.length < 3) definition = null;
    }
    return LivingLab(
      id: (json['ID'] ?? json['id'])?.toString() ?? '',
      name: json['name'] as String? ?? '',
      definition: definition,
    );
  }
}
