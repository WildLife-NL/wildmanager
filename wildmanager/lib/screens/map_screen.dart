import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart';

import '../models/living_lab.dart';
import '../services/living_labs_service.dart';

const _keyMapLat = 'map_center_lat';
const _keyMapLng = 'map_center_lng';
const _keyMapZoom = 'map_zoom';
const _mapSaveDebounceMs = 800;

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
  List<LivingLab>? _livingLabs;
  bool _mapStateLoaded = false;
  LatLng? _savedCenter;
  double? _savedZoom;
  Timer? _saveMapStateDebounce;

  @override
  void initState() {
    super.initState();
    _loadMapState().then((_) {
      _mapEventSub = _mapController.mapEventStream.listen((_) {
        _updateVisibleKm();
        _scheduleSaveMapState();
      });
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibleKm());
      }
    });
    _loadLivingLabs();
  }

  Future<void> _loadMapState() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyMapLat);
    final lng = prefs.getDouble(_keyMapLng);
    final zoom = prefs.getDouble(_keyMapZoom);
    if (!mounted) return;
    setState(() {
      _mapStateLoaded = true;
      _savedCenter = (lat != null && lng != null) ? LatLng(lat, lng) : null;
      _savedZoom = zoom;
    });
  }

  void _scheduleSaveMapState() {
    _saveMapStateDebounce?.cancel();
    _saveMapStateDebounce = Timer(
      const Duration(milliseconds: _mapSaveDebounceMs),
      _saveMapState,
    );
  }

  Future<void> _saveMapState() async {
    _saveMapStateDebounce?.cancel();
    _saveMapStateDebounce = null;
    try {
      final camera = _mapController.camera;
      final center = camera.center;
      final zoom = camera.zoom;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyMapLat, center.latitude);
      await prefs.setDouble(_keyMapLng, center.longitude);
      await prefs.setDouble(_keyMapZoom, zoom);
    } catch (_) {}
  }

  Future<void> _loadLivingLabs() async {
    try {
      final list = await fetchLivingLabs();
      if (!mounted) return;
      setState(() => _livingLabs = list);
    } on LivingLabsException catch (e) {
      if (!mounted) return;
      setState(() => _livingLabs = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  void dispose() {
    _saveMapStateDebounce?.cancel();
    _saveMapState();
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

  List<Widget> _livingLabPolygonLayers() {
    final labs = _livingLabs!;
    final polygons = <Polygon>[];
    for (final lab in labs) {
      List<LatLng>? points = lab.definition;
      if (points == null || points.length < 3) continue;
      // Sluit polygoon indien eerste en laatste punt niet gelijk zijn
      if (points.isNotEmpty &&
          (points.first.latitude != points.last.latitude ||
              points.first.longitude != points.last.longitude)) {
        points = [...points, points.first];
      }
      polygons.add(
        Polygon(
          points: points,
          color: const Color(0xFF1565C0).withValues(alpha: 0.35),
          borderColor: const Color(0xFF0D47A1),
          borderStrokeWidth: 3.5,
          isDotted: false,
          label: lab.name,
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }
    if (polygons.isEmpty) return [];
    return [
      PolygonLayer(
        polygons: polygons,
        polygonCulling: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapStateLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final defaultCenter = MapStateInterface.defaultCenter;
    final initialCenter = _savedCenter ?? defaultCenter;
    final initialZoom = _savedZoom ?? 10.0;
    final minZoom = zoomForMaxKm(_maxZoomOutKm, initialCenter.latitude, screenWidth);

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
                initialCenter: initialCenter,
                initialZoom: initialZoom,
                minZoom: minZoom.clamp(5.0, 12.0),
                maxZoom: 18,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              extraLayers: [
                if (_livingLabs != null) ..._livingLabPolygonLayers(),
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
            Positioned(
              right: 16,
              bottom: 24,
              child: _NorthUpButton(mapController: _mapController),
            ),
          ],
        ),
      ),
    );
  }
}

class _NorthUpButton extends StatelessWidget {
  const _NorthUpButton({required this.mapController});

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
