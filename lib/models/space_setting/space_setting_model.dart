class SpaceSettingModel {
  SpaceSettingModel({
    required this.name,
    required this.key,
    required this.value,
    this.isReverse = false,
  });

  String name;
  String key;
  int? value;
  bool isReverse;

  bool get boolVal => isReverse ? value == 0 : value == 1;
}
