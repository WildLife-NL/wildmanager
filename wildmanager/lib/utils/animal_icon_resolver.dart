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

/// Bestandsnaam voor asset (zonder spaties) voor Flutter Web compatibility.
/// Flutter Web encodeert spaties in asset-URLs dubbel, wat 404 geeft in release builds.
String iconNameToAssetFileName(String iconName) {
  return iconName.replaceAll(' ', '_');
}

/// Basis-pad voor diericonen in package wildlifenl_assets.
const String animalIconsAssetPath = 'assets/icons/animals';

/// Expliciete lijst van alle diericon-assetpaden (bestandsnaam zonder .png).
/// Op web release worden dynamische paden soms niet meegenomen; door elke path
/// hier als literal te zetten, worden alle iconen in de build gebundeld.
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

/// Package-naam voor diericonen (voor Image.asset en rootBundle).
const String animalIconsPackage = 'wildlifenl_assets';

/// Geeft het asset-pad voor een icoonnaam, of null als onbekend.
/// Gebruikt de statische lijst zodat web release alle iconen meeneemt.
String? getAnimalIconAssetPath(String iconName) {
  final fileName = iconNameToAssetFileName(iconName);
  if (animalIconAssetFileNames.contains(fileName)) {
    return '$animalIconsAssetPath/$fileName.png';
  }
  return null;
}

/// Volle asset-keys voor preload (packages/...). Zorgt dat web release alle iconen laadt.
List<String> getAllAnimalIconAssetKeys() {
  return [
    for (final f in animalIconAssetFileNames)
      'packages/$animalIconsPackage/$animalIconsAssetPath/$f.png',
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
