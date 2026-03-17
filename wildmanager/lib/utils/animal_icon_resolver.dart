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

String iconNameToAssetFileName(String iconName) {
  return iconName.replaceAll(' ', '_');
}

const String animalIconsAssetPath = 'assets/icons/animals';

const List<String> animalIconAssetFileNames = [
  'bever',
  'boommarter',
  'bunzing',
  'damhert',
  'das',
  'edelhert',
  'eekhoorn',
  'egel',
  'europese_nerts',
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
  'wild_kat',
  'wild_zwijn',
  'wisent',
  'woelrat',
  'wolf',
];

String? getAnimalIconAssetPath(String iconName) {
  final fileName = iconNameToAssetFileName(iconName).toLowerCase();
  if (animalIconAssetFileNames.contains(fileName)) {
    return '$animalIconsAssetPath/$fileName.png';
  }
  return null;
}

List<String> getAllAnimalIconAssetKeys() {
  return [
    for (final f in animalIconAssetFileNames)
      '$animalIconsAssetPath/${f.toLowerCase()}.png',
  ];
}

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
