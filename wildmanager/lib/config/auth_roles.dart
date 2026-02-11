/// Rollen die toegang geven tot WildManager. Gebruiker moet minstens één hebben.
const List<String> allowedLoginRoles = [
  'wildlife-manager',
  'nature-area-manager',
  'herd-manager',
];

/// Controleert of [user] (API-response na verificatie) minstens één toegestane rol heeft.
/// Ondersteunt zowel 'roles' als 'scopes' in de user-map.
bool userHasAllowedRole(dynamic user) {
  if (user == null) return false;
  List<String> roles = [];
  if (user is Map<String, dynamic>) {
    final r = user['roles'];
    final s = user['scopes'];
    if (r is List) {
      for (final e in r) {
        if (e is String) roles.add(e.trim());
      }
    }
    if (s is List && roles.isEmpty) {
      for (final e in s) {
        if (e is String) roles.add(e.trim());
      }
    }
  }
  return roles.any((r) => allowedLoginRoles.contains(r));
}

/// Melding voor gebruikers zonder toegestane rol.
const String noAllowedRoleMessage =
    'Je hebt geen toegang tot WildManager. Alleen gebruikers met een van de volgende rollen kunnen inloggen: '
    'wildlife-manager, nature-area-manager of herd-manager. '
    'Neem contact op met je beheerder als je denkt dat je toegang zou moeten hebben.';
