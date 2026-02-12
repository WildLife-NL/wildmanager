import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/living_lab.dart';

const _bearerTokenKey = 'bearer_token';

/// Fetches all living labs from the API. Requires stored bearer token.
Future<List<LivingLab>> fetchLivingLabs() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(_bearerTokenKey);
  if (token == null || token.trim().isEmpty) {
    throw LivingLabsException('Geen inlogtoken');
  }

  final url = Uri.parse('${AppConfig.loginBaseUrl}/livinglabs/');
  final response = await http.get(
    url,
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw LivingLabsException(
      'Living labs ophalen mislukt: ${response.statusCode}',
    );
  }

  final list = json.decode(response.body) as List<dynamic>?;
  if (list == null) return [];
  return list
      .map((e) => LivingLab.fromJson(e as Map<String, dynamic>))
      .toList();
}

class LivingLabsException implements Exception {
  LivingLabsException(this.message);
  final String message;
  @override
  String toString() => message;
}
