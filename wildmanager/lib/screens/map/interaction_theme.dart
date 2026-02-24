import 'package:flutter/material.dart';

import '../../models/interaction.dart';

Color colorForInteractionType(int typeId) {
  switch (typeId) {
    case interactionTypeSighting:
      return const Color(0xFF7B1FA2);
    case interactionTypeDamage:
      return const Color(0xFFF9A825);
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

String formatMoment(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
