/// Lijst van diericonen in de asset folder (bestandsnaam zonder .png).
/// Gebruik [resolveSpeciesToIconName] om een API-soortnaam te koppelen aan een icoon.
const List<String> knownAnimalIconNames = [
  'bever',
  'boommarter',
  'bunzing',
  'damhert',
  'das',
  'edelhert',
  'eekhoorn',
  'egel',
  'europese nerts',
  'exmoorpony',
  'galloway',
  'goudjakhals',
  'haas',
  'hermelijn',
  'hooglander',
  'konijn',
  'konikpaard',
  'otter',
  'ree',
  'shetlandpony',
  'steenmarter',
  'taurus',
  'vos',
  'wezel',
  'wild kat',
  'wild zwijn',
  'wisent',
  'woelrat',
  'wolf',
];

String _normalize(String s) {
  return s.trim().toLowerCase();
}

/// Alternatieve namen (bijv. API) -> exacte icoonnaam in de asset component.
const Map<String, String> _speciesNameAliases = {
  'wilde kat': 'wild kat',
  'exmoor pony': 'exmoorpony',
  'shetland pony': 'shetlandpony',
  'tauros': 'taurus',
};

/// Koppelt een soortnaam (bijv. uit de API) aan de exacte icoonnaam uit de assets.
/// Retourneert de icoonnaam als er een match is, anders null (dan wordt elders de originele naam gebruikt).
String? resolveSpeciesToIconName(String? species) {
  if (species == null || species.trim().isEmpty) return null;
  final n = _normalize(species);
  final alias = _speciesNameAliases[n];
  if (alias != null) return alias;
  for (final iconName in knownAnimalIconNames) {
    if (_normalize(iconName) == n) return iconName;
  }
  for (final iconName in knownAnimalIconNames) {
    final inNorm = _normalize(iconName);
    if (inNorm == n || inNorm.contains(n) || n.contains(inNorm)) return iconName;
  }
  return null;
}
