import 'card_live_item.dart';

class ModuleInfo {
  int? id;
  String? link;
  String? pic;
  String? title;
  int? type;
  int? sort;
  int? count;

  ModuleInfo({
    this.id,
    this.link,
    this.pic,
    this.title,
    this.type,
    this.sort,
    this.count,
  });

  factory ModuleInfo.fromJson(Map<String, dynamic> json) => ModuleInfo(
        id: json['id'] as int?,
        link: json['link'] as String?,
        pic: json['pic'] as String?,
        title: json['title'] as String?,
        type: json['type'] as int?,
        sort: json['sort'] as int?,
        count: json['count'] as int?,
      );
}

class ExtraInfo {
  int? totalCount;

  ExtraInfo({this.totalCount});

  factory ExtraInfo.fromJson(Map<String, dynamic> json) => ExtraInfo(
        totalCount: json['total_count'],
      );
}

class CardDataItem {
  ModuleInfo? moduleInfo;
  List<CardLiveItem>? list;
  dynamic topView;
  ExtraInfo? extraInfo;

  CardDataItem({
    this.moduleInfo,
    this.list,
    this.topView,
    this.extraInfo,
  });

  factory CardDataItem.fromJson(Map<String, dynamic> json) => CardDataItem(
        moduleInfo: json['module_info'] == null
            ? null
            : ModuleInfo.fromJson(json['module_info'] as Map<String, dynamic>),
        list: (json['list'] as List<dynamic>?)
            ?.map((e) => CardLiveItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        topView: json['top_view'] as dynamic,
        extraInfo: json['extra_info'] == null
            ? null
            : ExtraInfo.fromJson(json['extra_info'] as Map<String, dynamic>),
      );
}
