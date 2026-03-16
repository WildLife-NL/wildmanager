import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

class Detection {
  const Detection({
    required this.id,
    required this.location,
    required this.type,
    this.moment,
    this.species,
    this.speciesCategory,
    this.sex,
    this.condition,
    this.lifeStage,
    this.behaviour,
    this.confidence,
    this.description,
    this.deploymentID,
    this.userName,
  });

  final String id;
  final LatLng location;
  final DetectionType type;
  final DateTime? moment;
  final String? species;
  final String? speciesCategory;
  final String? sex;
  final String? condition;
  final String? lifeStage;
  final String? behaviour;
  final int? confidence;
  final String? description;
  final String? deploymentID;
  final String? userName;

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
    String? speciesCategory;
    final speciesObj = json['species'];
    if (speciesObj is Map<String, dynamic>) {
      species = speciesObj['commonName'] as String? ?? speciesObj['name'] as String?;
      speciesCategory = speciesObj['category'] as String?;
    } else if (speciesObj is String) {
      species = speciesObj;
    }
    species ??= json['animal_species'] as String?;

    String? sex;
    String? condition;
    String? lifeStage;
    String? behaviour;
    int? confidence;
    String? description;
    final animals = json['animals'] as List<dynamic>?;
    final firstAnimal = animals != null && animals.isNotEmpty && animals.first is Map<String, dynamic>
        ? animals.first as Map<String, dynamic>
        : null;
    if (firstAnimal != null) {
      sex = firstAnimal['sex'] as String?;
      condition = firstAnimal['condition'] as String?;
      lifeStage = firstAnimal['lifeStage'] as String?;
      behaviour = firstAnimal['behaviour'] as String?;
      confidence = (firstAnimal['confidence'] as num?)?.toInt();
      description = firstAnimal['description'] as String?;
    }
    description ??= json['description'] as String?;

    final deploymentID = json['deploymentID'] as String? ?? json['deployment_id'] as String?;
    final user = json['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String?;

    return Detection(
      id: id,
      location: location,
      type: type,
      moment: moment,
      species: species,
      speciesCategory: speciesCategory,
      sex: sex,
      condition: condition,
      lifeStage: lifeStage,
      behaviour: behaviour,
      confidence: confidence,
      description: description,
      deploymentID: deploymentID,
      userName: userName,
    );
  }
}
