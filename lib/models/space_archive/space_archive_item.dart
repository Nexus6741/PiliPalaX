/// 用户空间投稿视频项模型
/// 参考PiliPlus的SpaceArchiveItem
class SpaceArchiveItem {
  String title;
  String? subtitle;
  String? tname;
  String? cover;
  String? coverIcon;
  String? uri;
  String? param;
  String? goto;
  String? length;
  int duration;
  bool? isPopular;
  bool? isSteins;
  bool? isUgcpay;
  bool? isCooperation;
  bool? isPgc;
  bool? isLivePlayback;
  bool? isPugv;
  bool? isFold;
  bool? isOneself;
  int? ctime;
  int? ugcPay;
  bool? state;
  String? bvid;
  int? videos;
  int? cid;
  int? iconType;
  String? publishTimeText;
  SpaceArchiveStat stat;
  String? author;
  String? styles;
  String? label;

  SpaceArchiveItem({
    required this.title,
    this.subtitle,
    this.tname,
    this.cover,
    this.coverIcon,
    this.uri,
    this.param,
    this.goto,
    this.length,
    this.duration = 0,
    this.isPopular,
    this.isSteins,
    this.isUgcpay,
    this.isCooperation,
    this.isPgc,
    this.isLivePlayback,
    this.isPugv,
    this.isFold,
    this.isOneself,
    this.ctime,
    this.ugcPay,
    this.state,
    this.bvid,
    this.videos,
    this.cid,
    this.iconType,
    this.publishTimeText,
    required this.stat,
    this.author,
    this.styles,
    this.label,
  });

  factory SpaceArchiveItem.fromJson(Map<String, dynamic> json) {
    return SpaceArchiveItem(
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      tname: json['tname'],
      cover: json['cover'],
      coverIcon: json['cover_icon'],
      uri: json['uri'],
      param: json['param'],
      goto: json['goto'],
      length: json['length'],
      duration: json['duration'] ?? 0,
      isPopular: json['is_popular'],
      isSteins: json['is_steins'],
      isUgcpay: json['is_ugcpay'],
      isCooperation: json['is_cooperation'],
      isPgc: json['is_pgc'],
      isLivePlayback: json['is_live_playback'],
      isPugv: json['is_pugv'],
      isFold: json['is_fold'],
      isOneself: json['is_oneself'],
      ctime: json['ctime'],
      ugcPay: json['ugc_pay'],
      state: json['state'],
      bvid: json['bvid'],
      videos: json['videos'],
      cid: json['first_cid'],
      iconType: json['icon_type'],
      publishTimeText: json['publish_time_text'],
      stat: SpaceArchiveStat.fromJson(json),
      author: json['author'],
      styles: json['styles'],
      label: json['label'],
    );
  }

  /// 获取aid (从param解析)
  int? get aid {
    if (param != null) {
      return int.tryParse(param!);
    }
    return null;
  }
}

/// 播放统计
class SpaceArchiveStat {
  int? view;
  int? danmu;

  SpaceArchiveStat({this.view, this.danmu});

  factory SpaceArchiveStat.fromJson(Map<String, dynamic> json) {
    return SpaceArchiveStat(
      view: json['play'],
      danmu: json['danmaku'],
    );
  }
}
