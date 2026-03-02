import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

import '../models/interaction.dart';

class FilterState {
  const FilterState({
    this.momentAfter,
    this.momentBefore,
    this.waarneming = false,
    this.schade = false,
    this.aanrijding = false,
    this.detectie = false,
    this.detectieVisueel = false,
    this.detectieAkoestisch = false,
    this.detectieChemisch = false,
    this.detectieOverig = false,
    this.showAnimals = true,
    this.showHeatmap = true,
    this.showLivingLab = true,
    this.heatmapRoodVanaf,
    this.heatmapCellSizeMeters,
  });

  final DateTime? momentAfter;
  final DateTime? momentBefore;
  final bool waarneming;
  final bool schade;
  final bool aanrijding;
  final bool detectie;
  final bool detectieVisueel;
  final bool detectieAkoestisch;
  final bool detectieChemisch;
  final bool detectieOverig;
  final bool showAnimals;
  final bool showHeatmap;
  final bool showLivingLab;
  final int? heatmapRoodVanaf;
  final double? heatmapCellSizeMeters;

  static FilterState get defaults => const FilterState();

  int get activeFilterCount {
    var n = 0;
    if (momentAfter != null || momentBefore != null) n++;
    if (waarneming) n++;
    if (schade) n++;
    if (aanrijding) n++;
    if (detectie) n++;
    if (!showAnimals) n++;
    if (!showHeatmap) n++;
    if (!showLivingLab) n++;
    return n;
  }

  bool get hasAnyInteractionTypeSelected => waarneming || schade || aanrijding;

  bool get hasAnyEventTypeSelected =>
      waarneming || schade || aanrijding || detectie;

  bool get hasAnyDetectionSubtypeSelected =>
      detectieVisueel || detectieAkoestisch || detectieChemisch || detectieOverig;

  bool interactionTypeMatches(int typeId) {
    if (!hasAnyInteractionTypeSelected) return true;
    switch (typeId) {
      case interactionTypeSighting:
        return waarneming;
      case interactionTypeDamage:
        return schade;
      case interactionTypeCollision:
        return aanrijding;
      default:
        return false;
    }
  }

  bool detectionTypeMatches(dynamic type) {
    if (!hasAnyEventTypeSelected) return true;
    if (!detectie) return false;
    if (!hasAnyDetectionSubtypeSelected) return true;
    if (type is DetectionType) {
      switch (type) {
        case DetectionType.visual:
          return detectieVisueel;
        case DetectionType.acoustic:
          return detectieAkoestisch;
        case DetectionType.chemical:
          return detectieChemisch;
        case DetectionType.other:
          return detectieOverig;
      }
    }
    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterState &&
          momentAfter == other.momentAfter &&
          momentBefore == other.momentBefore &&
          waarneming == other.waarneming &&
          schade == other.schade &&
          aanrijding == other.aanrijding &&
          detectie == other.detectie &&
          detectieVisueel == other.detectieVisueel &&
          detectieAkoestisch == other.detectieAkoestisch &&
          detectieChemisch == other.detectieChemisch &&
          detectieOverig == other.detectieOverig &&
          showAnimals == other.showAnimals &&
          showHeatmap == other.showHeatmap &&
          showLivingLab == other.showLivingLab &&
          heatmapRoodVanaf == other.heatmapRoodVanaf &&
          heatmapCellSizeMeters == other.heatmapCellSizeMeters;

  @override
  int get hashCode => Object.hash(
        momentAfter,
        momentBefore,
        waarneming,
        schade,
        aanrijding,
        detectie,
        detectieVisueel,
        detectieAkoestisch,
        detectieChemisch,
        detectieOverig,
        showAnimals,
        showHeatmap,
        showLivingLab,
        heatmapRoodVanaf,
        heatmapCellSizeMeters,
      );

  FilterState copyWith({
    DateTime? momentAfter,
    DateTime? momentBefore,
    bool? waarneming,
    bool? schade,
    bool? aanrijding,
    bool? detectie,
    bool? detectieVisueel,
    bool? detectieAkoestisch,
    bool? detectieChemisch,
    bool? detectieOverig,
    bool? showAnimals,
    bool? showHeatmap,
    bool? showLivingLab,
    int? heatmapRoodVanaf,
    double? heatmapCellSizeMeters,
    bool clearMomentAfter = false,
    bool clearMomentBefore = false,
    bool clearHeatmapRoodVanaf = false,
    bool clearHeatmapCellSize = false,
  }) {
    return FilterState(
      momentAfter: clearMomentAfter ? null : (momentAfter ?? this.momentAfter),
      momentBefore: clearMomentBefore ? null : (momentBefore ?? this.momentBefore),
      waarneming: waarneming ?? this.waarneming,
      schade: schade ?? this.schade,
      aanrijding: aanrijding ?? this.aanrijding,
      detectie: detectie ?? this.detectie,
      detectieVisueel: detectieVisueel ?? this.detectieVisueel,
      detectieAkoestisch: detectieAkoestisch ?? this.detectieAkoestisch,
      detectieChemisch: detectieChemisch ?? this.detectieChemisch,
      detectieOverig: detectieOverig ?? this.detectieOverig,
      showAnimals: showAnimals ?? this.showAnimals,
      showHeatmap: showHeatmap ?? this.showHeatmap,
      showLivingLab: showLivingLab ?? this.showLivingLab,
      heatmapRoodVanaf: clearHeatmapRoodVanaf ? null : (heatmapRoodVanaf ?? this.heatmapRoodVanaf),
      heatmapCellSizeMeters:
          clearHeatmapCellSize ? null : (heatmapCellSizeMeters ?? this.heatmapCellSizeMeters),
    );
  }
}
