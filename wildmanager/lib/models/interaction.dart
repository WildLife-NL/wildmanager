import 'package:latlong2/latlong.dart';

/// Interaction type IDs from the API: 1 = sighting, 2 = damage, 3 = collision.
const int interactionTypeSighting = 1;
const int interactionTypeDamage = 2;
const int interactionTypeCollision = 3;

class Interaction {
  const Interaction({
    required this.id,
    required this.location,
    required this.typeId,
    required this.typeName,
    this.moment,
    this.description,
    this.speciesCommonName,
    this.speciesCategory,
  });

  final String id;
  final LatLng location;
  final int typeId;
  final String typeName;
  final DateTime? moment;
  final String? description;
  final String? speciesCommonName;
  final String? speciesCategory;

  static Interaction? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['ID'] as String? ?? json['id'] as String?;
      if (id == null) return null;

      final loc = json['location'] as Map<String, dynamic>? ?? json['place'] as Map<String, dynamic>?;
      if (loc == null) return null;
      final lat = (loc['latitude'] as num?)?.toDouble() ?? (loc['lat'] as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble() ?? (loc['lon'] as num?)?.toDouble() ?? (loc['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final location = LatLng(lat, lng);

      final type = json['type'] as Map<String, dynamic>?;
      final typeId = (type?['ID'] as num?)?.toInt() ?? 0;
      final typeName = type?['name'] as String? ?? '';

      final momentStr = json['moment'] as String?;
      DateTime? moment;
      if (momentStr != null) {
        moment = DateTime.tryParse(momentStr);
      }

      final description = json['description'] as String?;

      String? speciesCommonName;
      String? speciesCategory;
      final sighting = json['reportOfSighting'] as Map<String, dynamic>?;
      if (sighting != null) {
        final involved = sighting['involvedAnimals'] as List<dynamic>?;
        final first = involved?.isNotEmpty == true ? involved!.first as Map<String, dynamic>? : null;
        final species = first?['species'] ?? sighting['species'] as Map<String, dynamic>?;
        if (species != null) {
          speciesCommonName = species['commonName'] as String?;
          speciesCategory = species['category'] as String?;
        }
      }

      return Interaction(
        id: id,
        location: location,
        typeId: typeId,
        typeName: typeName,
        moment: moment,
        description: description,
        speciesCommonName: speciesCommonName,
        speciesCategory: speciesCategory,
      );
    } catch (_) {
      return null;
    }
  }
}
