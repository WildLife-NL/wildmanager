import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

class Detection {
  const Detection({
    required this.id,
    required this.location,
    required this.type,
    this.moment,
    this.species,
  });

  final String id;
  final LatLng location;
  final DetectionType type;
  final DateTime? moment;
  final String? species;

  static Detection? fromJson(Map<String, dynamic> json) {
    final locMap = json['location'] as Map<String, dynamic>?;
    final data = locMap ?? json;
    final lat = detectionLatitude(data);
    final lng = detectionLongitude(data);
    if (lat == null || lng == null) return null;
    final location = LatLng(lat, lng);

    final id = json['ID'] as String? ?? json['id'] as String? ?? '${lat}_${lng}_${json['start']}';
    final typeStr = json['sensorType'] as String? ?? json['type'] as String?;
    final type = detectionTypeFromString(typeStr);
    final momentStr = json['start'] as String? ?? json['end'] as String? ?? json['moment'] as String?;
    final moment = momentStr != null ? DateTime.tryParse(momentStr) : null;
    String? species;
    final speciesObj = json['species'];
    if (speciesObj is Map<String, dynamic>) {
      species = speciesObj['commonName'] as String? ?? speciesObj['name'] as String? ?? speciesObj['category'] as String?;
    } else if (speciesObj is String) {
      species = speciesObj;
    }
    if (species == null) species = json['animal_species'] as String?;

    return Detection(
      id: id,
      location: location,
      type: type,
      moment: moment,
      species: species,
    );
  }
}
