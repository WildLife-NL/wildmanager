import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class NorthUpButton extends StatelessWidget {
  const NorthUpButton({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white.withValues(alpha: 0.92),
      child: IconButton(
        onPressed: () => mapController.rotate(0),
        icon: Icon(Icons.explore, size: 24, color: Colors.grey.shade700),
        tooltip: 'Noord naar boven',
      ),
    );
  }
}
