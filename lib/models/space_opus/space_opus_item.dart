/// 用户空间图文项模型
/// 参考PiliPlus的SpaceOpusItemModel
class SpaceOpusItem {
  String? content;
  String? jumpUrl;
  String? opusId;
  SpaceOpusStat? stat;
  SpaceOpusCover? cover;

  SpaceOpusItem({
    this.content,
    this.jumpUrl,
    this.opusId,
    this.stat,
    this.cover,
  });

  factory SpaceOpusItem.fromJson(Map<String, dynamic> json) {
    return SpaceOpusItem(
      content: json['content'] as String?,
      jumpUrl: json['jump_url'] as String?,
      opusId: json['opus_id'] as String?,
      stat: json['stat'] == null
          ? null
          : SpaceOpusStat.fromJson(json['stat'] as Map<String, dynamic>),
      cover: json['cover'] == null
          ? null
          : SpaceOpusCover.fromJson(json['cover'] as Map<String, dynamic>),
    );
  }
}

/// 图文统计
class SpaceOpusStat {
  String? like;

  SpaceOpusStat({this.like});

  factory SpaceOpusStat.fromJson(Map<String, dynamic> json) {
    return SpaceOpusStat(
      like: json['like'] as String?,
    );
  }
}

/// 图文封面
class SpaceOpusCover {
  int? height;
  String? url;
  int? width;
  late double ratio;

  SpaceOpusCover({this.height, this.url, this.width, double? ratio}) {
    this.ratio = ratio ?? 1.0;
  }

  factory SpaceOpusCover.fromJson(Map<String, dynamic> json) {
    final height = json['height'] as int?;
    final width = json['width'] as int?;
    double ratio = 1.0;
    if (height != null && width != null && width > 0) {
      // 限制比例在 0.68 到 2.7 之间
      ratio = (height / width).clamp(0.68, 2.7);
    }
    return SpaceOpusCover(
      height: height,
      url: json['url'] as String?,
      width: width,
      ratio: ratio,
    );
  }
}

/// 图文数据响应
class SpaceOpusData {
  bool? hasMore;
  List<SpaceOpusItem>? items;
  String? offset;
  int? updateNum;

  SpaceOpusData({this.hasMore, this.items, this.offset, this.updateNum});

  factory SpaceOpusData.fromJson(Map<String, dynamic> json) {
    return SpaceOpusData(
      hasMore: json['has_more'] as bool?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => SpaceOpusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      offset: json['offset'] as String?,
      updateNum: json['update_num'] as int?,
    );
  }
}
