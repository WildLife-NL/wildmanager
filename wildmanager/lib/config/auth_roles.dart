/// Rollen die toegang geven tot WildManager. Gebruiker moet minstens één hebben.
const List<String> allowedLoginRoles = [
  'wildlife-manager',
  'nature-area-manager',
  'herd-manager',
];

/// Haalt roles/scopes uit de (mogelijk geneste) API-response.
List<String> _collectRolesFromUser(dynamic user) {
  if (user == null || user is! Map<String, dynamic>) return [];
  final m = user;
  final nested = m['user'] is Map<String, dynamic> ? m['user'] as Map<String, dynamic> : null;
  final List<String> out = [];
  for (final map in [m, if (nested != null) nested]) {
    final r = map['roles'];
    final s = map['scopes'];
    if (r is List) for (final e in r) { if (e is String) out.add(e.trim()); }
    if (s is List) for (final e in s) { if (e is String) out.add(e.trim()); }
  }
  return out;
}

/// Controleert of [user] (API-response na verificatie) minstens één toegestane rol heeft.
/// Ondersteunt zowel 'roles' als 'scopes', en geneste 'user' in de response.
bool userHasAllowedRole(dynamic user) {
  final roles = _collectRolesFromUser(user);
  return roles.any((r) => allowedLoginRoles.contains(r));
}

/// Melding voor gebruikers zonder toegestane rol.
const String noAllowedRoleMessage =
    'Je hebt geen toegang tot WildManager. Alleen gebruikers met een van de volgende rollen kunnen inloggen: '
    'wildlife-manager, nature-area-manager of herd-manager. '
    'Neem contact op met je beheerder als je denkt dat je toegang zou moeten hebben.';
