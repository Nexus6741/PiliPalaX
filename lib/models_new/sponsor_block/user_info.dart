class UserInfo {
  final String? userName;
  final int? viewCount;
  final double? minutesSaved;
  final int? segmentCount;
  final int? ignoredSegmentCount;
  final int? ignoredViewCount;
  final double? ignoredMinutesSaved;
  final String? vip;
  final int? lastSegmentID;
  final int? warnings;

  UserInfo({
    this.userName,
    this.viewCount,
    this.minutesSaved,
    this.segmentCount,
    this.ignoredSegmentCount,
    this.ignoredViewCount,
    this.ignoredMinutesSaved,
    this.vip,
    this.lastSegmentID,
    this.warnings,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userName: json['userName'] as String?,
      viewCount: json['viewCount'] as int?,
      minutesSaved: (json['minutesSaved'] as num?)?.toDouble(),
      segmentCount: json['segmentCount'] as int?,
      ignoredSegmentCount: json['ignoredSegmentCount'] as int?,
      ignoredViewCount: json['ignoredViewCount'] as int?,
      ignoredMinutesSaved: (json['ignoredMinutesSaved'] as num?)?.toDouble(),
      vip: json['vip'] as String?,
      lastSegmentID: json['lastSegmentID'] as int?,
      warnings: json['warnings'] as int?,
    );
  }

  @override
  String toString() {
    final List<String> parts = [];
    if (viewCount != null) {
      parts.add('跳过次数: $viewCount');
    }
    if (minutesSaved != null) {
      parts.add('节省时间: ${minutesSaved!.toStringAsFixed(2)}分钟');
    }
    if (segmentCount != null) {
      parts.add('提交片段: $segmentCount');
    }
    return parts.join('\n');
  }
}
