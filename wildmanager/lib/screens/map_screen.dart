import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart';

import '../models/interaction.dart';
import '../models/living_lab.dart';
import '../services/interactions_service.dart';
import '../services/living_labs_service.dart';
import 'map/interaction_filter_sheet.dart';
import 'map/interaction_theme.dart';
import 'map/interactions_info.dart';
import 'map/map_math.dart';
import 'map/north_up_button.dart';
import 'map/scale_bar_indicator.dart';

const _keyMapLat = 'map_center_lat';
const _keyMapLng = 'map_center_lng';
const _keyMapZoom = 'map_zoom';

const _mapSaveDebounceMs = 800;
const _interactionsDebounceMs = 800;
const _visibleKmDebounceMs = 250;

const double _maxZoomOutKm = 200;
const int _maxVisibleMarkersZoomedIn = 150;
const int _maxVisibleMarkersZoomedOut = 400;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  StreamSubscription<MapEvent>? _mapEventSub;

  double _visibleKm = 0;
  double _screenWidthPx = 400;

  List<LivingLab>? _livingLabs;

  bool _mapStateLoaded = false;
  LatLng? _savedCenter;
  double? _savedZoom;

  Timer? _saveMapStateDebounce;

  List<Interaction>? _interactions;
  bool _interactionsLoading = false;

  int? _lastFetchRadiusMeters;
  LatLng? _lastFetchedCenter;
  double? _lastFetchedVisibleKm;

  Timer? _interactionsDebounce;
  Timer? _interactionsPollTimer;
  Timer? _visibleKmDebounce;

  int? _interactionTypeFilter;
  DateTime? _momentAfter;
  DateTime? _momentBefore;

  int _interactionRequestId = 0;

  bool _interactionInDateRange(Interaction i) {
    if (_momentAfter == null && _momentBefore == null) return true;
    final m = i.moment?.toLocal();
    if (m == null) return false;
    final afterStart = _momentAfter != null
        ? DateTime(_momentAfter!.year, _momentAfter!.month, _momentAfter!.day)
        : null;
    final beforeEnd = _momentBefore != null
        ? DateTime(_momentBefore!.year, _momentBefore!.month, _momentBefore!.day, 23, 59, 59, 999)
        : null;
    if (afterStart != null && m.isBefore(afterStart)) return false;
    if (beforeEnd != null && m.isAfter(beforeEnd)) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadMapState().then((_) {
      _mapEventSub = _mapController.mapEventStream.listen((_) {
        _visibleKmDebounce?.cancel();
        _visibleKmDebounce = Timer(
          const Duration(milliseconds: _visibleKmDebounceMs),
          _updateVisibleKm,
        );
        _scheduleSaveMapState();
        _scheduleLoadInteractions();
      });

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateVisibleKm();
          Future.delayed(const Duration(milliseconds: 350), () {
            if (!mounted) return;
            _loadInteractions();
          });
        });

        _interactionsPollTimer = Timer.periodic(
          const Duration(milliseconds: 3000),
          (_) => _checkMapMovedAndReload(),
        );
      }
    });

    _loadLivingLabs();
  }

  void _checkMapMovedAndReload() {
    if (!mounted || _interactionsLoading) return;

    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return;
    }

    final center = _mapController.camera.center;
    final visibleKm = visibleWidthKmFromBounds(bounds);

    if (_lastFetchedCenter == null || _lastFetchedVisibleKm == null) {
      _scheduleLoadInteractions();
      return;
    }

    final centerMoved = (center.latitude - _lastFetchedCenter!.latitude).abs() > 0.0015 ||
        (center.longitude - _lastFetchedCenter!.longitude).abs() > 0.0015;
    final zoomChanged = (visibleKm - _lastFetchedVisibleKm!).abs() > 1.2;

    if (centerMoved || zoomChanged) _scheduleLoadInteractions();
  }

  void _scheduleLoadInteractions() {
    _interactionsDebounce?.cancel();
    _interactionsDebounce = Timer(
      const Duration(milliseconds: _interactionsDebounceMs),
      _loadInteractions,
    );
  }

  Future<void> _loadInteractions() async {
    _interactionsDebounce?.cancel();
    _interactionsDebounce = null;
    if (!mounted) return;

    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return;
    }

    final camera = _mapController.camera;
    final requestedCenter = camera.center;

    final radiusMeters = computeRadiusMetersForBounds(requestedCenter, bounds);
    final requestId = ++_interactionRequestId;

    setState(() => _interactionsLoading = true);

    try {
      final before = _momentBefore != null
          ? DateTime(_momentBefore!.year, _momentBefore!.month, _momentBefore!.day, 23, 59, 59, 999)
          : null;
      final list = await fetchInteractions(
        center: requestedCenter,
        radiusMeters: radiusMeters,
        momentAfter: _momentAfter,
        momentBefore: before,
        interactionTypeId: _interactionTypeFilter,
      );

      if (!mounted) return;
      if (requestId != _interactionRequestId) return;

      LatLngBounds nowBounds;
      try {
        nowBounds = _mapController.camera.visibleBounds;
      } catch (_) {
        return;
      }

      final listInRange = list.where(_interactionInDateRange).toList();
      final merged = <String, Interaction>{};
      for (final i in _interactions ?? <Interaction>[]) {
        if (_interactionInDateRange(i)) merged[i.id] = i;
      }
      for (final i in listInRange) {
        merged[i.id] = i;
      }
      var mergedList = merged.values.toList();
      if (mergedList.length > 2000) {
        mergedList = mergedList.take(2000).toList();
      }

      setState(() {
        _interactions = mergedList;
        _interactionsLoading = false;
        _lastFetchRadiusMeters = radiusMeters;
        _lastFetchedCenter = requestedCenter;
        _lastFetchedVisibleKm = visibleWidthKmFromBounds(nowBounds);
      });
    } catch (_) {
      if (!mounted) return;
      if (requestId != _interactionRequestId) return;
      setState(() {
        _interactions = null;
        _interactionsLoading = false;
        _lastFetchRadiusMeters = null;
      });
    }
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
    _visibleKmDebounce?.cancel();
    _interactionsDebounce?.cancel();
    _interactionsPollTimer?.cancel();
    _saveMapState();
    _mapEventSub?.cancel();
    super.dispose();
  }

  void _updateVisibleKm() {
    final camera = _mapController.camera;
    final zoom = camera.zoom;
    final lat = camera.center.latitude;
    final w = _screenWidthPx > 0 ? _screenWidthPx : 400;
    final km = visibleWidthKmFromZoom(
        zoom, lat, w, zoomOffset: zoomScaleOffset);
    final clamped = km.clamp(0.05, 500.0);
    if (mounted && (_visibleKm - clamped).abs() > 0.5) {
      setState(() => _visibleKm = clamped);
    }
  }

  List<Widget> _livingLabPolygonLayers() {
    final labs = _livingLabs!;
    final polygons = <Polygon>[];
    for (final lab in labs) {
      List<LatLng>? points = lab.definition;
      if (points == null || points.length < 3) continue;
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

  int _maxMarkersForCurrentZoom() {
    try {
      final zoom = _mapController.camera.zoom;
      if (zoom >= 10) return _maxVisibleMarkersZoomedIn;
      if (zoom <= 7) return _maxVisibleMarkersZoomedOut;
      final t = (zoom - 7) / 3;
      return (_maxVisibleMarkersZoomedOut + t * (_maxVisibleMarkersZoomedIn - _maxVisibleMarkersZoomedOut)).round();
    } catch (_) {
      return _maxVisibleMarkersZoomedIn;
    }
  }

  List<Marker> _interactionMarkers() {
    final list = _interactions;
    if (list == null || list.isEmpty) return [];
    final maxMarkers = _maxMarkersForCurrentZoom();
    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      final toShow = list.take(maxMarkers).toList();
      return toShow.map((i) => _buildInteractionMarker(i)).toList();
    }
    final inBounds = list.where((i) => pointInBounds(i.location, bounds)).toList();
    final toShow = inBounds.take(maxMarkers).toList();
    return toShow.map((i) => _buildInteractionMarker(i)).toList();
  }

  int _getVisibleMarkerCount() {
    final list = _interactions;
    if (list == null || list.isEmpty) return 0;
    final maxMarkers = _maxMarkersForCurrentZoom();
    try {
      final bounds = _mapController.camera.visibleBounds;
      final inBounds = list.where((i) => pointInBounds(i.location, bounds)).length;
      return inBounds > maxMarkers ? maxMarkers : inBounds;
    } catch (_) {
      return list.length > maxMarkers ? maxMarkers : list.length;
    }
  }

  Marker _buildInteractionMarker(Interaction i) {
    final color = colorForInteractionType(i.typeId);
    final iconData = iconForInteractionType(i.typeId);
    return Marker(
      point: i.location,
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => _showInteractionDetail(i),
        child: Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 2,
          child: Center(
            child: Icon(iconData, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  void _showInteractionDetail(Interaction interaction) {
    final typeLabel = typeLabelForInteraction(interaction);
    final typeColor = colorForInteractionType(interaction.typeId);
    final typeIcon = iconForInteractionType(interaction.typeId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.7,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Material(
                    color: typeColor,
                    shape: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(typeIcon, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      typeLabel,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              if (interaction.moment != null) ...[
                const SizedBox(height: 8),
                Text(
                  formatMoment(interaction.moment!),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              if (interaction.description != null &&
                  interaction.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  interaction.description!,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
              if (interaction.speciesCommonName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.pets, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      interaction.speciesCategory != null
                          ? '${interaction.speciesCommonName} (${interaction.speciesCategory})'
                          : interaction.speciesCommonName!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Locatie: ${interaction.location.latitude.toStringAsFixed(5)}, ${interaction.location.longitude.toStringAsFixed(5)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInteractionFilters() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => InteractionFilterSheet(
        typeFilter: _interactionTypeFilter,
        momentAfter: _momentAfter,
        momentBefore: _momentBefore,
        onApply: (typeId, after, before) {
          setState(() {
            _interactionTypeFilter = typeId;
            _momentAfter = after;
            _momentBefore = before;
            _interactions = null;
          });
          _loadInteractions();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapStateLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    _screenWidthPx = screenWidth;

    final defaultCenter = MapStateInterface.defaultCenter;
    final initialCenter = _savedCenter ?? defaultCenter;
    final initialZoom = _savedZoom ?? 10.0;

    final minZoomRaw = zoomForMaxKm(_maxZoomOutKm, initialCenter.latitude, screenWidth);
    final minZoom = minZoomRaw.clamp(5.0, 12.0);

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
                minZoom: minZoom,
                maxZoom: 18,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              extraLayers: [
                if (_livingLabs != null) ..._livingLabPolygonLayers(),
                MarkerLayer(
                  markers: _interactionMarkers(),
                ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaleBarIndicator(mapController: _mapController),
                  if (_lastFetchRadiusMeters != null && _interactions != null) ...[
                    const SizedBox(height: 8),
                    InteractionsInfo(
                      count: _interactions!.length,
                      visibleCount: _getVisibleMarkerCount(),
                      radiusMeters: _lastFetchRadiusMeters!,
                      visibleKm: _visibleKm,
                      onRefresh: _loadInteractions,
                      isLoading: _interactionsLoading,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filled(
                    onPressed: _openInteractionFilters,
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filters',
                  ),
                  const SizedBox(height: 8),
                  NorthUpButton(mapController: _mapController),
                ],
              ),
            ),
            if (_interactionsLoading)
              const Positioned(
                top: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
