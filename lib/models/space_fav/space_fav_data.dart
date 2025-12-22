/// 用户空间收藏数据模型
class SpaceFavData {
  int? id;
  String? name;
  MediaListResponse? mediaListResponse;
  String? uri;

  SpaceFavData({this.id, this.name, this.mediaListResponse, this.uri});

  factory SpaceFavData.fromJson(Map<String, dynamic> json) => SpaceFavData(
        id: json['id'] as int?,
        name: json['name'] as String?,
        mediaListResponse: json['mediaListResponse'] == null
            ? null
            : MediaListResponse.fromJson(
                json['mediaListResponse'] as Map<String, dynamic>,
              ),
        uri: json['uri'] as String?,
      );
}

class MediaListResponse {
  int? count;
  List<SpaceFavItemModel>? list;
  bool? hasMore;

  MediaListResponse({this.count, this.list, this.hasMore});

  factory MediaListResponse.fromJson(Map<String, dynamic> json) {
    return MediaListResponse(
      count: json['count'] as int?,
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => SpaceFavItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool?,
    );
  }
}

class SpaceFavItemModel {
  int? id;
  int? mediaId;
  int? count;
  int? isPublic;
  int? fid;
  int? mid;
  int? attr;
  String? attrDesc;
  String? title;
  String? cover;
  SpaceFavUpper? upper;
  int? coverType;
  String? intro;
  int? ctime;
  int? mtime;
  int? state;
  int? favState;
  int? mediaCount;
  int? viewCount;
  int? vt;
  bool? isTop;
  dynamic recentFav;
  int? playSwitch;
  int? type;
  String? link;
  String? bvid;

  SpaceFavItemModel({
    this.id,
    this.mediaId,
    this.count,
    this.isPublic,
    this.fid,
    this.mid,
    this.attr,
    this.attrDesc,
    this.title,
    this.cover,
    this.upper,
    this.coverType,
    this.intro,
    this.ctime,
    this.mtime,
    this.state,
    this.favState,
    this.mediaCount,
    this.viewCount,
    this.vt,
    this.isTop,
    this.recentFav,
    this.playSwitch,
    this.type,
    this.link,
    this.bvid,
  });

  factory SpaceFavItemModel.fromJson(Map<String, dynamic> json) =>
      SpaceFavItemModel(
        id: json['id'] as int?,
        mediaId: json['media_id'] as int?,
        count: json['count'] as int?,
        isPublic: json['is_public'] as int?,
        fid: json['fid'] as int?,
        mid: json['mid'] as int?,
        attr: json['attr'] as int?,
        attrDesc: json['attr_desc'] as String?,
        title: json['title'] as String?,
        cover: json['cover'] as String?,
        upper: json['upper'] == null
            ? null
            : SpaceFavUpper.fromJson(json['upper'] as Map<String, dynamic>),
        coverType: json['cover_type'] as int?,
        intro: json['intro'] as String?,
        ctime: json['ctime'] as int?,
        mtime: json['mtime'] as int?,
        state: json['state'] as int?,
        favState: json['fav_state'] as int?,
        mediaCount: json['media_count'] as int?,
        viewCount: json['view_count'] as int?,
        vt: json['vt'] as int?,
        isTop: json['is_top'] as bool?,
        recentFav: json['recent_fav'],
        playSwitch: json['play_switch'] as int?,
        type: json['type'] as int?,
        link: json['link'] as String?,
        bvid: json['bvid'] as String?,
      );
}

class SpaceFavUpper {
  int? mid;
  String? name;
  String? face;

  SpaceFavUpper({this.mid, this.name, this.face});

  factory SpaceFavUpper.fromJson(Map<String, dynamic> json) => SpaceFavUpper(
        mid: json['mid'] as int?,
        name: json['name'] as String?,
        face: json['face'] as String?,
      );
}
