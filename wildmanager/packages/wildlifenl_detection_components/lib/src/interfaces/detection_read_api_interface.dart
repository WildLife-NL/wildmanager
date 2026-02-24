abstract class DetectionReadApiInterface {
  Future<List<Map<String, dynamic>>> getDetectionsByFilter({
    required DateTime start,
    required DateTime end,
    required double latitude,
    required double longitude,
    required int radius,
  });
}
