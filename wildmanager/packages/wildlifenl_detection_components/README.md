# wildlifenl_detection_components

API voor **Get Detections By Filter**: GET `/detection/` – detections binnen een spatiotemporele span. Geschikt voor Wild Rapport, WildManager en andere apps die dezelfde backend gebruiken.

**Scopes:** nature-area-manager, wildlife-manager, herd-manager.

## Dependency

```yaml
dependencies:
  wildlifenl_detection_components:
    path: ../wildlifenl-components/wildlifenl_detection_components
```

## Gebruik

- **DetectionReadApiInterface** – `getDetectionsByFilter(start, end, latitude, longitude, radius)`.
- **HttpDetectionReadApi** – gebruikt `baseUrl` en Bearer token uit SharedPreferences (`bearer_token`).

De API retourneert **lijsten van `Map<String, dynamic>`** (ruwe JSON). De app parsed die met eigen modellen (bijv. `Detection.fromJson(map)`).

### Voorbeeld

```dart
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

final api = HttpDetectionReadApi(baseUrl: 'https://api.example.com');

final list = await api.getDetectionsByFilter(
  start: DateTime(2025, 1, 1),
  end: DateTime(2025, 1, 31),
  latitude: 52.09,
  longitude: 5.12,
  radius: 5000,
);
final detections = list.map((e) => Detection.fromJson(e)).toList();
```

### Query parameters (API)

| Parameter  | Type   | Vereist | Beschrijving |
|-----------|--------|---------|--------------|
| start     | date-time | ja   | Startmoment van de span |
| end       | date-time | ja   | Eindmoment van de span |
| latitude  | double | ja   | Breedtegraad van het centrum (-90 t/m 90) |
| longitude | double | ja   | Lengtegraad van het centrum (-180 t/m 180) |
| radius    | int    | ja   | Straal in meters (1 t/m 10000) |

Authorization: Bearer token in de `Authorization` header.

## Detections op de kaart (pins)

Pins kunnen per **type** een kleur krijgen en per **soort** een icoon in de pin.

- **DetectionType** – `visual`, `acoustic`, `chemical`, `other` met kleur (rood, oranje, groen, grijs).
- **getPinStyleForDetection(detection)** – geeft `DetectionPinStyle` (color + icon) op basis van `detection['type']` en `detection['species']` (of `animal_species`).
- **defaultSpeciesIcons** – map soort → IconData; **iconForSpecies(species)** voor fallback.
- **detectionLatitude(d)** / **detectionLongitude(d)** – haal coördinaten uit een detection-map (keys: `latitude`/`longitude` of `lat`/`lng`).

Filters (client-side):

- **filterDetectionsByType(detections, type)** – filter op type.
- **filterDetectionsByTimePeriod(detections, start:, end:)** – filter op tijd (key `moment` of custom).
- **detectionHasLocation(d)** – of de detection coördinaten heeft.

Voorbeeld: markers op de kaart (in de app, met flutter_map):

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

final detections = await api.getDetectionsByFilter(...);
final withLocation = detections.where(detectionHasLocation).toList();
final filtered = filterDetectionsByType(withLocation, DetectionType.visual);

final markers = filtered.map((d) {
  final style = getPinStyleForDetection(d);
  final lat = detectionLatitude(d)!;
  final lng = detectionLongitude(d)!;
  return Marker(
    point: LatLng(lat, lng),
    child: Icon(Icons.place, color: style.color, size: 32),
    // of custom pin met style.icon erin
  );
}).toList();

// In FlutterMap children:
MarkerLayer(markers: markers)
```

Area/zoom: gebruik voor de API `latitude`, `longitude` en `radius` op basis van het kaartcentrum en zoomniveau (bijv. grotere radius bij lager zoom).
