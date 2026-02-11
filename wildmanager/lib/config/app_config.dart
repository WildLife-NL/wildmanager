/// App-configuratie (base URL en naam). Pas aan voor productie.
class AppConfig {
  AppConfig._();

  static const String appName = 'WildManager';

  /// Backend base URL voor login (zonder trailing slash).
  /// Voor productie: vervang door de echte API-URL (bijv. uit .env).
  static const String loginBaseUrl = 'https://test-api-wildlifenl.uu.nl';
}
