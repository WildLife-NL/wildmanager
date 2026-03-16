import 'animal_assets.dart';

/// Package-pad voor alle app-icons (rapporteren, questionnaire, gender, etc.).
String iconPath(String relativePath) =>
    '$packagePrefix/assets/icons/$relativePath';

// --- Root icons ---
String get iconMarkedEarth => iconPath('marked_earth.png');
String get iconReport => iconPath('report.png');
String get iconMyReport => iconPath('my_report.png');
String get iconAccident => iconPath('accident.png');
String get iconBinoculars => iconPath('binoculars.png');
String get iconAgriculture => iconPath('agriculture.png');
String get iconDeer => iconPath('deer.png');
String get iconAnimalmeet => iconPath('animalmeet.png');

// --- Rapporteren ---
String get iconRapporterenCrop => iconPath('rapporteren/crop_icon.png');
String get iconRapporterenHealth => iconPath('rapporteren/health_icon.png');
String get iconRapporterenSighting => iconPath('rapporteren/sighting_icon.png');
String get iconRapporterenAccident => iconPath('rapporteren/accident_icon.png');

// --- Questionnaire ---
String get iconQuestionnaireArrow => iconPath('questionnaire/arrow.png');
String get iconQuestionnaireArrowForward =>
    iconPath('questionnaire/arrow_forward.png');
String get iconQuestionnaireSave => iconPath('questionnaire/save.png');

// --- Gender ---
String get iconGenderFemale => iconPath('gender/female_gender.png');
String get iconGenderMale => iconPath('gender/male_gender.png');
String get iconGenderUnknown => iconPath('gender/unknown_gender.png');

// --- Category ---
String get iconCategoryEvenhoevigen => iconPath('category/evenhoevigen.png');
String get iconCategoryKnaagdieren => iconPath('category/knaagdieren.png');
String get iconCategoryRoofdieren => iconPath('category/roofdieren.png');

// --- Possesion / gewassen ---
String get iconPossesionImpactedArea =>
    iconPath('possesion/impacted_area_type.png');
String get iconPossesionApple => iconPath('possesion/gewassen/apple.svg');
String get iconPossesionCorn => iconPath('possesion/gewassen/corn.svg');
String get iconPossesionGrass => iconPath('possesion/gewassen/grass.svg');
String get iconPossesionRadish => iconPath('possesion/gewassen/radish_2.svg');
String get iconPossesionTomato => iconPath('possesion/gewassen/tomato.svg');
String get iconPossesionTulip => iconPath('possesion/gewassen/tulip_2.svg');
String get iconPossesionWheat => iconPath('possesion/gewassen/wheat.svg');

/// Alle app-icon paden (voor precaching).
List<String> getAllAppIconPaths() => [
      iconMarkedEarth,
      iconReport,
      iconMyReport,
      iconAccident,
      iconBinoculars,
      iconAgriculture,
      iconDeer,
      iconRapporterenCrop,
      iconRapporterenHealth,
      iconRapporterenSighting,
      iconRapporterenAccident,
      iconQuestionnaireArrow,
      iconQuestionnaireArrowForward,
      iconQuestionnaireSave,
      iconGenderFemale,
      iconGenderMale,
      iconGenderUnknown,
      iconCategoryEvenhoevigen,
      iconCategoryKnaagdieren,
      iconCategoryRoofdieren,
      iconPossesionImpactedArea,
      iconPossesionApple,
      iconPossesionCorn,
      iconPossesionGrass,
      iconPossesionRadish,
      iconPossesionTomato,
      iconPossesionTulip,
      iconPossesionWheat,
    ];
