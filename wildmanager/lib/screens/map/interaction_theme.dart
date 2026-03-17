import 'package:flutter/material.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

import '../../models/interaction.dart';

const Color mapColorAnimal = Color(0xFFE91E8C);
const Color mapColorAnimalTrail = Color(0xFFE91E8C);
const Color mapColorDetection = Color(0xFF00BCD4);

Color colorForDetectionType(DetectionType type) {
  switch (type) {
    case DetectionType.visual:
      return mapColorDetection;
    case DetectionType.acoustic:
      return const Color(0xFFFF9800);
    case DetectionType.chemical:
    case DetectionType.other:
      return Colors.grey;
  }
}

Color colorForInteractionType(int typeId) {
  switch (typeId) {
    case interactionTypeSighting:
      return const Color(0xFF7B1FA2);
    case interactionTypeDamage:
      return const Color(0xFF00897B);
    case interactionTypeCollision:
      return const Color(0xFF1976D2);
    default:
      return Colors.grey;
  }
}

IconData iconForInteractionType(int typeId) {
  switch (typeId) {
    case interactionTypeSighting:
      return Icons.pets;
    case interactionTypeDamage:
      return Icons.home_repair_service;
    case interactionTypeCollision:
      return Icons.directions_car;
    default:
      return Icons.place;
  }
}

String typeLabelForInteraction(Interaction interaction) {
  if (interaction.typeName.isNotEmpty) return interaction.typeName;
  switch (interaction.typeId) {
    case interactionTypeSighting:
      return 'Waarneming';
    case interactionTypeDamage:
      return 'Schade';
    case interactionTypeCollision:
      return 'Aanrijding';
    default:
      return 'Interactie';
  }
}

String typeNameShortForInteraction(Interaction interaction) {
  switch (interaction.typeId) {
    case interactionTypeSighting:
      return 'waarneming';
    case interactionTypeDamage:
      return 'schademelding';
    case interactionTypeCollision:
      return 'dieraanrijding';
    default:
      return interaction.typeName.isNotEmpty ? interaction.typeName.toLowerCase() : 'interactie';
  }
}

String formatMoment(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
