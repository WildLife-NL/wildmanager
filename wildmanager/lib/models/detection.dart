import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

class Detection {
  const Detection({
    required this.id,
    required this.location,
    required this.type,
    this.moment,
    this.species,
    this.sex,
    this.condition,
    this.lifeStage,
  });

  final String id;
  final LatLng location;
  final DetectionType type;
  final DateTime? moment;
  final String? species;
  final String? sex;
  final String? condition;
  final String? lifeStage;

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
    species ??= json['animal_species'] as String?;

    final animal = json['animal'] as Map<String, dynamic>? ?? json['detectedAnimal'] as Map<String, dynamic>?;
    String? sex = json['sex'] as String? ?? json['gender'] as String?;
    String? condition = json['condition'] as String? ?? json['health'] as String?;
    String? lifeStage = json['lifeStage'] as String? ?? json['life_stage'] as String? ?? json['lifestage'] as String? ?? json['ageClass'] as String?;
    if (animal != null) {
      sex ??= animal['sex'] as String? ?? animal['gender'] as String?;
      condition ??= animal['condition'] as String? ?? animal['health'] as String?;
      lifeStage ??= animal['lifeStage'] as String? ?? animal['life_stage'] as String? ?? animal['lifestage'] as String? ?? animal['ageClass'] as String?;
    }

    return Detection(
      id: id,
      location: location,
      type: type,
      moment: moment,
      species: species,
      sex: sex,
      condition: condition,
      lifeStage: lifeStage,
    );
  }
}
