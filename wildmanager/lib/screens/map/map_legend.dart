import 'package:flutter/material.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

import '../../models/interaction.dart';

import 'interaction_theme.dart' as theme;

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legenda',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _row(context, theme.colorForInteractionType(interactionTypeSighting), 'Waarneming', isCircle: true),
            _row(context, theme.colorForInteractionType(interactionTypeDamage), 'Schade', isCircle: true),
            _row(context, theme.colorForInteractionType(interactionTypeCollision), 'Aanrijding', isCircle: true),
            _row(context, const Color(0xFF2E7D32), 'Dieren', isCircle: true),
            _row(context, DetectionType.visual.color, 'Detectie visueel', isCircle: false),
            _row(context, DetectionType.acoustic.color, 'Detectie akoestisch', isCircle: false),
            _row(context, DetectionType.other.color, 'Detectie overig', isCircle: false),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.red],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Recreatiedruk', style: _labelStyle(context)),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.5),
                    border: Border.all(color: const Color(0xFF0D47A1)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Living lab', style: _labelStyle(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Color color, String label, {bool isCircle = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(2),
              border: Border.all(color: Colors.white70, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: _labelStyle(context)),
        ],
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
