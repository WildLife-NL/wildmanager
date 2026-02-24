import 'package:flutter/material.dart';

enum DetectionType {
  visual,
  acoustic,
  chemical,
  other,
}

extension DetectionTypeColors on DetectionType {
  Color get color {
    switch (this) {
      case DetectionType.visual:
        return Colors.red;
      case DetectionType.acoustic:
        return Colors.orange;
      case DetectionType.chemical:
        return Colors.green;
      case DetectionType.other:
        return Colors.grey;
    }
  }
}

DetectionType detectionTypeFromString(String? value) {
  if (value == null || value.isEmpty) return DetectionType.other;
  final lower = value.toLowerCase();
  switch (lower) {
    case 'visual':
      return DetectionType.visual;
    case 'acoustic':
      return DetectionType.acoustic;
    case 'chemical':
      return DetectionType.chemical;
    default:
      return DetectionType.other;
  }
}
