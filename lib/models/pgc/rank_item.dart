class PgcRankItem {
  PgcRankItem({
    this.badge,
    this.badgeInfo,
    this.badgeType,
    this.cover,
    this.newEp,
    this.rank,
    this.rating,
    this.seasonId,
    this.seasonType,
    this.stat,
    this.title,
    this.url,
  });

  String? badge;
  BadgeInfo? badgeInfo;
  int? badgeType;
  String? cover;
  NewEp? newEp;
  int? rank;
  String? rating;
  int? seasonId;
  int? seasonType;
  Stat? stat;
  String? title;
  String? url;

  factory PgcRankItem.fromJson(Map<String, dynamic> json) => PgcRankItem(
        badge: json['badge'],
        badgeInfo: json['badge_info'] != null
            ? BadgeInfo.fromJson(json['badge_info'])
            : null,
        badgeType: json['badge_type'],
        cover: json['cover'],
        newEp: json['new_ep'] != null ? NewEp.fromJson(json['new_ep']) : null,
        rank: json['rank'],
        rating: json['rating'],
        seasonId: json['season_id'],
        seasonType: json['season_type'],
        stat: json['stat'] != null ? Stat.fromJson(json['stat']) : null,
        title: json['title'],
        url: json['url'],
      );

  Map<String, dynamic> toJson() => {
        'badge': badge,
        'badge_info': badgeInfo?.toJson(),
        'badge_type': badgeType,
        'cover': cover,
        'new_ep': newEp?.toJson(),
        'rank': rank,
        'rating': rating,
        'season_id': seasonId,
        'season_type': seasonType,
        'stat': stat?.toJson(),
        'title': title,
        'url': url,
      };
}

class BadgeInfo {
  BadgeInfo({
    this.bgColor,
    this.bgColorNight,
    this.text,
  });

  String? bgColor;
  String? bgColorNight;
  String? text;

  factory BadgeInfo.fromJson(Map<String, dynamic> json) => BadgeInfo(
        bgColor: json['bg_color'],
        bgColorNight: json['bg_color_night'],
        text: json['text'],
      );

  Map<String, dynamic> toJson() => {
        'bg_color': bgColor,
        'bg_color_night': bgColorNight,
        'text': text,
      };
}

class NewEp {
  NewEp({
    this.cover,
    this.id,
    this.indexShow,
  });

  String? cover;
  int? id;
  String? indexShow;

  factory NewEp.fromJson(Map<String, dynamic> json) => NewEp(
        cover: json['cover'],
        id: json['id'],
        indexShow: json['index_show'],
      );

  Map<String, dynamic> toJson() => {
        'cover': cover,
        'id': id,
        'index_show': indexShow,
      };
}

class Stat {
  Stat({
    this.danmaku,
    this.follow,
    this.series,
    this.seriesFollow,
    this.view,
  });

  int? danmaku;
  int? follow;
  int? series;
  int? seriesFollow;
  int? view;

  factory Stat.fromJson(Map<String, dynamic> json) => Stat(
        danmaku: json['danmaku'],
        follow: json['follow'],
        series: json['series'],
        seriesFollow: json['series_follow'],
        view: json['view'],
      );

  Map<String, dynamic> toJson() => {
        'danmaku': danmaku,
        'follow': follow,
        'series': series,
        'series_follow': seriesFollow,
        'view': view,
      };
}
