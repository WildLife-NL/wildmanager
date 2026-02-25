import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart';

import '../models/detection.dart';
import '../models/interaction.dart';
import '../models/living_lab.dart';
import '../services/detections_service.dart';
import '../services/interactions_service.dart';
import '../services/living_labs_service.dart';
import '../services/visitation_service.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';
import 'package:wildlifenl_visitation_components/wildlifenl_visitation_components.dart';
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
const double _minVisibleWidthM = 50;
const int _maxVisibleMarkersCap = 1200;

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
  List<HeatmapCell>? _heatmapCells;
  bool _heatmapLoading = false;

  bool _mapStateLoaded = false;
  LatLng? _savedCenter;
  double? _savedZoom;

  Timer? _saveMapStateDebounce;

  List<Interaction>? _interactions;
  bool _interactionsLoading = false;

  List<Detection>? _detections;
  bool _detectionsLoading = false;
  int _detectionRequestId = 0;

  int? _lastFetchRadiusMeters;
  LatLng? _lastFetchedCenter;
  double? _lastFetchedVisibleKm;

  Timer? _interactionsDebounce;
  Timer? _interactionsPollTimer;
  Timer? _visibleKmDebounce;

  int? _interactionTypeFilter;
  DetectionType? _detectionTypeFilter;
  DateTime? _momentAfter;
  DateTime? _momentBefore;
  int? _heatmapRoodVanaf;
  double? _heatmapCellSizeMeters;

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
    if (!mounted || _interactionsLoading || _detectionsLoading) return;

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

    if (centerMoved || zoomChanged) {
      _scheduleLoadInteractions();
      _scheduleLoadDetections();
    }
  }

  Timer? _detectionsDebounce;

  void _scheduleLoadDetections() {
    _detectionsDebounce?.cancel();
    _detectionsDebounce = Timer(
      const Duration(milliseconds: _interactionsDebounceMs),
      _loadDetections,
    );
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

  Future<void> _loadDetections() async {
    _detectionsDebounce?.cancel();
    _detectionsDebounce = null;
    if (!mounted) return;

    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return;
    }

    final center = _mapController.camera.center;
    final radiusMeters = computeRadiusMetersForBounds(center, bounds);
    final requestId = ++_detectionRequestId;

    var end = _momentBefore != null
        ? DateTime(_momentBefore!.year, _momentBefore!.month, _momentBefore!.day, 23, 59, 59, 999)
        : DateTime.now();
    var start = _momentAfter ?? end.subtract(const Duration(days: 30));
    if (start.isAfter(end)) start = end.subtract(const Duration(days: 1));

    setState(() => _detectionsLoading = true);
    debugPrint('[MapScreen] Detections laden: center=(${center.latitude}, ${center.longitude}) radius=${radiusMeters}m');

    try {
      final list = await fetchDetections(
        center: center,
        radiusMeters: radiusMeters,
        start: start,
        end: end,
        typeFilter: _detectionTypeFilter,
      );

      if (!mounted) return;
      if (requestId != _detectionRequestId) return;

      debugPrint('[MapScreen] Detections geladen: ${list.length} stuks');
      setState(() {
        _detections = list;
        _detectionsLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      if (requestId != _detectionRequestId) return;
      debugPrint('[MapScreen] Detections fout: $e');
      debugPrint('[MapScreen] Stack: $st');
      setState(() {
        _detections = null;
        _detectionsLoading = false;
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
      _loadVisitation();
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
    _detectionsDebounce?.cancel();
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

  Future<void> _loadVisitation() async {
    final labs = _livingLabs;
    if (labs == null || labs.isEmpty) {
      setState(() {
        _heatmapCells = null;
        _heatmapLoading = false;
      });
      return;
    }
    setState(() => _heatmapLoading = true);
    try {
      final cellSize = _heatmapCellSizeMeters ?? defaultVisitationCellSize;
      final cells = await fetchVisitationForLivingLabs(
        labs,
        cellSize: cellSize,
        maxCount: _heatmapRoodVanaf,
      );
      if (!mounted) return;
      setState(() {
        _heatmapCells = cells;
        _heatmapLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _heatmapCells = null;
        _heatmapLoading = false;
      });
    }
  }

  List<Widget> _heatmapLayers() {
    final cells = _heatmapCells;
    if (cells == null || cells.isEmpty) return [];

    final withCount = cells.where((c) => c.count > 0).toList();
    if (withCount.isEmpty) return [];

    final cellSize = _heatmapCellSizeMeters ?? defaultVisitationCellSize;
    final radiusMeters = heatmapCircleRadiusMeters(cellSize);

    final circles = withCount.map((c) {
      final intensity = c.intensity.clamp(0.0, 1.0);

      final color = Color.lerp(
        const Color(0xFF2E7D32),
        const Color(0xFFC62828),
        intensity,
      )!.withValues(alpha: 0.35 + 0.5 * intensity);

      return CircleMarker(
        point: LatLng(c.latitude, c.longitude),
        radius: radiusMeters,
        useRadiusInMeter: true,
        color: color,
        borderStrokeWidth: 0,
      );
    }).toList();

    return [CircleLayer(circles: circles)];
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

  List<Marker> _interactionMarkers() {
    final list = _interactions;
    if (list == null || list.isEmpty) return [];
    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return list.take(_maxVisibleMarkersCap).map((i) => _buildInteractionMarker(i)).toList();
    }
    final inBounds = list.where((i) => pointInBounds(i.location, bounds)).toList();
    final toShow = inBounds.length > _maxVisibleMarkersCap
        ? inBounds.take(_maxVisibleMarkersCap).toList()
        : inBounds;
    return toShow.map((i) => _buildInteractionMarker(i)).toList();
  }

  int _getVisibleMarkerCount() {
    final list = _interactions;
    if (list == null || list.isEmpty) return 0;
    try {
      final bounds = _mapController.camera.visibleBounds;
      final count = list.where((i) => pointInBounds(i.location, bounds)).length;
      return count > _maxVisibleMarkersCap ? _maxVisibleMarkersCap : count;
    } catch (_) {
      return list.length > _maxVisibleMarkersCap ? _maxVisibleMarkersCap : list.length;
    }
  }

  List<Marker> _detectionMarkers() {
    final list = _detections;
    if (list == null || list.isEmpty) return [];
    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return list.take(_maxVisibleMarkersCap).map((d) => _buildDetectionMarker(d)).toList();
    }
    final inBounds = list.where((d) => pointInBounds(d.location, bounds)).toList();
    final toShow = inBounds.length > _maxVisibleMarkersCap
        ? inBounds.take(_maxVisibleMarkersCap).toList()
        : inBounds;
    return toShow.map((d) => _buildDetectionMarker(d)).toList();
  }

  Marker _buildDetectionMarker(Detection d) {
    return Marker(
      point: d.location,
      width: 32,
      height: 32,
      child: GestureDetector(
        onTap: () => _showDetectionDetail(d),
        child: Material(
          color: d.type.color,
          shape: const CircleBorder(),
          elevation: 2,
          child: Center(
            child: Icon(iconForSpecies(d.species), color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  void _showDetectionDetail(Detection d) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  color: d.type.color,
                  shape: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(iconForSpecies(d.species), color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _detectionTypeLabel(d.type),
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (d.moment != null) ...[
              const SizedBox(height: 8),
              Text(
                formatMoment(d.moment!),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
            if (d.species != null && d.species!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(d.species!, style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
            ],
            const SizedBox(height: 8),
            Text(
              'Locatie: ${d.location.latitude.toStringAsFixed(5)}, ${d.location.longitude.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _detectionTypeLabel(DetectionType t) {
    switch (t) {
      case DetectionType.visual:
        return 'Visueel';
      case DetectionType.acoustic:
        return 'Acoustisch';
      case DetectionType.chemical:
        return 'Chemisch';
      case DetectionType.other:
        return 'Detectie';
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
        detectionTypeFilter: _detectionTypeFilter,
        momentAfter: _momentAfter,
        momentBefore: _momentBefore,
        heatmapRoodVanaf: _heatmapRoodVanaf,
        heatmapCellSizeMeters: _heatmapCellSizeMeters,
        onApply: (typeId, detectionType, after, before, {heatmapRoodVanaf, heatmapCellSizeMeters}) {
          setState(() {
            _interactionTypeFilter = typeId;
            _detectionTypeFilter = detectionType;
            _momentAfter = after;
            _momentBefore = before;
            _heatmapRoodVanaf = heatmapRoodVanaf;
            _heatmapCellSizeMeters = heatmapCellSizeMeters;
            _interactions = null;
            _detections = null;
          });
          _loadInteractions();
          _loadDetections();
          _loadVisitation();
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
    final maxZoomRaw = zoomForMaxKm(_minVisibleWidthM / 1000.0, initialCenter.latitude, screenWidth);
    final maxZoom = maxZoomRaw.clamp(14.0, 22.0);

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
                maxZoom: maxZoom,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              extraLayers: [
                if (_livingLabs != null) ..._livingLabPolygonLayers(),
                if (_livingLabs != null) ..._heatmapLayers(),
                MarkerLayer(markers: _detectionMarkers()),
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
            if (_interactionsLoading || _detectionsLoading || _heatmapLoading)
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
