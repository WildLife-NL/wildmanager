import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

/// Eén dier binnen een detection (één detection kan meerdere dieren omvatten).
class DetectionAnimal {
  const DetectionAnimal({
    this.species,
    this.speciesCategory,
    this.sex,
    this.condition,
    this.lifeStage,
    this.behaviour,
    this.confidence,
    this.description,
  });

  final String? species;
  final String? speciesCategory;
  final String? sex;
  final String? condition;
  final String? lifeStage;
  final String? behaviour;
  final int? confidence;
  final String? description;

  static DetectionAnimal? _fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
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
    return DetectionAnimal(
      species: species,
      speciesCategory: speciesCategory,
      sex: json['sex'] as String?,
      condition: json['condition'] as String?,
      lifeStage: json['lifeStage'] as String?,
      behaviour: json['behaviour'] as String?,
      confidence: (json['confidence'] as num?)?.toInt(),
      description: json['description'] as String?,
    );
  }
}

class Detection {
  const Detection({
    required this.id,
    required this.location,
    required this.type,
    this.moment,
    this.animals = const [],
    this.deploymentID,
    this.userName,
    this.description,
  });

  final String id;
  final LatLng location;
  final DetectionType type;
  final DateTime? moment;
  /// Alle dieren in deze detection (één detection = één timestamp, kan meerdere soorten).
  final List<DetectionAnimal> animals;
  final String? deploymentID;
  final String? userName;
  /// Top-level beschrijving (als geen dier-niveau beschrijving).
  final String? description;

  /// Eerste dier – voor backward compatibility en marker-icoon.
  DetectionAnimal? get firstAnimal =>
      animals.isNotEmpty ? animals.first : null;

  /// Eerste soortnaam (van eerste dier).
  String? get species => firstAnimal?.species;

  /// Eerste soortcategorie (van eerste dier).
  String? get speciesCategory => firstAnimal?.speciesCategory;

  /// Geslacht/conditie/levensfase van eerste dier (backward compat).
  String? get sex => firstAnimal?.sex;
  String? get condition => firstAnimal?.condition;
  String? get lifeStage => firstAnimal?.lifeStage;
  String? get behaviour => firstAnimal?.behaviour;
  int? get confidence => firstAnimal?.confidence;
  String? get descriptionOrFallback => firstAnimal?.description ?? description;

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

    final animalsRaw = json['animals'] as List<dynamic>?;
    final animals = <DetectionAnimal>[];
    if (animalsRaw != null && animalsRaw.isNotEmpty) {
      for (final a in animalsRaw) {
        final animal = DetectionAnimal._fromJson(a);
        if (animal != null && (animal.species != null || animal.speciesCategory != null)) {
          animals.add(animal);
        }
      }
    }
    String? fallbackDescription = json['description'] as String?;
    if (animals.isEmpty) {
      // Geen animals-array: één dier uit top-level velden.
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
      final firstMap = animalsRaw != null &&
              animalsRaw.isNotEmpty &&
              animalsRaw.first is Map<String, dynamic>
          ? animalsRaw.first as Map<String, dynamic>
          : null;
      animals.add(DetectionAnimal(
        species: species,
        speciesCategory: speciesCategory,
        sex: firstMap?['sex'] as String?,
        condition: firstMap?['condition'] as String?,
        lifeStage: firstMap?['lifeStage'] as String?,
        behaviour: firstMap?['behaviour'] as String?,
        confidence: (firstMap?['confidence'] as num?)?.toInt(),
        description: firstMap?['description'] as String? ?? fallbackDescription,
      ));
    }

    final deploymentID = json['deploymentID'] as String? ?? json['deployment_id'] as String?;
    final user = json['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String?;

    return Detection(
      id: id,
      location: location,
      type: type,
      moment: moment,
      animals: animals,
      deploymentID: deploymentID,
      userName: userName,
      description: fallbackDescription,
    );
  }
}
