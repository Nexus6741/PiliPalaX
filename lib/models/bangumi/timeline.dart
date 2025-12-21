// 追番时间表模型
class TimelineModel {
  String? date;
  int? dateTs;
  int? dayOfWeek;
  List<TimelineEpisode>? episodes;
  int? isToday;

  TimelineModel({
    this.date,
    this.dateTs,
    this.dayOfWeek,
    this.episodes,
    this.isToday,
  });

  factory TimelineModel.fromJson(Map<String, dynamic> json) {
    return TimelineModel(
      date: json['date'] as String?,
      dateTs: json['date_ts'] as int?,
      dayOfWeek: json['day_of_week'] as int?,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => TimelineEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
      isToday: json['is_today'] as int?,
    );
  }

  // 合并同一天的番剧（国创和番剧）
  void addAll(TimelineModel other) {
    if (dateTs == other.dateTs) {
      if (other.episodes != null) {
        episodes ??= <TimelineEpisode>[];
        episodes!.addAll(other.episodes!);
      }
    }
  }
}

class TimelineEpisode {
  String? cover;
  int? delay;
  int? delayId;
  String? delayIndex;
  String? delayReason;
  String? epCover;
  int? episodeId;
  int? follow;
  String? follows;
  String? plays;
  String? pubIndex;
  String? pubTime;
  int? pubTs;
  int? published;
  int? seasonId;
  String? squareCover;
  String? title;

  TimelineEpisode({
    this.cover,
    this.delay,
    this.delayId,
    this.delayIndex,
    this.delayReason,
    this.epCover,
    this.episodeId,
    this.follow,
    this.follows,
    this.plays,
    this.pubIndex,
    this.pubTime,
    this.pubTs,
    this.published,
    this.seasonId,
    this.squareCover,
    this.title,
  });

  factory TimelineEpisode.fromJson(Map<String, dynamic> json) {
    return TimelineEpisode(
      cover: json['cover'] as String?,
      delay: json['delay'] as int?,
      delayId: json['delay_id'] as int?,
      delayIndex: json['delay_index'] as String?,
      delayReason: json['delay_reason'] as String?,
      epCover: json['ep_cover'] as String?,
      episodeId: json['episode_id'] as int?,
      follow: json['follow'] as int?,
      follows: json['follows'] as String?,
      plays: json['plays'] as String?,
      pubIndex: json['pub_index'] as String?,
      pubTime: json['pub_time'] as String?,
      pubTs: json['pub_ts'] as int?,
      published: json['published'] as int?,
      seasonId: json['season_id'] as int?,
      squareCover: json['square_cover'] as String?,
      title: json['title'] as String?,
    );
  }
}
