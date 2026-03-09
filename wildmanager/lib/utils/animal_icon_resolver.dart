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

const Map<String, String> _speciesNameAliases = {
  'wilde kat': 'wild kat',
  'exmoor pony': 'exmoorpony',
  'shetland pony': 'shetlandpony',
  'tauros': 'taurus',
};

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
