import 'item.dart';

class LiveFollowData {
  String? title;
  int? pageSize;
  int? totalPage;
  List<LiveFollowItem>? list;
  int? count;
  int? neverLivedCount;
  int? liveCount;
  List<dynamic>? neverLivedFaces;

  LiveFollowData({
    this.title,
    this.pageSize,
    this.totalPage,
    this.list,
    this.count,
    this.neverLivedCount,
    this.liveCount,
    this.neverLivedFaces,
  });

  factory LiveFollowData.fromJson(Map<String, dynamic> json) {
    List<LiveFollowItem>? list;
    if ((json['list'] as List<dynamic>?)?.isNotEmpty == true) {
      list = <LiveFollowItem>[];
      for (var item in json['list']) {
        if (item['live_status'] == 1) {
          list.add(LiveFollowItem.fromJson(item));
        }
      }
    }

    return LiveFollowData(
      title: json['title'] as String?,
      pageSize: json['pageSize'] as int?,
      totalPage: json['totalPage'] as int?,
      list: list,
      count: json['count'] as int?,
      neverLivedCount: json['never_lived_count'] as int?,
      liveCount: json['live_count'] as int?,
      neverLivedFaces: json['never_lived_faces'] as List<dynamic>?,
    );
  }
}
