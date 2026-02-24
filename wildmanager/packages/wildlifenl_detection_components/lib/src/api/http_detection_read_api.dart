import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../interfaces/detection_read_api_interface.dart';

const String _tokenKey = 'bearer_token';
const Duration _timeout = Duration(seconds: 30);

class HttpDetectionReadApi implements DetectionReadApiInterface {
  HttpDetectionReadApi({
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
    debugPrint('[Detections API] GET ${uri.toString()}');
    debugPrint('[Detections API] Token aanwezig: ${token != null && token.isNotEmpty}');
    final res = await http.get(uri, headers: headers).timeout(_timeout);
    debugPrint('[Detections API] Status: ${res.statusCode} body lengte: ${res.body.length}');
    return res;
  }

  @override
  Future<List<Map<String, dynamic>>> getDetectionsByFilter({
    required DateTime start,
    required DateTime end,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    final params = <String, String>{
      'start': start.toUtc().toIso8601String(),
      'end': end.toUtc().toIso8601String(),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radius.toString(),
    };
    final query = Uri(queryParameters: params).query;
    final path = 'detection/?$query';
    final res = await _get(path);

    if (res.statusCode != 200) {
      debugPrint('[Detections API] Fout response (eerste 400 tekens): ${res.body.length > 400 ? res.body.substring(0, 400) : res.body}');
      if (res.statusCode == 401) {
        throw Exception('Unauthorized (401) on GET /detection/');
      }
      throw Exception('Failed to get detections: ${res.statusCode}');
    }

    final body = res.body.trim();
    if (body.isEmpty) {
      debugPrint('[Detections API] Lege body – server gaf 200 maar geen inhoud');
      return [];
    }

    final decoded = jsonDecode(body);
    List list = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List)
            ? decoded['items'] as List
            : (decoded is Map && decoded['results'] is List)
                ? decoded['results'] as List
                : (decoded is Map && decoded['data'] is List)
                    ? decoded['data'] as List
                    : (decoded is Map && decoded['detections'] is List)
                        ? decoded['detections'] as List
                        : const [];

    if (list.isEmpty) {
      debugPrint('[Detections API] Response is geen lijst of lijst is leeg. decoded type: ${decoded.runtimeType}');
      if (decoded is Map) {
        debugPrint('[Detections API] Top-level keys: ${decoded.keys.toList()}');
      }
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
