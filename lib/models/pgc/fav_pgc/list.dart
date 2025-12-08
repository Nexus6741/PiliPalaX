import 'package:PiliPalaX/models/pgc/fav_pgc/rating.dart';
import 'package:PiliPalaX/models/pgc/fav_pgc/new_ep.dart';
import 'package:PiliPalaX/models/pgc/fav_pgc/stat.dart';
import 'package:PiliPalaX/models/pgc/fav_pgc/rights.dart';

class FavPgcItemModel {
  int? seasonId;
  int? mediaId;
  int? seasonType;
  String? seasonTypeName;
  String? title;
  String? cover;
  int? totalCount;
  int? isFinish;
  int? isStarted;
  int? isPlay;
  String? badge;
  int? badgeType;
  Rights? rights;
  Stat? stat;
  NewEp? newEp;
  Rating? rating;
  String? squareCover;
  int? seasonStatus;
  String? seasonTitle;
  String? badgeEp;
  int? mediaAttr;
  int? seasonAttr;
  String? evaluate;
  String? subtitle;
  int? firstEp;
  int? canWatch;
  String? url;
  String? renewalTime;
  int? formalEpCount;
  String? shortUrl;
  String? seasonVersion;
  String? horizontalCover169;
  String? horizontalCover1610;
  String? subtitle14;
  int? viewableCrowdType;
  String? summary;
  List<String>? styles;
  int? followStatus;
  int? isNew;
  String? progress;
  bool? bothFollow;
  String? subtitle25;

  FavPgcItemModel({
    this.seasonId,
    this.mediaId,
    this.seasonType,
    this.seasonTypeName,
    this.title,
    this.cover,
    this.totalCount,
    this.isFinish,
    this.isStarted,
    this.isPlay,
    this.badge,
    this.badgeType,
    this.rights,
    this.stat,
    this.newEp,
    this.rating,
    this.squareCover,
    this.seasonStatus,
    this.seasonTitle,
    this.badgeEp,
    this.mediaAttr,
    this.seasonAttr,
    this.evaluate,
    this.subtitle,
    this.firstEp,
    this.canWatch,
    this.url,
    this.renewalTime,
    this.formalEpCount,
    this.shortUrl,
    this.seasonVersion,
    this.horizontalCover169,
    this.horizontalCover1610,
    this.subtitle14,
    this.viewableCrowdType,
    this.summary,
    this.styles,
    this.followStatus,
    this.isNew,
    this.progress,
    this.bothFollow,
    this.subtitle25,
  });

  factory FavPgcItemModel.fromJson(Map<String, dynamic> json) =>
      FavPgcItemModel(
        seasonId: json['season_id'] as int?,
        mediaId: json['media_id'] as int?,
        seasonType: json['season_type'] as int?,
        seasonTypeName: json['season_type_name'] as String?,
        title: json['title'] as String?,
        cover: json['cover'] as String?,
        totalCount: json['total_count'] as int?,
        isFinish: json['is_finish'] as int?,
        isStarted: json['is_started'] as int?,
        isPlay: json['is_play'] as int?,
        badge: json['badge'] as String?,
        badgeType: json['badge_type'] as int?,
        rights: json['rights'] == null
            ? null
            : Rights.fromJson(json['rights'] as Map<String, dynamic>),
        stat: json['stat'] == null
            ? null
            : Stat.fromJson(json['stat'] as Map<String, dynamic>),
        newEp: json['new_ep'] == null
            ? null
            : NewEp.fromJson(json['new_ep'] as Map<String, dynamic>),
        rating: json['rating'] == null
            ? null
            : Rating.fromJson(json['rating'] as Map<String, dynamic>),
        squareCover: json['square_cover'] as String?,
        seasonStatus: json['season_status'] as int?,
        seasonTitle: json['season_title'] as String?,
        badgeEp: json['badge_ep'] as String?,
        mediaAttr: json['media_attr'] as int?,
        seasonAttr: json['season_attr'] as int?,
        evaluate: json['evaluate'] as String?,
        subtitle: json['subtitle'] as String?,
        firstEp: json['first_ep'] as int?,
        canWatch: json['can_watch'] as int?,
        url: json['url'] as String?,
        renewalTime: json['renewal_time'] as String?,
        formalEpCount: json['formal_ep_count'] as int?,
        shortUrl: json['short_url'] as String?,
        seasonVersion: json['season_version'] as String?,
        horizontalCover169: json['horizontal_cover_16_9'] as String?,
        horizontalCover1610: json['horizontal_cover_16_10'] as String?,
        subtitle14: json['subtitle_14'] as String?,
        viewableCrowdType: json['viewable_crowd_type'] as int?,
        summary: json['summary'] as String?,
        styles: (json['styles'] as List?)?.cast<String>(),
        followStatus: json['follow_status'] as int?,
        isNew: json['is_new'] as int?,
        progress: json['progress'] == '' ? null : json['progress'] as String?,
        bothFollow: json['both_follow'] as bool?,
        subtitle25: json['subtitle_25'] as String?,
      );
}
