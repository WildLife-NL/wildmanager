import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const double zoomScaleOffset = 0.65;
const int apiMaxRadiusMeters = 10000;
const double fetchPaddingFactor = 1.08;

double visibleWidthKmFromBounds(LatLngBounds bounds) {
  final centerLat = (bounds.north + bounds.south) / 2;
  final lonDeg = (bounds.east - bounds.west).abs();
  if (lonDeg <= 0) return 0;
  final latRad = centerLat * math.pi / 180;
  final kmPerDegreeLon = 111.32 * math.cos(latRad);
  return lonDeg * kmPerDegreeLon;
}

double visibleWidthKmFromZoom(
  num zoom,
  num latDeg,
  num screenWidthPx, {
  num zoomOffset = 0,
}) {
  const earthCircumferenceM = 40075017.0;
  const tileSize = 256.0;
  final z = zoom.toDouble() + zoomOffset.toDouble();
  final latRad = latDeg.toDouble() * math.pi / 180;
  final metersPerPx =
      (earthCircumferenceM * math.cos(latRad)) / (tileSize * math.pow(2, z));
  return (screenWidthPx.toDouble() * metersPerPx) / 1000.0;
}

double zoomForMaxKm(double maxKm, double latDeg, double screenWidthPx) {
  const earthCircumferenceM = 40075017.0;
  const tileSize = 256.0;
  final latRad = latDeg * math.pi / 180;
  final metersPerPx = maxKm * 1000 / screenWidthPx;
  final twoPowZoom =
      math.cos(latRad) * earthCircumferenceM / (tileSize * metersPerPx);
  return math.log(twoPowZoom) / math.ln2;
}

bool pointInBounds(LatLng point, LatLngBounds bounds) {
  if (point.latitude < bounds.south || point.latitude > bounds.north) return false;
  final w = bounds.west;
  final e = bounds.east;
  if (w <= e) {
    return point.longitude >= w && point.longitude <= e;
  }
  return point.longitude >= w || point.longitude <= e;
}

int computeRadiusMetersForBounds(LatLng center, LatLngBounds bounds) {
  final dist = const Distance();
  final corners = <LatLng>[
    LatLng(bounds.north, bounds.west),
    LatLng(bounds.north, bounds.east),
    LatLng(bounds.south, bounds.west),
    LatLng(bounds.south, bounds.east),
  ];
  double maxM = 0;
  for (final c in corners) {
    final m = dist.as(LengthUnit.Meter, center, c);
    if (m > maxM) maxM = m;
  }
  final padded = (maxM * fetchPaddingFactor).round();
  return padded.clamp(1, apiMaxRadiusMeters);
}

double metersPerLogicalPxWebMercator(
  double zoom,
  double latDeg, {
  double zoomOffset = 0,
}) {
  const earthCircumferenceM = 40075017.0;
  const tileSize = 256.0;
  final z = zoom + zoomOffset;
  final latRad = latDeg * math.pi / 180;
  return (earthCircumferenceM * math.cos(latRad)) / (tileSize * math.pow(2, z));
}
