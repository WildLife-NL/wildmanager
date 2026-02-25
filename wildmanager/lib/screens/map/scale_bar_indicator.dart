import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'map_math.dart';

class ScaleBarIndicator extends StatefulWidget {
  const ScaleBarIndicator({super.key, required this.mapController});

  final MapController mapController;

  @override
  State<ScaleBarIndicator> createState() => _ScaleBarIndicatorState();
}

class _ScaleBarIndicatorState extends State<ScaleBarIndicator> {
  static const List<int> _allowedMeters = [
    50000, 20000, 10000, 9000, 8000, 7000, 6000, 5000, 4500, 4000, 3500,
    3000, 2500, 2000, 1500, 1000, 750, 500, 400, 300, 250, 200, 150, 100, 75, 50,
  ];

  double _barPx = 90;
  String _label = '1 km';
  StreamSubscription<MapEvent>? _mapSub;
  Timer? _recalcDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalc();
      _mapSub = widget.mapController.mapEventStream.listen((_) {
        _recalcDebounce?.cancel();
        _recalcDebounce = Timer(const Duration(milliseconds: 200), _recalc);
      });
    });
  }

  @override
  void dispose() {
    _recalcDebounce?.cancel();
    _mapSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ScaleBarIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController != widget.mapController) {
      _mapSub?.cancel();
      _mapSub = widget.mapController.mapEventStream.listen((_) {
        _recalcDebounce?.cancel();
        _recalcDebounce = Timer(const Duration(milliseconds: 200), _recalc);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalc());
  }

  void _recalc() {
    if (!mounted) return;
    final cam = widget.mapController.camera;
    final zoom = cam.zoom.toDouble();
    if (zoom < 0 || zoom > 22) return;
    final mpp = metersPerLogicalPxWebMercator(
      zoom, cam.center.latitude, zoomOffset: zoomScaleOffset,
    );
    if (mpp <= 0 || mpp > 1e7) return;

    const double minPx = 70;
    const double maxPx = 140;

    int chosenM = _allowedMeters.last;
    double chosenPx = chosenM / mpp;

    for (final m in _allowedMeters) {
      final px = m / mpp;
      if (px >= minPx && px <= maxPx) {
        chosenM = m;
        chosenPx = px;
        break;
      }
    }

    if (chosenPx < minPx) {
      final lastM = _allowedMeters.last;
      chosenM = lastM;
      chosenPx = math.max(minPx, lastM / mpp);
    } else if (chosenPx > maxPx) {
      final firstM = _allowedMeters.first;
      chosenM = firstM;
      chosenPx = math.min(maxPx, firstM / mpp);
    }

    final label = chosenM >= 1000 ? '${chosenM ~/ 1000} km' : '${chosenM} m';
    if ((chosenPx - _barPx).abs() > 1 || label != _label) {
      setState(() {
        _barPx = chosenPx;
        _label = label;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 6,
                  width: _barPx,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.straighten, size: 16, color: Colors.grey.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
