import 'package:flutter/material.dart';

import 'map_math.dart';

class InteractionsInfo extends StatelessWidget {
  const InteractionsInfo({
    super.key,
    required this.count,
    required this.visibleCount,
    required this.radiusMeters,
    required this.visibleKm,
    required this.onRefresh,
    required this.isLoading,
  });

  final int count;
  final int visibleCount;
  final int radiusMeters;
  final double visibleKm;
  final VoidCallback onRefresh;
  final bool isLoading;

  static const int _likelyApiResultCap = 500;

  @override
  Widget build(BuildContext context) {
    final radiusKm = radiusMeters >= 1000
        ? '${(radiusMeters / 1000).toStringAsFixed(1)} km'
        : '$radiusMeters m';
    final isCapped = radiusMeters >= apiMaxRadiusMeters;
    final displayKm = visibleKm.clamp(0.2, 500.0);
    final visibleStr = displayKm >= 1
        ? '${displayKm.toStringAsFixed(1)} km'
        : '${(displayKm * 1000).round()} m';
    final radiusLabel = isCapped ? '$radiusKm (max)' : radiusKm;

    final countLabel = visibleCount < count
        ? '$visibleCount in beeld (${count >= _likelyApiResultCap ? "$count+" : count} totaal)'
        : (count >= _likelyApiResultCap
            ? '$count+ interacties (max. door API)'
            : '$count interacties');

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$countLabel · zoekradius $radiusLabel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Kaart toont ~${visibleStr} breed',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : onRefresh,
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey.shade700,
                          ),
                        )
                      : Icon(Icons.refresh, size: 20, color: Colors.grey.shade700),
                  tooltip: 'Interacties vernieuwen',
                ),
              ],
            ),
            Text(
              'Opnieuw laden: bij pannen/zoomen of na filters toepassen',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
