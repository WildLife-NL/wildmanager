import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildlifenl_interaction_components/src/interfaces/interaction_read_api_interface.dart';

const String _tokenKey = 'bearer_token';
const Duration _timeout = Duration(seconds: 30);

/// Standaardimplementatie: GET interactions/me/ en GET interactions/query/
/// met Bearer token uit SharedPreferences.
class HttpInteractionReadApi implements InteractionReadApiInterface {
  HttpInteractionReadApi({
    required this.baseUrl,
  });

  final String baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<http.Response> _get(String path) async {
    final token = await _getToken();
    final uri = Uri.parse(baseUrl).resolve(path);
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final res = await http.get(uri, headers: headers).timeout(_timeout);
    return res;
  }

  @override
  Future<List<Map<String, dynamic>>> getMyInteractions() async {
    final res = await _get('interactions/me/');
    if (res.statusCode != HttpStatus.ok) {
      debugPrint('[HttpInteractionReadApi] getMyInteractions: ${res.statusCode}');
      throw Exception('Failed to get my interactions: ${res.statusCode}');
    }
    final body = res.body.trim();
    if (body.isEmpty) return [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> queryInteractions({
    required double areaLatitude,
    required double areaLongitude,
    required int areaRadiusMeters,
    DateTime? momentAfter,
    DateTime? momentBefore,
  }) async {
    final params = <String, String>{
      'area_latitude': areaLatitude.toString(),
      'area_longitude': areaLongitude.toString(),
      'area_radius': areaRadiusMeters.toString(),
      if (momentAfter != null)
        'moment_after': momentAfter.toUtc().toIso8601String(),
      if (momentBefore != null)
        'moment_before': momentBefore.toUtc().toIso8601String(),
    };
    final query = Uri(queryParameters: params).query;
    final path = 'interactions/query/?$query';
    final res = await _get(path);
    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body);
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['items'] is List)
              ? decoded['items'] as List
              : const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (res.statusCode == 204 || res.statusCode == 404) return [];
    if (res.statusCode == 401) throw Exception('Unauthorized (401) on interactions/query/');
    throw Exception('Query failed (${res.statusCode}): ${res.body}');
  }
}
