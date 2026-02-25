import 'package:wildlifenl_visitation_components/wildlifenl_visitation_components.dart';

import '../config/app_config.dart';
import '../models/living_lab.dart';


const double defaultVisitationCellSize = 50;


Future<List<HeatmapCell>> fetchVisitationForLivingLabs(
  List<LivingLab> livingLabs, {
  DateTime? start,
  DateTime? end,
  double cellSize = defaultVisitationCellSize,
  int? maxCount,
}) async {
  if (livingLabs.isEmpty) return [];
  final baseUrl = AppConfig.loginBaseUrl;
  if (baseUrl.isEmpty) return [];

  final now = DateTime.now();
  final startDate = start ?? now.subtract(const Duration(days: 90));
  final endDate = end ?? now;

  if (cellSize < 20 || cellSize > 10000) {
    cellSize = cellSize.clamp(20.0, 10000.0);
  }

  final api = HttpVisitationReadApi(baseUrl: baseUrl);
  final allCells = <VisitationCell>[];

  for (final lab in livingLabs) {
    if (lab.id.isEmpty) continue;
    try {
      final response = await api.getVisitationForLivingLab(
        livingLabID: lab.id,
        start: startDate,
        end: endDate,
        cellSize: cellSize,
      );
      allCells.addAll(response.cells);
    } catch (_) {
      continue;
    }
  }

  return toHeatmapCells(allCells, maxCount: maxCount);
}
