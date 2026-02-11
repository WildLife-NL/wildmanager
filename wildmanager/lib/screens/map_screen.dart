import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart';

/// Berekent de zichtbare breedte in km uit de kaartbounds (nauwkeurig).
double visibleWidthKmFromBounds(LatLngBounds bounds) {
  final centerLat = (bounds.north + bounds.south) / 2;
  final lonDeg = (bounds.east - bounds.west).abs();
  if (lonDeg <= 0) return 0;
  final latRad = centerLat * math.pi / 180;
  final kmPerDegreeLon = 111.32 * math.cos(latRad);
  return lonDeg * kmPerDegreeLon;
}

/// Zoomniveau voor max zichtbare breedte (Web Mercator, 256 tiles).
double zoomForMaxKm(double maxKm, double latDeg, double screenWidthPx) {
  const earthCircumferenceM = 40075017.0;
  const tileSize = 256.0;
  final latRad = latDeg * math.pi / 180;
  final metersPerPx = maxKm * 1000 / screenWidthPx;
  final twoPowZoom = math.cos(latRad) * earthCircumferenceM / (tileSize * metersPerPx);
  return math.log(twoPowZoom) / math.ln2;
}

const double _maxZoomOutKm = 200;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<MapEvent>? _mapEventSub;
  double _visibleKm = 0;

  @override
  void initState() {
    super.initState();
    _mapEventSub = _mapController.mapEventStream.listen((_) => _updateVisibleKm());
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibleKm());
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    super.dispose();
  }

  void _updateVisibleKm() {
    final camera = _mapController.camera;
    try {
      final bounds = camera.visibleBounds;
      final km = visibleWidthKmFromBounds(bounds);
      if (mounted && (_visibleKm - km).abs() > 0.3) {
        setState(() => _visibleKm = km);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final minZoom = zoomForMaxKm(_maxZoomOutKm, MapStateInterface.defaultCenter.latitude, screenWidth);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            WildLifeNLMap(
              userAgentPackageName: 'wildmanager',
              mapController: _mapController,
              options: MapOptions(
                initialCenter: MapStateInterface.defaultCenter,
                initialZoom: 10,
                minZoom: minZoom.clamp(5.0, 12.0),
                maxZoom: 18,
              ),
              extraLayers: [
                MarkerLayer(
                  markers: [
                    Marker(
                      point: MapStateInterface.defaultCenter,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.place,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 24,
              child: _ZoomScaleIndicator(visibleKm: _visibleKm),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomScaleIndicator extends StatelessWidget {
  const _ZoomScaleIndicator({required this.visibleKm});

  final double visibleKm;

  @override
  Widget build(BuildContext context) {
    String text;
    if (visibleKm >= 100) {
      text = '${visibleKm.round()} km';
    } else if (visibleKm >= 10) {
      text = '${visibleKm.round()} km';
    } else if (visibleKm >= 1) {
      text = '${visibleKm.toStringAsFixed(1)} km';
    } else if (visibleKm >= 0.1) {
      text = '${(visibleKm * 1000).round()} m';
    } else {
      text = '${(visibleKm * 1000).round()} m';
    }

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.zoom_out_map, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
