import 'dart:convert';

/// 视频标签模型
/// 用于表示视频的分类标签、话题标签和BGM标签
class VideoTag {
  /// 标签ID
  int? tagId;

  /// 标签名称
  String? tagName;

  /// 标签类型: 'tag'(普通), 'topic'(话题), 'bgm'(音乐)
  String? tagType;

  /// 音乐ID(仅BGM标签使用)
  String? musicId;

  /// 跳转链接
  String? jumpUrl;

  VideoTag({
    this.tagId,
    this.tagName,
    this.tagType,
    this.musicId,
    this.jumpUrl,
  });

  /// 从JSON创建VideoTag对象
  factory VideoTag.fromJson(Map<String, dynamic> json) => VideoTag(
        tagId: json["tag_id"],
        tagName: json["tag_name"],
        tagType: json["tag_type"],
        musicId: json["music_id"],
        jumpUrl: json["jump_url"],
      );

  /// 将VideoTag对象转换为JSON
  Map<String, dynamic> toJson() => {
        "tag_id": tagId,
        "tag_name": tagName,
        "tag_type": tagType,
        "music_id": musicId,
        "jump_url": jumpUrl,
      };

  /// 从JSON字符串创建VideoTag对象
  factory VideoTag.fromRawJson(String str) =>
      VideoTag.fromJson(json.decode(str));

  /// 将VideoTag对象转换为JSON字符串
  String toRawJson() => json.encode(toJson());

  @override
  String toString() {
    return 'VideoTag(tagId: $tagId, tagName: $tagName, tagType: $tagType, musicId: $musicId, jumpUrl: $jumpUrl)';
  }
}
