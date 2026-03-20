import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart';

import '../models/detection.dart';
import '../models/interaction.dart';
import '../models/living_lab.dart';
import '../services/animals_service.dart';
import '../services/detections_service.dart';
import '../services/interactions_service.dart';
import '../services/living_labs_service.dart';
import '../services/visitation_service.dart';
import 'package:wildlifenl_animal_components/wildlifenl_animal_components.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';
import 'package:wildlifenl_visitation_components/wildlifenl_visitation_components.dart';
import '../state/filter_state.dart';
import '../state/map_filter_notifier.dart';
import '../utils/animal_icon_resolver.dart';
import 'map/filter_content.dart';
import 'map/filter_panel_controller.dart';
import 'map/interaction_theme.dart';
import 'map/map_legend.dart';
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
const double _filterPanelWidth = 400;

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

  List<Animal>? _animals;
  Map<String, List<LatLng>>? _animalTrails;
  bool _animalsLoading = false;
  int _animalRequestId = 0;
  Timer? _animalsDebounce;

  LatLng? _lastFetchedCenter;
  double? _lastFetchedVisibleKm;

  Timer? _interactionsDebounce;
  Timer? _interactionsPollTimer;
  Timer? _visibleKmDebounce;

  MapFilterNotifier? _filterNotifier;
  late final FilterPanelController _filterPanelController;
  late final ScrollController _panelScrollController;
  bool _showLegend = true;
  bool _initialTileRefreshScheduled = false;

  String _versionLabel = '';

  int _interactionRequestId = 0;

  static bool _interactionInDateRange(Interaction i, FilterState fs) {
    if (fs.momentAfter == null && fs.momentBefore == null) return true;
    final m = i.moment?.toLocal();
    if (m == null) return false;
    final afterStart = fs.momentAfter != null
        ? DateTime(fs.momentAfter!.year, fs.momentAfter!.month, fs.momentAfter!.day)
        : null;
    final beforeEnd = fs.momentBefore != null
        ? DateTime(fs.momentBefore!.year, fs.momentBefore!.month, fs.momentBefore!.day, 23, 59, 59, 999)
        : null;
    if (afterStart != null && m.isBefore(afterStart)) return false;
    if (beforeEnd != null && m.isAfter(beforeEnd)) return false;
    return true;
  }

  void _onFilterChanged() {
    if (!mounted || _filterNotifier == null) return;
    setState(() {
      _interactions = null;
      _detections = null;
      _animals = null;
      _animalTrails = null;
    });
    _loadInteractions();
    _loadDetections();
    _loadVisitation();
    if (_showAnimalsLayer) _scheduleLoadAnimals();
  }

  @override
  void initState() {
    super.initState();
    for (final key in getAllAnimalIconAssetKeys()) {
      rootBundle.load(key);
    }
    _filterNotifier = context.read<MapFilterNotifier>();
    _filterNotifier!.addListener(_onFilterChanged);
    _filterPanelController = FilterPanelController();
    _panelScrollController = ScrollController();
    _loadMapState().then((_) {
      _mapEventSub = _mapController.mapEventStream.listen((_) {
        _visibleKmDebounce?.cancel();
        _visibleKmDebounce = Timer(
          const Duration(milliseconds: _visibleKmDebounceMs),
          _updateVisibleKm,
        );
        _scheduleSaveMapState();
        _scheduleLoadInteractions();
        _scheduleLoadDetections();
        if (_showAnimalsLayer) _scheduleLoadAnimals();
      });

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateVisibleKm();
          _scheduleInitialTileRefresh();
          _loadInteractions();
          _scheduleLoadDetections();
          if (_showAnimalsLayer) _scheduleLoadAnimals();
        });

        _interactionsPollTimer = Timer.periodic(
          const Duration(milliseconds: 3000),
          (_) => _checkMapMovedAndReload(),
        );
      }
    });

    _loadLivingLabs();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      final build = info.buildNumber.isNotEmpty ? info.buildNumber : 'dev';
      final isDateVersion = build.length == 8 && int.tryParse(build) != null;
      setState(() => _versionLabel = isDateVersion ? 'v$build' : 'v${info.version} ($build)');
    });
  }

  void _scheduleInitialTileRefresh() {
    if (_initialTileRefreshScheduled) return;
    _initialTileRefreshScheduled = true;
    void doRefresh() {
      if (!mounted) return;
      try {
        final center = _mapController.camera.center;
        final zoom = _mapController.camera.zoom;
        _mapController.move(center, zoom);
        setState(() {});
      } catch (_) {}
    }
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => doRefresh());
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => doRefresh());
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => doRefresh());
    });
  }

  void _checkMapMovedAndReload() {
    if (!mounted || _interactionsLoading || _detectionsLoading || _animalsLoading) return;

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
      _scheduleLoadDetections();
      if (_showAnimalsLayer) _scheduleLoadAnimals();
      return;
    }

    final centerMoved = (center.latitude - _lastFetchedCenter!.latitude).abs() > 0.0015 ||
        (center.longitude - _lastFetchedCenter!.longitude).abs() > 0.0015;
    final zoomChanged = (visibleKm - _lastFetchedVisibleKm!).abs() > 1.2;

    if (centerMoved || zoomChanged) {
      _scheduleLoadInteractions();
      _scheduleLoadDetections();
      if (_showAnimalsLayer) _scheduleLoadAnimals();
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

  void _scheduleLoadAnimals() {
    _animalsDebounce?.cancel();
    _animalsDebounce = Timer(
      const Duration(milliseconds: _interactionsDebounceMs),
      _loadAnimals,
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
    final fs = _filterNotifier!.state;

    try {
      final before = fs.momentBefore != null
          ? DateTime(fs.momentBefore!.year, fs.momentBefore!.month, fs.momentBefore!.day, 23, 59, 59, 999)
          : null;
      final list = await fetchInteractions(
        center: requestedCenter,
        radiusMeters: radiusMeters,
        momentAfter: fs.momentAfter,
        momentBefore: before,
        interactionTypeId: null,
      );

      if (!mounted) return;
      if (requestId != _interactionRequestId) return;

      LatLngBounds nowBounds;
      try {
        nowBounds = _mapController.camera.visibleBounds;
      } catch (_) {
        return;
      }

      final listInRange = list
          .where((i) => _interactionInDateRange(i, fs) && fs.interactionTypeMatches(i.typeId))
          .toList();
      final merged = <String, Interaction>{};
      for (final i in _interactions ?? <Interaction>[]) {
        if (_interactionInDateRange(i, fs) && fs.interactionTypeMatches(i.typeId)) merged[i.id] = i;
      }
      for (final i in listInRange) {
        merged[i.id] = i;
      }
      final mergedList = merged.values.toList();

      setState(() {
        _interactions = mergedList;
        _interactionsLoading = false;
        _lastFetchedCenter = requestedCenter;
        _lastFetchedVisibleKm = visibleWidthKmFromBounds(nowBounds);
      });
      _scheduleLoadDetections();
      if (_showAnimalsLayer) _scheduleLoadAnimals();
    } catch (_) {
      if (!mounted) return;
      if (requestId != _interactionRequestId) return;
      setState(() {
        _interactions = null;
        _interactionsLoading = false;
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

    final fs = _filterNotifier!.state;
    var end = fs.momentBefore != null
        ? DateTime(fs.momentBefore!.year, fs.momentBefore!.month, fs.momentBefore!.day, 23, 59, 59, 999)
        : DateTime.now();
    var start = fs.momentAfter ?? end.subtract(const Duration(days: 30));
    if (start.isAfter(end)) start = end.subtract(const Duration(days: 1));

    setState(() => _detectionsLoading = true);
    debugPrint('[MapScreen] Detections laden: center=(${center.latitude}, ${center.longitude}) radius=${radiusMeters}m');

    try {
      final list = await fetchDetections(
        center: center,
        radiusMeters: radiusMeters,
        start: start,
        end: end,
        typeFilter: null,
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

  Future<void> _loadAnimals() async {
    _animalsDebounce?.cancel();
    _animalsDebounce = null;
    if (!mounted) return;

    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return;
    }

    final center = _mapController.camera.center;
    final radiusMeters = computeRadiusMetersForBounds(center, bounds);
    final requestId = ++_animalRequestId;

    final fs = _filterNotifier!.state;
    var end = fs.momentBefore != null
        ? DateTime(fs.momentBefore!.year, fs.momentBefore!.month, fs.momentBefore!.day, 23, 59, 59, 999)
        : DateTime.now();
    var start = fs.momentAfter ?? end.subtract(const Duration(days: 30));
    if (start.isAfter(end)) start = end.subtract(const Duration(days: 1));

    setState(() => _animalsLoading = true);

    try {
      final result = await fetchAnimalsInSpan(
        center: center,
        radiusMeters: radiusMeters,
        start: start,
        end: end,
      );

      if (!mounted) return;
      if (requestId != _animalRequestId) return;

      setState(() {
        _animals = result.animals;
        _animalTrails = result.trailsByAnimalId;
        _animalsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (requestId != _animalRequestId) return;
      setState(() {
        _animals = null;
        _animalTrails = null;
        _animalsLoading = false;
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
    _filterNotifier?.removeListener(_onFilterChanged);
    _panelScrollController.dispose();
    _saveMapStateDebounce?.cancel();
    _visibleKmDebounce?.cancel();
    _interactionsDebounce?.cancel();
    _detectionsDebounce?.cancel();
    _animalsDebounce?.cancel();
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
    final fs = _filterNotifier?.state ?? FilterState.defaults;
    var end = fs.momentBefore != null
        ? DateTime(fs.momentBefore!.year, fs.momentBefore!.month, fs.momentBefore!.day, 23, 59, 59, 999)
        : DateTime.now();
    var start = fs.momentAfter ?? end.subtract(const Duration(days: 30));
    if (start.isAfter(end)) start = end.subtract(const Duration(days: 1));
    try {
      final cellSize = fs.heatmapCellSizeMeters ?? defaultVisitationCellSize;
      final cells = await fetchVisitationForLivingLabs(
        labs,
        start: start,
        end: end,
        cellSize: cellSize,
        maxCount: fs.heatmapRoodVanaf,
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

    final fs = _filterNotifier?.state ?? FilterState.defaults;
    final cellSize = fs.heatmapCellSizeMeters ?? defaultVisitationCellSize;
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

  bool get _showAnimalsLayer {
    final fs = _filterNotifier?.state ?? FilterState.defaults;
    return fs.showAnimals;
  }

  List<Marker> _interactionMarkers() {
    final list = _interactions;
    if (list == null || list.isEmpty) return [];
    final fs = _filterNotifier?.state ?? FilterState.defaults;
    final filtered = list
        .where((i) => _interactionInDateRange(i, fs) && fs.interactionTypeMatches(i.typeId))
        .toList();
    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      final clusters = _clusteredInteractionMarkers(filtered);
      return clusters.take(_maxVisibleMarkersCap).toList();
    }
    final inBounds = filtered.where((i) => pointInBounds(i.location, bounds)).toList();
    final clusters = _clusteredInteractionMarkers(inBounds);
    return clusters.take(_maxVisibleMarkersCap).toList();
  }

  static String _interactionLocationKey(LatLng loc) {
    return '${loc.latitude.toStringAsFixed(6)}_${loc.longitude.toStringAsFixed(6)}';
  }

  List<Marker> _clusteredInteractionMarkers(List<Interaction> list) {
    final sightings = list.where(_isSighting).toList();
    final nonSightings = list.where((i) => !_isSighting(i)).toList();
    final grouped = <String, List<Interaction>>{};
    for (final i in sightings) {
      grouped.putIfAbsent(_interactionLocationKey(i.location), () => []).add(i);
    }
    final markers = <Marker>[];
    for (final g in grouped.values) {
      if (g.length == 1) {
        markers.add(_buildInteractionMarker(g.single));
      } else {
        markers.add(_buildInteractionClusterMarker(g));
      }
    }
    markers.addAll(nonSightings.map(_buildInteractionMarker));
    return markers;
  }

  bool _detectionInDateRange(Detection d, FilterState fs) {
    if (fs.momentAfter == null && fs.momentBefore == null) return true;
    final m = d.moment?.toLocal();
    if (m == null) return false;
    final afterStart = fs.momentAfter != null
        ? DateTime(fs.momentAfter!.year, fs.momentAfter!.month, fs.momentAfter!.day)
        : null;
    final beforeEnd = fs.momentBefore != null
        ? DateTime(fs.momentBefore!.year, fs.momentBefore!.month, fs.momentBefore!.day, 23, 59, 59, 999)
        : null;
    if (afterStart != null && m.isBefore(afterStart)) return false;
    if (beforeEnd != null && m.isAfter(beforeEnd)) return false;
    return true;
  }

  static String _detectionLocationKey(LatLng loc) {
    return '${loc.latitude.toStringAsFixed(6)}_${loc.longitude.toStringAsFixed(6)}';
  }

  List<Marker> _detectionMarkers() {
    final list = _detections;
    if (list == null || list.isEmpty) return [];
    final fs = _filterNotifier?.state ?? FilterState.defaults;
    final filtered = list
        .where((d) => fs.detectionTypeMatches(d.type) && _detectionInDateRange(d, fs))
        .toList();
    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      final groups = _groupDetectionsByLocation(filtered);
      return groups.take(_maxVisibleMarkersCap).map((g) => g.length == 1
          ? _buildDetectionMarker(g.single)
          : _buildDetectionClusterMarker(g)).toList();
    }
    final inBounds = filtered.where((d) => pointInBounds(d.location, bounds)).toList();
    final groups = _groupDetectionsByLocation(inBounds);
    final toShow = groups.take(_maxVisibleMarkersCap).toList();
    return toShow.map((g) => g.length == 1
        ? _buildDetectionMarker(g.single)
        : _buildDetectionClusterMarker(g)).toList();
  }

  List<List<Detection>> _groupDetectionsByLocation(List<Detection> list) {
    final map = <String, List<Detection>>{};
    for (final d in list) {
      map.putIfAbsent(_detectionLocationKey(d.location), () => []).add(d);
    }
    return map.values.toList();
  }

  List<Marker> _animalMarkers() {
    final list = _animals;
    if (list == null || list.isEmpty) return [];
    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return list.take(_maxVisibleMarkersCap).map((a) => _buildAnimalMarker(a)).toList();
    }
    final inBounds = list.whereType<Animal>().where((a) => pointInBounds(a.location, bounds)).toList();
    final toShow = inBounds.length > _maxVisibleMarkersCap
        ? inBounds.take(_maxVisibleMarkersCap).toList()
        : inBounds;
    return toShow.map((a) => _buildAnimalMarker(a)).toList();
  }

  List<Polyline> _animalTrailPolylines() {
    final trails = _animalTrails;
    if (trails == null || trails.isEmpty) return [];
    final polylines = <Polyline>[];
    const minAlpha = 0.06;
    const maxAlpha = 0.9;
    for (final entry in trails.entries) {
      final points = entry.value;
      if (points.length < 2) continue;
      final n = points.length;
      for (int i = 0; i < n - 1; i++) {
        final t = (n > 2) ? (i + 1) / (n - 1) : 1.0;
        final alpha = minAlpha + (maxAlpha - minAlpha) * t;
        polylines.add(Polyline(
          points: [points[i], points[i + 1]],
          color: mapColorAnimalTrail.withValues(alpha: alpha),
          strokeWidth: 1.5,
        ));
      }
    }
    return polylines;
  }

  Widget _animalIconWidget(String? speciesCommonName, double size) {
    final iconName = resolveSpeciesToIconName(speciesCommonName) ?? speciesCommonName;
    final path = iconName != null && iconName.isNotEmpty ? getAnimalIconAssetPath(iconName) : null;
    if (path != null) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.pets, color: Colors.white, size: size),
      );
    }
    return Icon(Icons.pets, color: Colors.white, size: size);
  }

  String _animalTitleWithLatin(String commonName, String? latinName) {
    if (latinName != null && latinName.trim().isNotEmpty) {
      return '$commonName (${latinName.trim()})';
    }
    return commonName;
  }

  Marker _buildAnimalMarker(Animal a) {
    return Marker(
      point: a.location,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showAnimalDetail(a),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mapColorAnimal,
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Center(
            child: _animalMarkerIconWidget(a.displaySpecies, 22, iconColor: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _animalMarkerIconWidget(String? speciesCommonName, double size, {Color? iconColor}) {
    final iconName = resolveSpeciesToIconName(speciesCommonName) ?? speciesCommonName;
    final path = iconName != null && iconName.isNotEmpty ? getAnimalIconAssetPath(iconName) : null;
    final color = iconColor ?? mapColorAnimal;
    if (path != null) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (_, __, ___) => Icon(Icons.pets, color: color, size: size),
      );
    }
    return Icon(Icons.pets, color: color, size: size);
  }

  Widget _speciesDisplayWidget(BuildContext ctx, String? common, String? latin, {TextStyle? textStyle}) {
    final c = common?.trim();
    final l = latin?.trim();
    final style = textStyle ?? TextStyle(fontSize: 14, color: Colors.grey.shade800);
    if (c != null && c.isNotEmpty) {
      if (l != null && l.isNotEmpty) {
        return Text.rich(
          TextSpan(
            style: style,
            children: [
              TextSpan(text: c),
              TextSpan(text: ' ($l)', style: style.copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
        );
      }
      return Text(c, style: style);
    }
    if (l != null && l.isNotEmpty) {
      return Text(l, style: style.copyWith(fontStyle: FontStyle.italic));
    }
    return Text('—', style: style);
  }

  String _animalLocationDisplay(LatLng location, DateTime? locationTimestamp) {
    final coords = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(5)}';
    if (locationTimestamp != null) return '$coords (${formatMoment(locationTimestamp)})';
    return coords;
  }

  String _locationWithTimestamp(LatLng location, DateTime? moment) {
    final coords = '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
    if (moment != null) return '$coords (${formatMoment(moment)})';
    return coords;
  }

  static final RegExp _uuidLike = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  bool _reporterNameIsReal(String? reporterName) {
    if (reporterName == null || reporterName.trim().isEmpty) return false;
    final t = reporterName.trim();
    if (RegExp(r'^\d+$').hasMatch(t)) return false; // numeric ID
    if (_uuidLike.hasMatch(t)) return false; // UUID
    return true;
  }

  void _showAnimalDetail(Animal a) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: mapColorAnimal,
                    shape: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _animalIconWidget(a.displaySpecies, 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _animalTitleWithLatin(a.speciesCommonName ?? a.displaySpecies ?? 'Dier', a.speciesLatinName),
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.name,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(
                ctx,
                Icons.science,
                'Species',
                a.speciesCategory?.trim().isNotEmpty == true
                    ? a.speciesCategory!
                    : (a.speciesCommonName ?? a.displaySpecies ?? '—'),
              ),
              _detailRow(
                ctx,
                Icons.location_on,
                'Locatie',
                _animalLocationDisplay(a.location, a.locationTimestamp),
              ),
              const SizedBox(height: 12),
              _detailRow(ctx, Icons.tag, 'ID', a.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detectionIcon(String? species, {required double size}) {
    final iconName = resolveSpeciesToIconName(species) ?? species;
    final path = iconName != null && iconName.isNotEmpty ? getAnimalIconAssetPath(iconName) : null;
    if (path != null) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          if (kDebugMode) debugPrint('[Detection icoon] Laden mislukt: $path (soort: $species)');
          return Icon(Icons.pets, color: Colors.white, size: size);
        },
      );
    }
    return Icon(Icons.pets, color: Colors.white, size: size);
  }

  static final _detectionMarkerShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));

  Marker _buildDetectionMarker(Detection d) {
    return Marker(
      point: d.location,
      width: 32,
      height: 32,
      child: GestureDetector(
        onTap: () => _showDetectionAnimalPicker(d),
        child: Material(
          color: colorForDetectionType(d.type),
          shape: _detectionMarkerShape,
          elevation: 2,
          child: Center(
            child: _detectionIcon(d.species, size: 18),
          ),
        ),
      ),
    );
  }

  Marker _buildDetectionClusterMarker(List<Detection> list) {
    final d = list.first;
    final count = list.length;
    return Marker(
      point: d.location,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showDetectionClusterDetail(list),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: colorForDetectionType(d.type),
              shape: _detectionMarkerShape,
              elevation: 2,
              child: Center(
                child: _detectionIcon(d.species, size: 20),
              ),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetectionClusterDetail(List<Detection> list) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                '${list.length} detecties op deze locatie',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...list.map((d) => ListTile(
                leading: Material(
                  color: colorForDetectionType(d.type),
                  shape: _detectionMarkerShape,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _detectionIcon(d.species, size: 20),
                  ),
                ),
                title: Text(
                  _detectionSpeciesTitle(d),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _detectionClusterSubtitle(d),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorForDetectionType(d.type),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_displayedAnimalCount(d)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDetectionAnimalPicker(d);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  int _displayedAnimalCount(Detection d) {
    return d.animalCount ?? d.animals.length;
  }

  String _detectionClusterSubtitle(Detection d) {
    final typeStr = _detectionTypeLabel(d.type);
    final timeStr = d.moment != null ? formatMoment(d.moment!) : null;
    return [typeStr, if (timeStr != null) timeStr].join(' · ');
  }

  String _detectionSpeciesTitle(Detection d) {
    final seen = <String>{};
    final unique = d.animals
        .map((a) => a.species ?? a.speciesCategory ?? '')
        .where((s) => s.trim().isNotEmpty)
        .where((s) => seen.add(s))
        .toList();
    if (unique.isNotEmpty) return unique.join(', ');
    return d.species?.trim().isNotEmpty == true
        ? d.species!
        : d.speciesCategory?.trim().isNotEmpty == true
            ? d.speciesCategory!
            : 'Detectie';
  }

  void _showDetectionAnimalPicker(Detection d) {
    final count = _displayedAnimalCount(d);
    final list = <DetectionAnimal>[];
    for (var i = 0; i < d.animals.length; i++) list.add(d.animals[i]);
    while (list.length < count) list.add(const DetectionAnimal());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(ctx).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Material(
                    color: colorForDetectionType(d.type),
                    shape: _detectionMarkerShape,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _detectionIcon(d.species, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _speciesDisplayWidget(
                          ctx,
                          _detectionSpeciesTitle(d),
                          d.speciesCategory?.trim().isNotEmpty == true
                              ? d.speciesCategory
                              : d.animals.isNotEmpty
                                  ? (d.animals.first.speciesCategory?.trim().isNotEmpty == true
                                      ? d.animals.first.speciesCategory
                                      : null)
                                  : null,
                          textStyle: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                        ),
                        if (d.moment != null)
                          Text(
                            '${_detectionTypeLabel(d.type)} · ${formatMoment(d.moment!)}',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Groepssamenstelling',
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              ...List.generate(list.length, (i) {
                final a = list[i];
                final compactLine = _detectionAnimalCompactLine(a);
                final hasBehaviour = a.behaviour != null && a.behaviour!.trim().isNotEmpty;
                final hasDescription = a.description != null && a.description!.trim().isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _showDetectionAnimalDetail(d, a),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (compactLine.isNotEmpty)
                              Text(
                                compactLine,
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                              )
                            else if (!hasBehaviour && !hasDescription)
                              Text(
                                '—',
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                              ),
                            if (hasBehaviour) ...[
                              if (compactLine.isNotEmpty) const SizedBox(height: 6),
                              Text(
                                a.behaviour!,
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (hasDescription) ...[
                              if (compactLine.isNotEmpty || hasBehaviour) const SizedBox(height: 6),
                              Text(
                                a.description!,
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetectionAnimalDetail(Detection d, DetectionAnimal a) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(ctx).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Material(
                    color: colorForDetectionType(d.type),
                    shape: _detectionMarkerShape,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _detectionIcon(a.species ?? d.species, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _speciesDisplayWidget(ctx, a.species ?? d.species, a.speciesCategory ?? d.speciesCategory),
                        const SizedBox(height: 4),
                        Text(
                          _detectionTypeLabel(d.type),
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (a.sex != null && a.sex!.trim().isNotEmpty)
                _detailRow(ctx, Icons.wc, 'Geslacht', _detectionSexLabel(a.sex!)),
              if (a.condition != null && a.condition!.trim().isNotEmpty)
                _detailRow(ctx, Icons.favorite, 'Conditie', _detectionConditionLabel(a.condition!)),
              if (a.lifeStage != null && a.lifeStage!.trim().isNotEmpty)
                _detailRow(ctx, Icons.cake, 'Levensfase', _detectionLifeStageLabel(a.lifeStage!)),
              if (a.behaviour != null && a.behaviour!.trim().isNotEmpty)
                _detailRow(ctx, Icons.pets, 'Gedrag', a.behaviour!),
              if (a.confidence != null)
                _detailRow(ctx, Icons.percent, 'Detectiezekerheid', '${a.confidence}%'),
              if (a.description != null && a.description!.trim().isNotEmpty)
                _detailRow(ctx, Icons.description, 'Beschrijving', a.description!),
              const SizedBox(height: 16),
              if (d.moment != null)
                _detailRow(ctx, Icons.schedule, 'Tijdstip detectie', formatMoment(d.moment!)),
              _detailRow(ctx, Icons.tag, 'ID', d.id),
              _detailRow(
                ctx,
                Icons.location_on,
                'Locatie',
                '${d.location.latitude.toStringAsFixed(5)}, ${d.location.longitude.toStringAsFixed(5)}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _detectionAnimalCompactLine(DetectionAnimal a) {
    final parts = <String>[];
    if (a.sex != null && a.sex!.trim().isNotEmpty) parts.add(_detectionSexLabel(a.sex!));
    if (a.lifeStage != null && a.lifeStage!.trim().isNotEmpty) parts.add(_detectionLifeStageLabel(a.lifeStage!));
    if (a.condition != null && a.condition!.trim().isNotEmpty) parts.add(_detectionConditionLabel(a.condition!));
    if (a.confidence != null) parts.add('${a.confidence}% detectiezekerheid');
    return parts.join(' · ');
  }

  String _detectionTypeLabel(DetectionType t) {
    switch (t) {
      case DetectionType.visual:
        return 'Visueel';
      case DetectionType.acoustic:
        return 'Akoestisch';
      case DetectionType.chemical:
        return 'Chemisch';
      case DetectionType.other:
        return 'Detectie';
    }
  }

  String _detectionSexLabel(String value) {
    switch (value.toLowerCase()) {
      case 'female':
        return 'Vrouwelijk';
      case 'male':
        return 'Mannelijk';
      default:
        return value;
    }
  }

  String _detectionConditionLabel(String value) {
    switch (value.toLowerCase()) {
      case 'healthy':
        return 'Gezond';
      case 'impaired':
        return 'Gewond';
      case 'dead':
        return 'Dood';
      default:
        return value;
    }
  }

  String _detectionLifeStageLabel(String value) {
    switch (value.toLowerCase()) {
      case 'infant':
        return 'Jong';
      case 'adolescent':
        return 'Adolescent';
      case 'adult':
        return 'Volwassen';
      default:
        return value;
    }
  }

  bool _isSighting(Interaction i) {
    return i.typeId == interactionTypeSighting ||
        i.typeName.toLowerCase().contains('waarneming') ||
        i.typeName.toLowerCase().contains('sighting');
  }

  Widget _interactionIcon(Interaction i, {required double size}) {
    final useAnimalIcon = _isSighting(i) || i.typeId == interactionTypeCollision;
    if (useAnimalIcon) {
      final name = i.speciesCommonName?.trim();
      if (name != null && name.isNotEmpty) {
        final iconName = resolveSpeciesToIconName(name) ?? name;
        final path = getAnimalIconAssetPath(iconName);
        if (path != null) {
          return Image.asset(
            path,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              if (kDebugMode) debugPrint('[Interaction icoon] Laden mislukt: $path (soort: $name)');
              return Icon(iconForInteractionType(i.typeId), color: Colors.white, size: size);
            },
          );
        }
      }
    }
    return Icon(iconForInteractionType(i.typeId), color: Colors.white, size: size);
  }

  Marker _buildInteractionMarker(Interaction i) {
    final color = colorForInteractionType(i.typeId);
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
            child: _interactionIcon(i, size: 20),
          ),
        ),
      ),
    );
  }

  int _interactionAnimalCount(Interaction i) {
    final detailed = i.involvedAnimals?.length ?? 0;
    if (detailed > 0) return detailed;
    final named = i.involvedAnimalNames?.length ?? 0;
    if (named > 0) return named;
    return 1;
  }

  Marker _buildInteractionClusterMarker(List<Interaction> list) {
    final i = list.first;
    final color = colorForInteractionType(i.typeId);
    final totalAnimals = list.fold<int>(0, (sum, x) => sum + _interactionAnimalCount(x));
    return Marker(
      point: i.location,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => _showInteractionClusterDetail(list),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: color,
              shape: const CircleBorder(),
              elevation: 2,
              child: Center(
                child: _interactionIcon(i, size: 22),
              ),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  totalAnimals > 99 ? '99+' : '$totalAnimals',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInteractionClusterDetail(List<Interaction> list) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                '${list.length} waarnemingen op deze locatie',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...list.map((i) => ListTile(
                    leading: Material(
                      color: colorForInteractionType(i.typeId),
                      shape: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _interactionIcon(i, size: 20),
                      ),
                    ),
                    title: Text(
                      i.speciesCommonName?.trim().isNotEmpty == true ? i.speciesCommonName! : 'Waarneming',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      i.moment != null ? formatMoment(i.moment!) : typeNameShortForInteraction(i),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorForInteractionType(i.typeId),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${_interactionAnimalCount(i)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showInteractionDetail(i);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  static String _interactionIntensityOrUrgencyLabel(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return 'Hoog';
      case 'medium':
        return 'Gemiddeld';
      case 'low':
        return 'Laag';
      default:
        return value;
    }
  }

  static String _interactionImpactTypeLabel(String value) {
    switch (value.toLowerCase()) {
      case 'square-meters':
        return 'm²';
      case 'units':
        return 'stuks';
      default:
        return value;
    }
  }

  void _showInteractionDetail(Interaction interaction) {
    final typeColor = colorForInteractionType(interaction.typeId);
    final hasSpecies = interaction.speciesCommonName?.trim().isNotEmpty == true ||
        interaction.speciesCategory?.trim().isNotEmpty == true;
    final isSighting = interaction.typeId == interactionTypeSighting;
    final isDamage = interaction.typeId == interactionTypeDamage;
    final isCollision = interaction.typeId == interactionTypeCollision;
    final rawAnimals = interaction.involvedAnimals ?? interaction.involvedAnimalNames
        ?.map((name) => InvolvedAnimal(displayName: name)).toList();
    final listAnimals = rawAnimals
        ?.where((a) =>
            (a.speciesCommonName != null && a.speciesCommonName!.trim().isNotEmpty) ||
            (a.speciesLatinName != null && a.speciesLatinName!.trim().isNotEmpty) ||
            (a.displayName != null && a.displayName!.trim().isNotEmpty) ||
            (a.sex != null && a.sex!.trim().isNotEmpty) ||
            (a.lifeStage != null && a.lifeStage!.trim().isNotEmpty) ||
            (a.behaviour != null && a.behaviour!.trim().isNotEmpty) ||
            (a.description != null && a.description!.trim().isNotEmpty))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(ctx).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Material(
                    color: typeColor,
                    shape: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _interactionIcon(interaction, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasSpecies)
                          _speciesDisplayWidget(
                            ctx,
                            interaction.speciesCommonName?.trim().isNotEmpty == true
                                ? interaction.speciesCommonName
                                : (interaction.speciesCategory?.trim().isEmpty ?? true ? 'Onbekend' : null),
                            interaction.speciesLatinName?.trim().isNotEmpty == true
                                ? interaction.speciesLatinName
                                : (interaction.speciesCategory?.trim().isNotEmpty == true ? interaction.speciesCategory : null),
                            textStyle: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                          )
                        else
                          Text(
                            typeNameShortForInteraction(interaction),
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                          ),
                        Text(
                          hasSpecies
                              ? [
                                  typeNameShortForInteraction(interaction),
                                  if (interaction.moment != null) formatMoment(interaction.moment!),
                                ].join(' · ')
                              : (interaction.moment != null ? formatMoment(interaction.moment!) : ''),
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (isSighting) ...[
                if (interaction.momentReported != null)
                  _detailRow(ctx, Icons.schedule, 'Gemeld op', _locationWithTimestamp(interaction.location, interaction.momentReported)),
                if (interaction.moment != null)
                  _detailRow(ctx, Icons.event, 'Gebeurd op', _locationWithTimestamp(interaction.location, interaction.moment)),
                if (_reporterNameIsReal(interaction.reporterName))
                  _detailRow(ctx, Icons.person, 'Gemeld door', interaction.reporterName!),
                if (interaction.description != null && interaction.description!.trim().isNotEmpty)
                  _detailRow(ctx, Icons.description, 'Beschrijving', interaction.description!),
                if (interaction.typeDescription != null && interaction.typeDescription!.trim().isNotEmpty)
                  _detailRow(ctx, Icons.info_outline, 'Type', interaction.typeDescription!),
                if (interaction.speciesBehaviour != null && interaction.speciesBehaviour!.trim().isNotEmpty)
                  _detailRow(ctx, Icons.pets, 'Gedrag', interaction.speciesBehaviour!),
                if (interaction.speciesDescription != null && interaction.speciesDescription!.trim().isNotEmpty)
                  _detailRow(ctx, Icons.info_outline, 'Beschrijving soort', interaction.speciesDescription!),
                if (interaction.speciesAdvice != null && interaction.speciesAdvice!.trim().isNotEmpty)
                  _detailRow(ctx, Icons.lightbulb_outline, 'Advies', interaction.speciesAdvice!),
                if (interaction.speciesRoleInNature != null && interaction.speciesRoleInNature!.trim().isNotEmpty)
                  _detailRow(ctx, Icons.eco, 'Rol in de natuur', interaction.speciesRoleInNature!),
                const SizedBox(height: 8),
              ],

              if (rawAnimals != null && rawAnimals.isNotEmpty) ...[
                Text(
                  'Betrokken dieren',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                if (listAnimals != null && listAnimals.isNotEmpty)
                  ...listAnimals.map((a) {
                  final hasSpeciesLine = (a.speciesCommonName != null && a.speciesCommonName!.trim().isNotEmpty) ||
                      (a.speciesLatinName != null && a.speciesLatinName!.trim().isNotEmpty);
                  final showName = a.displayName != null && a.displayName!.trim().isNotEmpty &&
                      (!hasSpeciesLine || a.displayName != a.speciesCommonName);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasSpeciesLine)
                              _speciesDisplayWidget(
                                ctx,
                                a.speciesCommonName ?? (a.displayName?.trim().isEmpty ?? true ? null : a.displayName),
                                a.speciesLatinName,
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              )
                            else if (showName)
                              Text(
                                a.displayName!,
                                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            if (a.sex != null && a.sex!.trim().isNotEmpty) ...[
                              if (hasSpeciesLine || showName) const SizedBox(height: 4),
                              Text(
                                'Geslacht: ${_detectionSexLabel(a.sex!)}',
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                              ),
                            ],
                            if (a.lifeStage != null && a.lifeStage!.trim().isNotEmpty) ...[
                              if (hasSpeciesLine || showName || (a.sex != null && a.sex!.trim().isNotEmpty)) const SizedBox(height: 4),
                              Text(
                                'Levensfase: ${_detectionLifeStageLabel(a.lifeStage!)}',
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                              ),
                            ],
                            if (a.behaviour != null && a.behaviour!.trim().isNotEmpty) ...[
                              if (hasSpeciesLine || showName) const SizedBox(height: 6),
                              Text(
                                a.behaviour!,
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (a.description != null && a.description!.trim().isNotEmpty) ...[
                              if (hasSpeciesLine || showName || (a.behaviour != null && a.behaviour!.trim().isNotEmpty))
                                const SizedBox(height: 6),
                              Text(
                                a.description!,
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                })
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Geen diergegevens beschikbaar.',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 12),
              ],

              if (isDamage && (interaction.damageBelonging != null || interaction.damageEstimatedDamage != null ||
                  interaction.damageEstimatedLoss != null || interaction.damageImpactType != null)) ...[
                Text(
                  'Schade',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    [
                      if (interaction.damageBelonging != null && interaction.damageBelonging!.trim().isNotEmpty)
                        interaction.damageBelonging,
                      if (interaction.damageEstimatedDamage != null) '€${interaction.damageEstimatedDamage} geschat',
                      if (interaction.damageEstimatedLoss != null) '€${interaction.damageEstimatedLoss} verlies',
                      if (interaction.damageImpactType != null && interaction.damageImpactValue != null)
                        '${interaction.damageImpactValue} ${_interactionImpactTypeLabel(interaction.damageImpactType!)}',
                    ].join(' · '),
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
              ],

              if (isCollision && (interaction.collisionEstimatedDamage != null ||
                  interaction.collisionIntensity != null || interaction.collisionUrgency != null)) ...[
                Text(
                  'Aanrijding',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    [
                      if (interaction.collisionEstimatedDamage != null)
                        '€${interaction.collisionEstimatedDamage} geschat',
                      if (interaction.collisionIntensity != null && interaction.collisionIntensity!.trim().isNotEmpty)
                        _interactionIntensityOrUrgencyLabel(interaction.collisionIntensity!),
                      if (interaction.collisionUrgency != null && interaction.collisionUrgency!.trim().isNotEmpty)
                        _interactionIntensityOrUrgencyLabel(interaction.collisionUrgency!),
                    ].join(' · '),
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
              ],

              if (!isSighting && interaction.description != null && interaction.description!.trim().isNotEmpty) ...[
                Text(
                  'Beschrijving',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    interaction.description!,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              if (!isSighting) ...[
                if (_reporterNameIsReal(interaction.reporterName))
                  _detailRow(ctx, Icons.person, 'Gemeld door', interaction.reporterName!),
                if (interaction.momentReported != null)
                  _detailRow(ctx, Icons.schedule, 'Gemeld op', _locationWithTimestamp(interaction.location, interaction.momentReported)),
                if (interaction.moment != null)
                  _detailRow(ctx, Icons.event, 'Gebeurd op', _locationWithTimestamp(interaction.location, interaction.moment)),
              ],
            ],
          ),
        ),
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
    final maxZoom = maxZoomRaw.clamp(14.0, 17.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Consumer<MapFilterNotifier>(
              builder: (context, notifier, _) {
                final showAnimals = notifier.state.showAnimals;
                return WildLifeNLMap(
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
                    if (notifier.state.showLivingLab)
                      if (_livingLabs != null) ..._livingLabPolygonLayers(),
                    if (notifier.state.showHeatmap)
                      if (_livingLabs != null) ..._heatmapLayers(),
                    // Animals (and trails) drawn first so detection and interaction icons appear on top
                    if (showAnimals) ...[
                      if (notifier.state.showAnimalPath && _animalTrailPolylines().isNotEmpty)
                        PolylineLayer(polylines: _animalTrailPolylines()),
                      MarkerLayer(markers: _animalMarkers()),
                    ],
                    MarkerLayer(markers: _interactionMarkers()),
                    MarkerLayer(markers: _detectionMarkers()),
                  ],
                );
              },
            ),
            ListenableBuilder(
              listenable: _filterPanelController,
              builder: (_, __) {
                if (!_filterPanelController.isOpen) return const SizedBox.shrink();
                return Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  right: _filterPanelWidth,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _filterPanelController.closePanel(),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _versionLabel.isEmpty
                  ? const SizedBox.shrink()
                  : Material(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          _versionLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _showLegend ? const MapLegend() : const SizedBox.shrink(),
            ),
            Positioned(
              left: 16,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaleBarIndicator(mapController: _mapController),
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
                  Consumer<MapFilterNotifier>(
                    builder: (context, notifier, _) {
                      final count = notifier.state.activeFilterCount;
                      final tooltip = count > 0
                          ? 'Filters ($count actief)'
                          : 'Filters (alles aan)';
                      return Badge(
                        isLabelVisible: count > 0,
                        label: Text('$count'),
                        child: IconButton.filled(
                          onPressed: () => _filterPanelController.toggle(),
                          icon: const Icon(Icons.filter_list),
                          tooltip: tooltip,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  IconButton.filled(
                    onPressed: () => setState(() => _showLegend = !_showLegend),
                    icon: Icon(_showLegend ? Icons.legend_toggle : Icons.info_outline),
                    tooltip: _showLegend ? 'Legenda verbergen' : 'Legenda',
                  ),
                  const SizedBox(height: 8),
                  NorthUpButton(mapController: _mapController),
                ],
              ),
            ),
            if (_interactionsLoading || _detectionsLoading || _animalsLoading || _heatmapLoading)
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
            _buildFilterSidePanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSidePanel() {
    return ListenableBuilder(
      listenable: _filterPanelController,
      builder: (_, __) {
        final open = _filterPanelController.isOpen;
        return TweenAnimationBuilder<double>(
          key: ValueKey(open),
          duration: open
              ? const Duration(milliseconds: 200)
              : Duration.zero,
          curve: Curves.easeInOut,
          tween: Tween(begin: open ? 0 : 0, end: open ? 1 : 0),
          builder: (context, value, child) {
            return Positioned(
              right: -(1 - value) * _filterPanelWidth,
              top: 0,
              bottom: 0,
              width: _filterPanelWidth,
              child: child!,
            );
          },
          child: Material(
            elevation: 8,
            color: Theme.of(context).colorScheme.surface,
            child: Consumer<MapFilterNotifier>(
              builder: (context, notifier, _) {
                return FilterContent(
                  scrollController: _panelScrollController,
                  initialDraft: notifier.state,
                  onApply: (draft) {
                    notifier.apply(draft);
                    _filterPanelController.closePanel();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
