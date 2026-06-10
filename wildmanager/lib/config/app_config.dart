import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'WildManager';

  static String get loginBaseUrl {
    const fromDefine = String.fromEnvironment('DEV_BASE_URL');
    final url = fromDefine.isNotEmpty
        ? fromDefine
        : (dotenv.env['DEV_BASE_URL']?.trim() ?? '');
    if (url.isEmpty) return '';
    return url.replaceFirst(RegExp(r'/$'), '');
  }
}
