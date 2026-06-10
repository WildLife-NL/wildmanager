import 'package:shared_preferences/shared_preferences.dart';

const bearerTokenKey = 'bearer_token';
const scopesKey = 'scopes';

const unauthorizedSessionMessage =
    'Je sessie is verlopen of je hebt geen rechten voor deze omgeving '
    '(bijvoorbeeld test vs live). Log opnieuw in met een account dat toegang heeft.';

Future<void> clearStoredAuth() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(bearerTokenKey);
  await prefs.remove(scopesKey);
}

bool isUnauthorizedError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('401') || message.contains('unauthorized');
}
