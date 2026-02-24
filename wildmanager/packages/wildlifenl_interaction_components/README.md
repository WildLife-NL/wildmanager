# wildlifenl_interaction_components

API voor het ophalen van interactions: "mijn interactions" (GET interactions/me/) en gebiedsquery (GET interactions/query/). Geschikt voor Wild Rapport, WildManager en andere apps die dezelfde backend gebruiken.

## Gebruik

### Dependency (Git of path)

```yaml
dependencies:
  wildlifenl_interaction_components:
    git:
      url: https://github.com/WildLife-NL/wildlifenl-components.git
      ref: Wildlife-rapport-Components
      path: wildlifenl_interaction_components
```

### Interface + standaardimplementatie

- **InteractionReadApiInterface** – `getMyInteractions()` en `queryInteractions(...)`.
- **HttpInteractionReadApi** – gebruikt `baseUrl` en Bearer token uit SharedPreferences (`bearer_token`).

De API retourneert **lijsten van `Map<String, dynamic>`** (ruwe JSON). De app parsed die met eigen modellen (bijv. `MyInteraction.fromJson(map)`, `InteractionQueryResult.fromJson(map)`).

### Voorbeeld

```dart
import 'package:wildlifenl_interaction_components/wildlifenl_interaction_components.dart';

final api = HttpInteractionReadApi(baseUrl: 'https://api.example.com');

// Mijn interactions
final list = await api.getMyInteractions();
final myInteractions = list.map((e) => MyInteraction.fromJson(e)).toList();

// Query op gebied
final queryList = await api.queryInteractions(
  areaLatitude: 52.0,
  areaLongitude: 5.0,
  areaRadiusMeters: 5000,
  momentAfter: DateTime.now().subtract(Duration(days: 30)),
);
final results = queryList.map((e) => InteractionQueryResult.fromJson(e)).toList();
```

Send interaction (POST interaction/) blijft app-specifiek (verschillende report-typen per app) en zit niet in deze package.
