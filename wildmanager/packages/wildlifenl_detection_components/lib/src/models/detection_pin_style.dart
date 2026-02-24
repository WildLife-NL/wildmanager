import 'package:flutter/material.dart';

import 'detection_type.dart';

class DetectionPinStyle {
  const DetectionPinStyle({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;
}

const IconData _defaultSpeciesIcon = Icons.pets;

final Map<String, IconData> defaultSpeciesIcons = <String, IconData>{
  'roe_deer': Icons.pets,
  'red_deer': Icons.pets,
  'wild_boar': Icons.pets,
  'fox': Icons.pets,
  'badger': Icons.pets,
  'rabbit': Icons.pets,
  'bird': Icons.emoji_nature,
  'deer': Icons.pets,
};

IconData iconForSpecies(String? species) {
  if (species == null || species.isEmpty) return _defaultSpeciesIcon;
  final key = species.toLowerCase().replaceAll(' ', '_');
  return defaultSpeciesIcons[key] ?? _defaultSpeciesIcon;
}

String? _speciesNameFromJson(dynamic species) {
  if (species is String) return species;
  if (species is Map<String, dynamic>) {
    return species['commonName'] as String? ?? species['name'] as String? ?? species['category'] as String?;
  }
  return null;
}

DetectionPinStyle getPinStyleForDetection(
  Map<String, dynamic> detection, {
  Color? overrideColor,
  IconData? overrideIcon,
}) {
  final type = detectionTypeFromString(
    detection['sensorType'] as String? ?? detection['type'] as String?,
  );
  final species = _speciesNameFromJson(detection['species']) ?? detection['animal_species'] as String?;
  return DetectionPinStyle(
    color: overrideColor ?? type.color,
    icon: overrideIcon ?? iconForSpecies(species),
  );
}
