/// Interface voor het ophalen van interactions: "mijn" lijst en gebiedsquery.
abstract class InteractionReadApiInterface {
  /// GET interactions/me/ – lijst van interactions van de ingelogde gebruiker.
  /// Retourneert ruwe JSON-objecten; de app kan die met eigen modellen parsen.
  Future<List<Map<String, dynamic>>> getMyInteractions();

  /// GET interactions/query/?area_latitude=...&area_longitude=...&area_radius=... (optioneel moment_after, moment_before).
  /// Retourneert ruwe JSON-objecten voor de app om te parsen (bijv. InteractionQueryResult.fromJson).
  Future<List<Map<String, dynamic>>> queryInteractions({
    required double areaLatitude,
    required double areaLongitude,
    required int areaRadiusMeters,
    DateTime? momentAfter,
    DateTime? momentBefore,
  });
}
