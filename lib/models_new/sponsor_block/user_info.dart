class UserInfo {
  String? userName;
  int? minutesSaved;
  int? segmentCount;
  int? viewCount;
  int? ignoredSegmentCount;
  int? ignoredMinutesSaved;
  int? ignoredViewCount;
  int? warnings;
  int? reputation;
  String? vip;
  String? lastSegmentId;

  UserInfo({
    this.userName,
    this.minutesSaved,
    this.segmentCount,
    this.viewCount,
    this.ignoredSegmentCount,
    this.ignoredMinutesSaved,
    this.ignoredViewCount,
    this.warnings,
    this.reputation,
    this.vip,
    this.lastSegmentId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        userName: json["userName"],
        minutesSaved: json["minutesSaved"],
        segmentCount: json["segmentCount"],
        viewCount: json["viewCount"],
        ignoredSegmentCount: json["ignoredSegmentCount"],
        ignoredMinutesSaved: json["ignoredMinutesSaved"],
        ignoredViewCount: json["ignoredViewCount"],
        warnings: json["warnings"],
        reputation: json["reputation"],
        vip: json["vip"],
        lastSegmentId: json["lastSegmentID"],
      );
}
