import 'package:PiliPalaX/models/space_setting/privacy.dart';

class SpaceSettingData {
  final Privacy? privacy;

  SpaceSettingData({this.privacy});

  factory SpaceSettingData.fromJson(Map<String, dynamic> json) {
    return SpaceSettingData(
      privacy:
          json['privacy'] != null ? Privacy.fromJson(json['privacy']) : null,
    );
  }
}
