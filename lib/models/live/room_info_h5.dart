import 'package:PiliPalaX/models/live/live_feed_index/watched_show.dart';
import 'package:PiliPalaX/models/live_new/live_room_info_h5/like_info_v3.dart';

class RoomInfoH5Model {
  int? code;
  String? msg;
  String? message;
  RoomInfoH5Data? data;

  RoomInfoH5Model({this.code, this.msg, this.message, this.data});

  RoomInfoH5Model.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    msg = json['msg'];
    message = json['message'];
    data = json['data'] != null ? RoomInfoH5Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['msg'] = msg;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class RoomInfoH5Data {
  RoomInfo? roomInfo;
  AnchorInfo? anchorInfo;
  List<dynamic>? newsInfo;
  int? rank;
  int? silentStatus;
  int? switchInfo;
  List<dynamic>? recordSwitchInfo;
  int? fanClubShow;
  WatchedShow? watchedShow;
  LikeInfoV3? likeInfoV3;

  RoomInfoH5Data({
    this.roomInfo,
    this.anchorInfo,
    this.newsInfo,
    this.rank,
    this.silentStatus,
    this.switchInfo,
    this.recordSwitchInfo,
    this.fanClubShow,
  });

  RoomInfoH5Data.fromJson(Map<String, dynamic> json) {
    roomInfo =
        json['room_info'] != null ? RoomInfo.fromJson(json['room_info']) : null;
    anchorInfo = json['anchor_info'] != null
        ? AnchorInfo.fromJson(json['anchor_info'])
        : null;
    if (json['news_info'] != null) {
      newsInfo = <dynamic>[];
      json['news_info'].forEach((v) {
        newsInfo!.add(v);
      });
    }
    rank = json['rank'];
    silentStatus = json['silent_status'];
    switchInfo = json['switch_info'];
    if (json['record_switch_info'] != null) {
      recordSwitchInfo = <dynamic>[];
      json['record_switch_info'].forEach((v) {
        recordSwitchInfo!.add(v);
      });
    }
    fanClubShow = json['fan_club_show'];
    watchedShow = json['watched_show'] != null
        ? WatchedShow.fromJson(json['watched_show'])
        : null;
    likeInfoV3 = json['like_info_v3'] != null
        ? LikeInfoV3.fromJson(json['like_info_v3'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (roomInfo != null) {
      data['room_info'] = roomInfo!.toJson();
    }
    if (anchorInfo != null) {
      data['anchor_info'] = anchorInfo!.toJson();
    }
    if (newsInfo != null) {
      data['news_info'] = newsInfo!.map((v) => v.toJson()).toList();
    }
    data['rank'] = rank;
    data['silent_status'] = silentStatus;
    data['switch_info'] = switchInfo;
    if (recordSwitchInfo != null) {
      data['record_switch_info'] =
          recordSwitchInfo!.map((v) => v.toJson()).toList();
    }
    data['fan_club_show'] = fanClubShow;
    if (watchedShow != null) {
      data['watched_show'] = {'text_large': watchedShow!.textLarge};
    }
    if (likeInfoV3 != null) {
      data['like_info_v3'] = likeInfoV3!.toJson();
    }
    return data;
  }
}

class RoomInfo {
  int? uid;
  int? roomId;
  int? shortId;
  String? title;
  String? cover;
  String? tags;
  String? background;
  String? description;
  int? liveStatus;
  int? liveStartTime;
  int? liveScreenType;
  int? lockStatus;
  int? lockTime;
  int? hiddenStatus;
  int? hiddenTime;
  int? areaId;
  String? areaName;
  int? parentAreaId;
  String? parentAreaName;
  String? keyframe;
  int? specialType;
  String? upSession;
  int? pkStatus;
  int? isStudio;
  Pendants? pendants;
  int? onVoiceJoin;
  int? online;
  String? roomType;
  Map<String, dynamic>? subSessionKey;
  String? liveId;
  int? liveIdStr;
  int? vodIsStop;
  int? liveRoomMode;

  RoomInfo({
    this.uid,
    this.roomId,
    this.shortId,
    this.title,
    this.cover,
    this.tags,
    this.background,
    this.description,
    this.liveStatus,
    this.liveStartTime,
    this.liveScreenType,
    this.lockStatus,
    this.lockTime,
    this.hiddenStatus,
    this.hiddenTime,
    this.areaId,
    this.areaName,
    this.parentAreaId,
    this.parentAreaName,
    this.keyframe,
    this.specialType,
    this.upSession,
    this.pkStatus,
    this.isStudio,
    this.pendants,
    this.onVoiceJoin,
    this.online,
    this.roomType,
    this.subSessionKey,
    this.liveId,
    this.liveIdStr,
    this.vodIsStop,
    this.liveRoomMode,
  });

  RoomInfo.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    roomId = json['room_id'];
    shortId = json['short_id'];
    title = json['title'];
    cover = json['cover'];
    tags = json['tags'];
    background = json['background'];
    description = json['description'];
    liveStatus = json['live_status'];
    liveStartTime = json['live_start_time'];
    liveScreenType = json['live_screen_type'];
    lockStatus = json['lock_status'];
    lockTime = json['lock_time'];
    hiddenStatus = json['hidden_status'];
    hiddenTime = json['hidden_time'];
    areaId = json['area_id'];
    areaName = json['area_name'];
    parentAreaId = json['parent_area_id'];
    parentAreaName = json['parent_area_name'];
    keyframe = json['keyframe'];
    specialType = json['special_type'];
    upSession = json['up_session'];
    pkStatus = json['pk_status'];
    isStudio = json['is_studio'];
    pendants =
        json['pendants'] != null ? Pendants.fromJson(json['pendants']) : null;
    onVoiceJoin = json['on_voice_join'];
    online = json['online'];
    roomType = json['room_type']?.toString();
    subSessionKey = json['sub_session_key'] is Map<String, dynamic>
        ? json['sub_session_key']
        : null;
    liveId = json['live_id'];
    liveIdStr = json['live_id_str'];
    vodIsStop = json['vod_is_stop'];
    liveRoomMode = json['live_room_mode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uid'] = uid;
    data['room_id'] = roomId;
    data['short_id'] = shortId;
    data['title'] = title;
    data['cover'] = cover;
    data['tags'] = tags;
    data['background'] = background;
    data['description'] = description;
    data['live_status'] = liveStatus;
    data['live_start_time'] = liveStartTime;
    data['live_screen_type'] = liveScreenType;
    data['lock_status'] = lockStatus;
    data['lock_time'] = lockTime;
    data['hidden_status'] = hiddenStatus;
    data['hidden_time'] = hiddenTime;
    data['area_id'] = areaId;
    data['area_name'] = areaName;
    data['parent_area_id'] = parentAreaId;
    data['parent_area_name'] = parentAreaName;
    data['keyframe'] = keyframe;
    data['special_type'] = specialType;
    data['up_session'] = upSession;
    data['pk_status'] = pkStatus;
    data['is_studio'] = isStudio;
    if (pendants != null) {
      data['pendants'] = pendants!.toJson();
    }
    data['on_voice_join'] = onVoiceJoin;
    data['online'] = online;
    data['room_type'] = roomType;
    data['sub_session_key'] = subSessionKey;
    data['live_id'] = liveId;
    data['live_id_str'] = liveIdStr;
    data['vod_is_stop'] = vodIsStop;
    data['live_room_mode'] = liveRoomMode;
    return data;
  }
}

class Pendants {
  Frame? frame;

  Pendants({this.frame});

  Pendants.fromJson(Map<String, dynamic> json) {
    frame = json['frame'] != null ? Frame.fromJson(json['frame']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (frame != null) {
      data['frame'] = frame!.toJson();
    }
    return data;
  }
}

class Frame {
  String? name;
  String? value;
  String? desc;

  Frame({this.name, this.value, this.desc});

  Frame.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    value = json['value'];
    desc = json['desc'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['value'] = value;
    data['desc'] = desc;
    return data;
  }
}

class AnchorInfo {
  BaseInfo? baseInfo;
  LiveInfo? liveInfo;
  RelationInfo? relationInfo;
  MedalInfo? medalInfo;
  dynamic giftInfo;

  AnchorInfo({
    this.baseInfo,
    this.liveInfo,
    this.relationInfo,
    this.medalInfo,
    this.giftInfo,
  });

  AnchorInfo.fromJson(Map<String, dynamic> json) {
    baseInfo =
        json['base_info'] != null ? BaseInfo.fromJson(json['base_info']) : null;
    liveInfo =
        json['live_info'] != null ? LiveInfo.fromJson(json['live_info']) : null;
    relationInfo = json['relation_info'] != null
        ? RelationInfo.fromJson(json['relation_info'])
        : null;
    medalInfo = json['medal_info'] != null
        ? MedalInfo.fromJson(json['medal_info'])
        : null;
    giftInfo = json['gift_info'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (baseInfo != null) {
      data['base_info'] = baseInfo!.toJson();
    }
    if (liveInfo != null) {
      data['live_info'] = liveInfo!.toJson();
    }
    if (relationInfo != null) {
      data['relation_info'] = relationInfo!.toJson();
    }
    if (medalInfo != null) {
      data['medal_info'] = medalInfo!.toJson();
    }
    data['gift_info'] = giftInfo;
    return data;
  }
}

class BaseInfo {
  String? uname;
  String? face;
  String? gender;
  OfficialInfo? officialInfo;

  BaseInfo({this.uname, this.face, this.gender, this.officialInfo});

  BaseInfo.fromJson(Map<String, dynamic> json) {
    uname = json['uname'];
    face = json['face'];
    gender = json['gender'];
    officialInfo = json['official_info'] != null
        ? OfficialInfo.fromJson(json['official_info'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uname'] = uname;
    data['face'] = face;
    data['gender'] = gender;
    if (officialInfo != null) {
      data['official_info'] = officialInfo!.toJson();
    }
    return data;
  }
}

class OfficialInfo {
  int? role;
  String? title;
  String? desc;
  int? isOfficial;

  OfficialInfo({this.role, this.title, this.desc, this.isOfficial});

  OfficialInfo.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    title = json['title'];
    desc = json['desc'];
    isOfficial = json['is_official'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['role'] = role;
    data['title'] = title;
    data['desc'] = desc;
    data['is_official'] = isOfficial;
    return data;
  }
}

class LiveInfo {
  int? level;
  int? levelColor;
  int? score;
  int? upgradeScore;
  int? current;
  String? nextLevel;
  int? rank;
  int? yearRank;
  int? areaRank;

  LiveInfo({
    this.level,
    this.levelColor,
    this.score,
    this.upgradeScore,
    this.current,
    this.nextLevel,
    this.rank,
    this.yearRank,
    this.areaRank,
  });

  LiveInfo.fromJson(Map<String, dynamic> json) {
    level = json['level'];
    levelColor = json['level_color'];
    score = json['score'];
    upgradeScore = json['upgrade_score'];
    current = json['current'];
    nextLevel = json['next_level'].toString();
    rank = json['rank'];
    yearRank = json['year_rank'];
    areaRank = json['area_rank'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['level'] = level;
    data['level_color'] = levelColor;
    data['score'] = score;
    data['upgrade_score'] = upgradeScore;
    data['current'] = current;
    data['next_level'] = nextLevel;
    data['rank'] = rank;
    data['year_rank'] = yearRank;
    data['area_rank'] = areaRank;
    return data;
  }
}

class RelationInfo {
  int? attention;

  RelationInfo({this.attention});

  RelationInfo.fromJson(Map<String, dynamic> json) {
    attention = json['attention'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['attention'] = attention;
    return data;
  }
}

class MedalInfo {
  String? medalName;
  int? medalId;
  int? fansclub;

  MedalInfo({this.medalName, this.medalId, this.fansclub});

  MedalInfo.fromJson(Map<String, dynamic> json) {
    medalName = json['medal_name'];
    medalId = json['medal_id'];
    fansclub = json['fansclub'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['medal_name'] = medalName;
    data['medal_id'] = medalId;
    data['fansclub'] = fansclub;
    return data;
  }
}
