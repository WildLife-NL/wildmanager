/// Package-prefix voor assets in deze package.
const String packagePrefix = 'packages/wildlifenl_assets';

/// Geeft het pad naar de **foto** (assets/animals/) voor een soortnaam, of null.
/// Gebruik voor lijsten/kaarten waar je de grotere foto wilt.
String? getAnimalPhotoPath(String? commonName) {
  if (commonName == null || commonName.isEmpty) return null;
  final name = commonName.toLowerCase();

  if (name.contains('wolf')) return '$packagePrefix/assets/animals/wolf.png';
  if (name.contains('vos') || name.contains('fox')) return '$packagePrefix/assets/animals/vos.png';
  if (name.contains('das') || name.contains('badger')) return '$packagePrefix/assets/animals/das.png';
  if (name.contains('ree') || name.contains('roe deer') || name.contains('deer')) return '$packagePrefix/assets/animals/ree.png';
  if (name.contains('damhert') || name.contains('fallow')) return '$packagePrefix/assets/animals/damhert.png';
  if (name.contains('edelhert') || name.contains('red deer')) return '$packagePrefix/assets/animals/edelhert.png';
  if (name.contains('hert')) return '$packagePrefix/assets/animals/edelhert.png';
  if (name.contains('zwijn') || name.contains('wild zwijn') || name.contains('boar')) return '$packagePrefix/assets/animals/wild zwijn.png';
  if (name.contains('bever') || name.contains('beaver')) return '$packagePrefix/assets/animals/bever.png';
  if (name.contains('eekhoorn') || name.contains('squirrel')) return '$packagePrefix/assets/animals/eekhoorn.png';
  if (name.contains('egel') || name.contains('hedgehog')) return '$packagePrefix/assets/animals/egel.png';
  if (name.contains('steenmarter')) return '$packagePrefix/assets/animals/steenmarter.png';
  if (name.contains('boommarter')) return '$packagePrefix/assets/animals/boommarter.png';
  if (name.contains('marter') || name.contains('marten')) return '$packagePrefix/assets/animals/steenmarter.png';
  if (name.contains('bunzing')) return '$packagePrefix/assets/animals/bunzing.png';
  if (name.contains('wezel') || name.contains('weasel')) return '$packagePrefix/assets/animals/wezel.png';
  if (name.contains('hermelijn') || name.contains('stoat')) return '$packagePrefix/assets/animals/hermelijn.png';
  if (name.contains('otter')) return '$packagePrefix/assets/animals/otter.png';
  if (name.contains('wild kat') || name.contains('wilde kat') || name.contains('wildcat')) return '$packagePrefix/assets/animals/wild kat.png';
  if (name.contains('wisent') || name.contains('bison')) return '$packagePrefix/assets/animals/wisent.png';
  if (name.contains('hooglander') || name.contains('highlander')) return '$packagePrefix/assets/animals/hooglander.png';
  if (name.contains('galloway')) return '$packagePrefix/assets/animals/galloway.png';
  if (name.contains('konik') || name.contains('konikpaard')) return '$packagePrefix/assets/animals/konikpaard.png';
  if (name.contains('shetland') || name.contains('pony')) return '$packagePrefix/assets/animals/shetland pony.png';
  if (name.contains('exmoor')) return '$packagePrefix/assets/animals/exmoor pony.png';
  if (name.contains('tauros')) return '$packagePrefix/assets/animals/tauros.png';
  if (name.contains('europese nerts') || name.contains('european mink')) return '$packagePrefix/assets/animals/europese nerts.png';
  if (name.contains('woelrat') || name.contains('vole')) return '$packagePrefix/assets/animals/woelrat.png';
  if (name.contains('goudjakhals') || name.contains('golden jackal')) return '$packagePrefix/assets/animals/goudjakhals.png';
  if (name.contains('haas') || name.contains('hare')) return '$packagePrefix/assets/animals/haas.png';
  if (name.contains('konijn') || name.contains('rabbit')) return '$packagePrefix/assets/animals/konijn.png';

  return null;
}

/// Geeft het pad naar het **icoon** (assets/icons/animals/) voor een soortnaam, of null.
/// Gebruik voor pins op de kaart e.d.
String? getAnimalIconPath(String? speciesName) {
  if (speciesName == null || speciesName.isEmpty) return null;
  final name = speciesName.toLowerCase();

  if (name.contains('wolf')) return '$packagePrefix/assets/icons/animals/wolf.png';
  if (name.contains('vos') || name.contains('fox')) return '$packagePrefix/assets/icons/animals/vos.png';
  if (name.contains('das') || name.contains('badger')) return '$packagePrefix/assets/icons/animals/das.png';
  if (name.contains('ree') || name.contains('deer')) return '$packagePrefix/assets/icons/animals/ree.png';
  if (name.contains('zwijn') || name.contains('boar')) return '$packagePrefix/assets/icons/animals/wild_zwijn.png';
  if (name.contains('damhert')) return '$packagePrefix/assets/icons/animals/damhert.png';
  if (name.contains('egel') || name.contains('hedgehog')) return '$packagePrefix/assets/icons/animals/egel.png';
  if (name.contains('eekhoorn') || name.contains('squirrel')) return '$packagePrefix/assets/icons/animals/eekhoorn.png';
  if (name.contains('bever') || name.contains('beaver')) return '$packagePrefix/assets/icons/animals/beaver.png';
  if (name.contains('boommarten') || name.contains('marten')) return '$packagePrefix/assets/icons/animals/boommarten.png';
  if (name.contains('hooglander') || name.contains('highlander')) return '$packagePrefix/assets/icons/animals/hooglander.png';
  if (name.contains('wisent') || name.contains('bison')) return '$packagePrefix/assets/icons/animals/wisent.png';
  if (name.contains('edelhert') || name.contains('red deer')) return '$packagePrefix/assets/icons/animals/edelhert.png';
  if (name.contains('steenmarter')) return '$packagePrefix/assets/icons/animals/steenmarter.png';
  if (name.contains('bunzing')) return '$packagePrefix/assets/icons/animals/bunzing.png';
  if (name.contains('wezel') || name.contains('weasel')) return '$packagePrefix/assets/icons/animals/wezel.png';
  if (name.contains('hermelijn') || name.contains('stoat')) return '$packagePrefix/assets/icons/animals/hermelijn.png';
  if (name.contains('otter')) return '$packagePrefix/assets/icons/animals/otter.png';
  if (name.contains('wild kat') || name.contains('wildcat')) return '$packagePrefix/assets/icons/animals/wild_kat.png';
  if (name.contains('galloway')) return '$packagePrefix/assets/icons/animals/galloway.png';
  if (name.contains('konik') || name.contains('konikpaard')) return '$packagePrefix/assets/icons/animals/konikpaard.png';
  if (name.contains('shetland') || name.contains('pony')) return '$packagePrefix/assets/icons/animals/shetland_pony.png';
  if (name.contains('exmoor')) return '$packagePrefix/assets/icons/animals/exmoor_pony.png';
  if (name.contains('tauros')) return '$packagePrefix/assets/icons/animals/tauros.png';
  if (name.contains('europese nerts') || name.contains('mink')) return '$packagePrefix/assets/icons/animals/europese_nerts.png';
  if (name.contains('woelrat') || name.contains('vole')) return '$packagePrefix/assets/icons/animals/woelrat.png';
  if (name.contains('goudjakhals') || name.contains('jackal')) return '$packagePrefix/assets/icons/animals/goudjakhals.png';
  if (name.contains('haas') || name.contains('hare')) return '$packagePrefix/assets/icons/animals/haas.png';
  if (name.contains('konijn') || name.contains('rabbit')) return '$packagePrefix/assets/icons/animals/konijn.png';

  return null;
}

/// Alle package-assetpaden voor dieren (foto's + iconen) om te precachen.
List<String> getAllAnimalAssetPaths() {
  return [
    '$packagePrefix/assets/animals/wolf.png',
    '$packagePrefix/assets/animals/vos.png',
    '$packagePrefix/assets/animals/das.png',
    '$packagePrefix/assets/animals/ree.png',
    '$packagePrefix/assets/animals/damhert.png',
    '$packagePrefix/assets/animals/edelhert.png',
    '$packagePrefix/assets/animals/wild zwijn.png',
    '$packagePrefix/assets/animals/bever.png',
    '$packagePrefix/assets/animals/eekhoorn.png',
    '$packagePrefix/assets/animals/egel.png',
    '$packagePrefix/assets/animals/steenmarter.png',
    '$packagePrefix/assets/animals/boommarter.png',
    '$packagePrefix/assets/animals/bunzing.png',
    '$packagePrefix/assets/animals/wezel.png',
    '$packagePrefix/assets/animals/hermelijn.png',
    '$packagePrefix/assets/animals/otter.png',
    '$packagePrefix/assets/animals/wild kat.png',
    '$packagePrefix/assets/animals/wisent.png',
    '$packagePrefix/assets/animals/hooglander.png',
    '$packagePrefix/assets/animals/galloway.png',
    '$packagePrefix/assets/animals/konikpaard.png',
    '$packagePrefix/assets/animals/shetland pony.png',
    '$packagePrefix/assets/animals/exmoor pony.png',
    '$packagePrefix/assets/animals/tauros.png',
    '$packagePrefix/assets/animals/europese nerts.png',
    '$packagePrefix/assets/animals/woelrat.png',
    '$packagePrefix/assets/animals/goudjakhals.png',
    '$packagePrefix/assets/animals/haas.png',
    '$packagePrefix/assets/animals/konijn.png',
    '$packagePrefix/assets/icons/animals/wolf.png',
    '$packagePrefix/assets/icons/animals/vos.png',
    '$packagePrefix/assets/icons/animals/das.png',
    '$packagePrefix/assets/icons/animals/ree.png',
    '$packagePrefix/assets/icons/animals/wild_zwijn.png',
    '$packagePrefix/assets/icons/animals/damhert.png',
    '$packagePrefix/assets/icons/animals/egel.png',
    '$packagePrefix/assets/icons/animals/eekhoorn.png',
    '$packagePrefix/assets/icons/animals/beaver.png',
    '$packagePrefix/assets/icons/animals/boommarten.png',
    '$packagePrefix/assets/icons/animals/hooglander.png',
    '$packagePrefix/assets/icons/animals/wisent.png',
  ];
}
