import 'package:latlong2/latlong.dart';

const int interactionTypeSighting = 1;
const int interactionTypeDamage = 2;
const int interactionTypeCollision = 3;

/// Eén betrokken dier bij een waarneming/aanrijding (met soort, geslacht, leeftijd, gedrag, beschrijving).
class InvolvedAnimal {
  const InvolvedAnimal({
    this.displayName,
    this.speciesCommonName,
    this.speciesLatinName,
    this.sex,
    this.lifeStage,
    this.behaviour,
    this.description,
  });
  final String? displayName;
  final String? speciesCommonName;
  final String? speciesLatinName;
  /// Geslacht (bijv. male, female).
  final String? sex;
  /// Leeftijd/levensfase (bijv. jong, volwassen).
  final String? lifeStage;
  final String? behaviour;
  final String? description;
}

class Interaction {
  const Interaction({
    required this.id,
    required this.location,
    required this.typeId,
    required this.typeName,
    this.moment,
    this.momentReported,
    this.description,
    this.speciesCommonName,
    this.speciesCategory,
    this.speciesLatinName,
    this.speciesBehaviour,
    this.speciesDescription,
    this.speciesAdvice,
    this.speciesRoleInNature,
    this.typeDescription,
    this.reportTypeLabel,
    this.involvedAnimalNames,
    this.involvedAnimals,
    this.reporterName,
    this.damageBelonging,
    this.damageEstimatedDamage,
    this.damageEstimatedLoss,
    this.damageImpactType,
    this.damageImpactValue,
    this.collisionEstimatedDamage,
    this.collisionIntensity,
    this.collisionUrgency,
  });

  final String id;
  /// Where it happened (used for map pin). Parsed from place, fallback to location.
  final LatLng location;
  final int typeId;
  final String typeName;
  final DateTime? moment;
  final DateTime? momentReported;
  final String? description;
  final String? speciesCommonName;
  final String? speciesCategory;
  /// Latin binomen from species.name
  final String? speciesLatinName;
  /// From reportOfSighting.species (gedrag, beschrijving, advies, rol in de natuur)
  final String? speciesBehaviour;
  final String? speciesDescription;
  final String? speciesAdvice;
  final String? speciesRoleInNature;
  /// type.description (interaction type)
  final String? typeDescription;
  final String? reportTypeLabel;
  final List<String>? involvedAnimalNames;
  /// Per-dier details (soort, gedrag, beschrijving) bij waarneming/aanrijding.
  final List<InvolvedAnimal>? involvedAnimals;
  final String? reporterName;
  /// reportOfDamage (type 2)
  final String? damageBelonging;
  final int? damageEstimatedDamage;
  final int? damageEstimatedLoss;
  final String? damageImpactType;
  final int? damageImpactValue;
  /// reportOfCollision (type 3)
  final int? collisionEstimatedDamage;
  final String? collisionIntensity;
  final String? collisionUrgency;

  static Interaction? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['ID'] as String? ?? json['id'] as String?;
      if (id == null) return null;

      // Prefer place (where it happened) for the pin; fall back to location (where reported).
      final placeJson = json['place'] as Map<String, dynamic>? ?? json['locationWhereItHappened'] as Map<String, dynamic>?;
      final locationJson = json['location'] as Map<String, dynamic>? ?? json['incidentLocation'] as Map<String, dynamic>?;
      final loc = placeJson ?? locationJson;
      if (loc == null) return null;
      final lat = (loc['latitude'] as num?)?.toDouble() ?? (loc['lat'] as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble() ?? (loc['lon'] as num?)?.toDouble() ?? (loc['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final location = LatLng(lat, lng);

      final type = json['type'] as Map<String, dynamic>?;
      final typeId = (type?['ID'] as num?)?.toInt() ?? (type?['id'] as num?)?.toInt() ?? 0;
      final typeName = type?['name'] as String? ?? type?['typeName'] as String? ?? '';
      final typeDescription = type?['description'] as String?;
      final reportTypeLabel = _reportTypeLabel(typeId);

      final momentStr = json['moment'] as String? ?? json['incidentMoment'] as String? ?? json['date'] as String?;
      DateTime? moment;
      if (momentStr != null) moment = DateTime.tryParse(momentStr);
      var reportedStr = json['momentReported'] as String? ?? json['reportedAt'] as String? ?? json['createdAt'] as String? ?? json['reportMoment'] as String? ?? json['timestamp'] as String?;
      DateTime? momentReported;
      if (reportedStr != null) momentReported = DateTime.tryParse(reportedStr);

      final description = json['description'] as String? ?? json['summary'] as String?;
      final reporterName = json['reporterName'] as String? ?? json['reporter_name'] as String? ?? json['createdBy'] as String? ?? json['userName'] as String? ?? (json['user'] as Map<String, dynamic>?)?['name'] as String? ?? (json['reporter'] as Map<String, dynamic>?)?['name'] as String?;

      String? speciesCommonName;
      String? speciesCategory;

      String? fromSpecies(Map<String, dynamic>? s) {
        if (s == null) return null;
        return s['commonName'] as String? ?? s['common_name'] as String? ?? s['name'] as String? ?? s['commonNameNL'] as String?;
      }

      List<String>? involvedAnimalNames;
      List<InvolvedAnimal>? involvedAnimals;
      final sighting = json['reportOfSighting'] as Map<String, dynamic>? ?? json['report_of_sighting'] as Map<String, dynamic>?;
      String? speciesLatinName;
      String? speciesBehaviour;
      String? speciesDescription;
      String? speciesAdvice;
      String? speciesRoleInNature;
      if (sighting != null) {
        final sightingSpecies = sighting['species'] as Map<String, dynamic>?;
        speciesCommonName ??= fromSpecies(sightingSpecies);
        speciesCommonName ??= sighting['speciesCommonName'] as String? ?? sighting['species_common_name'] as String? ?? sighting['commonName'] as String?;
        speciesCategory ??= sightingSpecies?['category'] as String? ?? sighting['speciesCategory'] as String?;
        speciesLatinName = sightingSpecies?['name'] as String? ?? sighting['speciesLatinName'] as String?;
        speciesBehaviour = sightingSpecies?['behaviour'] as String? ?? sighting['speciesBehaviour'] as String?;
        speciesDescription = sightingSpecies?['description'] as String? ?? sighting['speciesDescription'] as String?;
        speciesAdvice = sightingSpecies?['advice'] as String? ?? sighting['speciesAdvice'] as String?;
        speciesRoleInNature = sightingSpecies?['roleInNature'] as String? ?? sighting['roleInNature'] as String? ?? sighting['speciesRoleInNature'] as String?;
        final involved = sighting['involvedAnimals'] as List<dynamic>? ?? sighting['involved_animals'] as List<dynamic>?;
        involvedAnimals = _parseInvolvedAnimals(involved);
        involvedAnimalNames = involvedAnimals != null ? involvedAnimals.map((a) => a.displayName ?? a.speciesCommonName ?? '—').where((s) => s != '—').toList() : _parseInvolvedAnimalNames(involved);
        if (involvedAnimalNames != null && involvedAnimalNames.isEmpty) involvedAnimalNames = null;
        final first = involved?.isNotEmpty == true ? involved!.first as Map<String, dynamic>? : null;
        final species = first?['species'] ?? sighting['species'] as Map<String, dynamic>?;
        if (species != null) {
          speciesCommonName ??= fromSpecies(species);
          speciesCategory ??= species['category'] as String? ?? species['speciesCategory'] as String?;
          speciesLatinName ??= species['name'] as String?;
        }
        speciesCommonName ??= first?['speciesCommonName'] as String? ?? first?['species_common_name'] as String? ?? first?['commonName'] as String?;
        if (momentReported == null) {
          final ts = sighting['timestamp'] as String? ?? sighting['reportedAt'] as String?;
          if (ts != null) momentReported = DateTime.tryParse(ts);
        }
      }
      final damageReport = json['reportOfDamage'] as Map<String, dynamic>? ?? json['report_of_damage'] as Map<String, dynamic>?;
      if (damageReport != null && involvedAnimals == null) {
        final involved = damageReport['involvedAnimals'] as List<dynamic>? ?? damageReport['involved_animals'] as List<dynamic>?;
        involvedAnimals = _parseInvolvedAnimals(involved);
        involvedAnimalNames ??= involvedAnimals != null ? involvedAnimals.map((a) => a.displayName ?? a.speciesCommonName ?? '—').where((s) => s != '—').toList() : _parseInvolvedAnimalNames(involved);
        if (involvedAnimalNames != null && involvedAnimalNames.isEmpty) involvedAnimalNames = null;
      }
      final collisionReport = json['reportOfCollision'] as Map<String, dynamic>? ??
          json['reportOfAnimalVehicleCollision'] as Map<String, dynamic>? ??
          json['report_of_animal_vehicle_collision'] as Map<String, dynamic>?;
      if (collisionReport != null && involvedAnimals == null) {
        final involved = collisionReport['involvedAnimals'] as List<dynamic>? ?? collisionReport['involved_animals'] as List<dynamic>?;
        involvedAnimals = _parseInvolvedAnimals(involved);
        involvedAnimalNames ??= involvedAnimals != null ? involvedAnimals.map((a) => a.displayName ?? a.speciesCommonName ?? '—').where((s) => s != '—').toList() : _parseInvolvedAnimalNames(involved);
        if (involvedAnimalNames != null && involvedAnimalNames.isEmpty) involvedAnimalNames = null;
      }

      int? damageEstimatedDamage;
      int? damageEstimatedLoss;
      int? damageImpactValue;
      String? damageBelonging;
      String? damageImpactType;
      if (damageReport != null) {
        damageBelonging = damageReport['belonging'] as String?;
        damageEstimatedDamage = (damageReport['estimatedDamage'] as num?)?.toInt();
        damageEstimatedLoss = (damageReport['estimatedLoss'] as num?)?.toInt();
        damageImpactType = damageReport['impactType'] as String?;
        damageImpactValue = (damageReport['impactValue'] as num?)?.toInt();
      }

      int? collisionEstimatedDamage;
      String? collisionIntensity;
      String? collisionUrgency;
      if (collisionReport != null) {
        collisionEstimatedDamage = (collisionReport['estimatedDamage'] as num?)?.toInt();
        collisionIntensity = collisionReport['intensity'] as String?;
        collisionUrgency = collisionReport['urgency'] as String?;
      }

      speciesCommonName ??= json['speciesCommonName'] as String? ?? json['species_common_name'] as String? ?? json['commonName'] as String?;
      final topSpecies = json['species'] as Map<String, dynamic>?;
      speciesCommonName ??= fromSpecies(topSpecies);
      speciesCategory ??= json['speciesCategory'] as String? ?? json['species_category'] as String? ?? (topSpecies != null ? topSpecies['category'] as String? : null);
      speciesLatinName ??= topSpecies?['name'] as String? ?? json['speciesLatinName'] as String? ?? json['species_name'] as String?;
      speciesBehaviour ??= topSpecies?['behaviour'] as String? ?? json['speciesBehaviour'] as String?;
      speciesDescription ??= topSpecies?['description'] as String? ?? json['speciesDescription'] as String?;
      speciesAdvice ??= topSpecies?['advice'] as String? ?? json['speciesAdvice'] as String?;
      speciesRoleInNature ??= topSpecies?['roleInNature'] as String? ?? json['speciesRoleInNature'] as String?;

      return Interaction(
        id: id,
        location: location,
        typeId: typeId,
        typeName: typeName,
        moment: moment,
        momentReported: momentReported,
        description: description,
        speciesCommonName: speciesCommonName,
        speciesCategory: speciesCategory,
        speciesLatinName: speciesLatinName,
        speciesBehaviour: speciesBehaviour,
        speciesDescription: speciesDescription,
        speciesAdvice: speciesAdvice,
        speciesRoleInNature: speciesRoleInNature,
        typeDescription: typeDescription,
        reportTypeLabel: reportTypeLabel,
        involvedAnimalNames: involvedAnimalNames,
        involvedAnimals: involvedAnimals,
        reporterName: reporterName,
        damageBelonging: damageBelonging,
        damageEstimatedDamage: damageEstimatedDamage,
        damageEstimatedLoss: damageEstimatedLoss,
        damageImpactType: damageImpactType,
        damageImpactValue: damageImpactValue,
        collisionEstimatedDamage: collisionEstimatedDamage,
        collisionIntensity: collisionIntensity,
        collisionUrgency: collisionUrgency,
      );
    } catch (_) {
      return null;
    }
  }

  static String _reportTypeLabel(int typeId) {
    switch (typeId) {
      case interactionTypeSighting:
        return 'SightingReport';
      case interactionTypeDamage:
        return 'DamageReport';
      case interactionTypeCollision:
        return 'AnimalVehicleCollisionReport';
      default:
        return 'Interaction';
    }
  }

  static List<String>? _parseInvolvedAnimalNames(List<dynamic>? involved) {
    if (involved == null || involved.isEmpty) return null;
    final names = <String>[];
    for (final e in involved) {
      if (e is Map<String, dynamic>) {
        final name = e['name'] as String? ?? e['commonName'] as String? ?? (e['species'] as Map<String, dynamic>?)?['commonName'] as String? ?? (e['species'] as Map<String, dynamic>?)?['name'] as String?;
        if (name != null && name.trim().isNotEmpty) names.add(name.trim());
      }
    }
    return names.isEmpty ? null : names;
  }

  static List<InvolvedAnimal>? _parseInvolvedAnimals(List<dynamic>? involved) {
    if (involved == null || involved.isEmpty) return null;
    final list = <InvolvedAnimal>[];
    for (final e in involved) {
      if (e is! Map<String, dynamic>) continue;
      final species = e['species'] as Map<String, dynamic>?;
      final common = species?['commonName'] as String? ?? species?['common_name'] as String? ?? species?['vernacularName'] as String? ?? e['commonName'] as String? ?? e['common_name'] as String? ?? e['speciesCommonName'] as String? ?? e['species_common_name'] as String? ?? e['vernacularName'] as String? ?? e['label'] as String?;
      final latin = species?['name'] as String? ?? species?['scientificName'] as String? ?? species?['category'] as String? ?? e['speciesLatinName'] as String? ?? e['species_name'] as String? ?? e['latinName'] as String?;
      final displayName = e['name'] as String? ?? e['commonName'] as String? ?? e['common_name'] as String? ?? e['label'] as String? ?? common;
      final behaviour = species?['behaviour'] as String? ?? e['behaviour'] as String? ?? e['behavior'] as String?;
      final description = species?['description'] as String? ?? e['description'] as String?;
      final lifeStage = e['lifeStage'] as String? ?? e['life_stage'] as String? ?? e['age'] as String? ?? e['ageClass'] as String? ?? e['levensfase'] as String? ?? species?['lifeStage'] as String?;
      final sex = e['sex'] as String? ?? e['gender'] as String? ?? e['geslacht'] as String? ?? species?['sex'] as String?;
      list.add(InvolvedAnimal(
        displayName: displayName?.trim().isEmpty == true ? null : displayName?.trim(),
        speciesCommonName: common?.trim().isEmpty == true ? null : common?.trim(),
        speciesLatinName: latin?.trim().isEmpty == true ? null : latin?.trim(),
        sex: sex?.trim().isEmpty == true ? null : sex?.trim(),
        lifeStage: lifeStage?.trim().isEmpty == true ? null : lifeStage?.trim(),
        behaviour: behaviour?.trim().isEmpty == true ? null : behaviour?.trim(),
        description: description?.trim().isEmpty == true ? null : description?.trim(),
      ));
    }
    return list.isEmpty ? null : list;
  }
}
