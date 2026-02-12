import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'WildManager';

  static String get loginBaseUrl {
    final url = dotenv.env['DEV_BASE_URL']?.trim();
    if (url == null || url.isEmpty) return '';
    return url.replaceFirst(RegExp(r'/$'), '');
  }
}
