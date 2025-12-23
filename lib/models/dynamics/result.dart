import 'dart:convert';

// 辅助函数：安全地将动态类型转换为int
int? _safeToInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

class DynamicsDataModel {
  DynamicsDataModel({
    this.hasMore,
    this.items,
    this.offset,
  });
  bool? hasMore;
  List<DynamicItemModel>? items;
  String? offset;

  DynamicsDataModel.fromJson(Map<String, dynamic> json) {
    try {
      hasMore = json['has_more'] ?? false;
      items = json['items'] != null
          ? (json['items'] as List)
              .map<DynamicItemModel>((e) => DynamicItemModel.fromJson(e))
              .toList()
          : [];
      offset = json['offset'] ?? '';
    } catch (e) {
      hasMore = false;
      items = [];
      offset = '';
    }
  }
}

// 单个动态
class DynamicItemModel {
  DynamicItemModel({
    this.basic,
    this.idStr,
    this.modules,
    this.orig,
    this.type,
    this.visible,
  });

  Map? basic;
  String? idStr;
  ItemModulesModel? modules;
  ItemOrigModel? orig;
  String? type;
  bool? visible;

  DynamicItemModel.fromJson(Map<String, dynamic> json) {
    basic = json['basic'];
    idStr = json['id_str'];
    modules = ItemModulesModel.fromJson(json['modules']);
    orig = json['orig'] != null ? ItemOrigModel.fromJson(json['orig']) : null;
    type = json['type'];
    visible = json['visible'];
  }
}

class ItemOrigModel {
  ItemOrigModel({
    this.basic,
    this.isStr,
    this.modules,
    this.type,
    this.visible,
  });

  Map? basic;
  String? isStr;
  ItemModulesModel? modules;
  String? type;
  bool? visible;

  ItemOrigModel.fromJson(Map<String, dynamic> json) {
    basic = json['basic'];
    isStr = json['is_str'];
    modules = ItemModulesModel.fromJson(json['modules']);
    type = json['type'];
    visible = json['visible'];
  }
}

// 单个动态详情
class ItemModulesModel {
  ItemModulesModel({
    this.moduleAuthor,
    this.moduleDynamic,
    // this.moduleInter,
    this.moduleStat,
    this.moduleTag,
  });

  ModuleAuthorModel? moduleAuthor;
  ModuleDynamicModel? moduleDynamic;
  // ModuleInterModel? moduleInter;
  ModuleStatModel? moduleStat;
  Map? moduleTag;

  ItemModulesModel.fromJson(Map<String, dynamic> json) {
    moduleAuthor = json['module_author'] != null
        ? ModuleAuthorModel.fromJson(json['module_author'])
        : null;
    moduleDynamic = json['module_dynamic'] != null
        ? ModuleDynamicModel.fromJson(json['module_dynamic'])
        : null;
    // moduleInter = ModuleInterModel.fromJson(json['module_interaction']);
    moduleStat = json['module_stat'] != null
        ? ModuleStatModel.fromJson(json['module_stat'])
        : null;
    moduleTag = json['module_tag'];
  }
}

// 单个动态详情 - 作者信息
class ModuleAuthorModel {
  ModuleAuthorModel({
    // this.avatar,
    // this.decorate,
    this.face,
    this.following,
    this.jumpUrl,
    this.label,
    this.mid,
    this.name,
    // this.officialVerify,
    // this.pandant,
    this.pubAction,
    // this.pubLocationText,
    this.pubTime,
    this.pubTs,
    this.type,
    this.vip,
  });

  String? face;
  bool? following;
  String? jumpUrl;
  String? label;
  int? mid;
  String? name;
  String? pubAction;
  String? pubTime;
  int? pubTs;
  String? type;
  Map? vip;

  ModuleAuthorModel.fromJson(Map<String, dynamic> json) {
    face = json['face'];
    following = json['following'];
    jumpUrl = json['jump_url'];
    label = json['label'];
    mid = _safeToInt(json['mid']);
    name = json['name'];
    pubAction = json['pub_action'];
    pubTime = json['pub_time'];
    pubTs = _safeToInt(json['pub_ts']);
    type = json['type'];
    vip = json['vip'];
  }
}

// 单个动态详情 - 动态信息
class ModuleDynamicModel {
  ModuleDynamicModel({
    this.additional,
    this.desc,
    this.major,
    this.topic,
  });

  DynamicAddModel? additional;
  DynamicDescModel? desc;
  DynamicMajorModel? major;
  DynamicTopicModel? topic;

  ModuleDynamicModel.fromJson(Map<String, dynamic> json) {
    additional = json['additional'] != null
        ? DynamicAddModel.fromJson(json['additional'])
        : null;
    desc =
        json['desc'] != null ? DynamicDescModel.fromJson(json['desc']) : null;
    if (json['major'] != null) {
      major = DynamicMajorModel.fromJson(json['major']);
    }
    topic = json['topic'] != null
        ? DynamicTopicModel.fromJson(json['topic'])
        : null;
  }
}

// 单个动态详情 - 评论？信息
// class ModuleInterModel {
//   ModuleInterModel({

//   });

//   ModuleInterModel.fromJson(Map<String, dynamic> json) {

//   }
// }
class DynamicAddModel {
  DynamicAddModel({
    this.type,
    this.vote,
    this.ugc,
    this.reserve,
    this.goods,
    this.common,
    this.match,
  });

  String? type;
  Vote? vote;
  Ugc? ugc;
  Reserve? reserve;
  Good? goods;
  AddCommon? common;
  AddMatch? match;

  DynamicAddModel.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    vote = json['vote'] != null ? Vote.fromJson(json['vote']) : null;
    ugc = json['ugc'] != null ? Ugc.fromJson(json['ugc']) : null;
    reserve =
        json['reserve'] != null ? Reserve.fromJson(json['reserve']) : null;
    goods = json['goods'] != null ? Good.fromJson(json['goods']) : null;
    common = json['common'] != null ? AddCommon.fromJson(json['common']) : null;
    match = json['match'] != null ? AddMatch.fromJson(json['match']) : null;
  }
}

class Vote {
  Vote({
    this.choiceCnt,
    this.defaultShare,
    this.share,
    this.endTime,
    this.joinNum,
    this.status,
    this.type,
    this.uid,
    this.voteId,
  });

  int? choiceCnt;
  String? share;
  int? defaultShare;
  int? endTime;
  int? joinNum;
  int? status;
  int? type;
  int? uid;
  int? voteId;

  Vote.fromJson(Map<String, dynamic> json) {
    choiceCnt = _safeToInt(json['choice_cnt']);
    share = json['share'];
    defaultShare = _safeToInt(json['default_share']);
    endTime = _safeToInt(json['end_time']);
    joinNum = _safeToInt(json['join_num']);
    status = _safeToInt(json['status']);
    type = _safeToInt(json['type']);
    uid = _safeToInt(json['uid']);
    voteId = _safeToInt(json['vote_id']);
  }
}

class Ugc {
  Ugc({
    this.cover,
    this.descSecond,
    this.duration,
    this.headText,
    this.idStr,
    this.jumpUrl,
    this.multiLine,
    this.title,
  });

  String? cover;
  String? descSecond;
  String? duration;
  String? headText;
  String? idStr;
  String? jumpUrl;
  bool? multiLine;
  String? title;

  Ugc.fromJson(Map<String, dynamic> json) {
    cover = json['cover'];
    descSecond = json['desc_second'];
    duration = json['duration'];
    headText = json['head_text'];
    idStr = json['id_str'];
    jumpUrl = json['jump_url'];
    multiLine = json['multi_line'];
    title = json['title'];
  }
}

class Reserve {
  Reserve({
    this.button,
    this.desc1,
    this.desc2,
    this.jumpUrl,
    this.reserveTotal,
    this.rid,
    this.state,
    this.stype,
    this.title,
    this.upMid,
  });

  Map? button;
  Map? desc1;
  Map? desc2;
  String? jumpUrl;
  int? reserveTotal;
  int? rid;
  int? state;
  int? stype;
  String? title;
  int? upMid;

  Reserve.fromJson(Map<String, dynamic> json) {
    button = json['button'];
    desc1 = json['desc1'];
    desc2 = json['desc2'];
    jumpUrl = json['jump_url'];
    reserveTotal = _safeToInt(json['reserve_total']);
    rid = _safeToInt(json['rid']);
    state = _safeToInt(json['state']);
    state = _safeToInt(json['state']);
    stype = _safeToInt(json['stype']);
    title = json['title'];
    upMid = _safeToInt(json['up_mid']);
  }
}

class Good {
  Good({
    this.headIcon,
    this.headText,
    this.items,
    this.jumpUrl,
  });

  String? headIcon;
  String? headText;
  List<GoodItem>? items;
  String? jumpUrl;

  Good.fromJson(Map<String, dynamic> json) {
    headIcon = json['head_icon'];
    headText = json['head_text'];
    items = json['items'].map<GoodItem>((e) => GoodItem.fromJson(e)).toList();
    jumpUrl = json['jump_url'];
  }
}

class GoodItem {
  GoodItem({
    this.brief,
    this.cover,
    this.id,
    this.jumpDesc,
    this.jumpUrl,
    this.name,
    this.price,
  });

  String? brief;
  String? cover;
  dynamic id;
  String? jumpDesc;
  String? jumpUrl;
  String? name;
  String? price;

  GoodItem.fromJson(Map<String, dynamic> json) {
    brief = json['brief'];
    cover = json['cover'];
    id = _safeToInt(json['id']);
    jumpDesc = json['jump_desc'];
    jumpUrl = json['jump_url'];
    name = json['name'];
    price = json['price'];
  }
}

class DynamicDescModel {
  DynamicDescModel({
    this.richTextNodes,
    this.text,
  });

  List<RichTextNodeItem>? richTextNodes;
  String? text;

  DynamicDescModel.fromJson(Map<String, dynamic> json) {
    richTextNodes = json['rich_text_nodes'] != null
        ? json['rich_text_nodes']
            .map<RichTextNodeItem>((e) => RichTextNodeItem.fromJson(e))
            .toList()
        : [];
    text = json['text'];
  }
}

//
class DynamicMajorModel {
  DynamicMajorModel({
    this.archive,
    this.draw,
    this.ugcSeason,
    this.opus,
    this.pgc,
    this.liveRcmd,
    this.live,
    this.none,
    this.type,
    this.courses,
  });

  DynamicArchiveModel? archive;
  DynamicDrawModel? draw;
  DynamicArchiveModel? ugcSeason;
  DynamicOpusModel? opus;
  DynamicArchiveModel? pgc;
  DynamicLiveModel? liveRcmd;
  DynamicLive2Model? live;
  DynamicNoneModel? none;
  DynamicCommonModel? common;
  // MAJOR_TYPE_DRAW 图片
  // MAJOR_TYPE_ARCHIVE 视频
  // MAJOR_TYPE_OPUS 图文/文章
  String? type;
  Map? courses;

  DynamicMajorModel.fromJson(Map<String, dynamic> json) {
    archive = json['archive'] != null
        ? DynamicArchiveModel.fromJson(json['archive'])
        : null;
    draw =
        json['draw'] != null ? DynamicDrawModel.fromJson(json['draw']) : null;
    ugcSeason = json['ugc_season'] != null
        ? DynamicArchiveModel.fromJson(json['ugc_season'])
        : null;
    opus =
        json['opus'] != null ? DynamicOpusModel.fromJson(json['opus']) : null;
    pgc =
        json['pgc'] != null ? DynamicArchiveModel.fromJson(json['pgc']) : null;
    liveRcmd = json['live_rcmd'] != null
        ? DynamicLiveModel.fromJson(json['live_rcmd'])
        : null;
    live =
        json['live'] != null ? DynamicLive2Model.fromJson(json['live']) : null;
    common = json['common'] != null
        ? DynamicCommonModel.fromJson(json['common'])
        : null;
    none =
        json['none'] != null ? DynamicNoneModel.fromJson(json['none']) : null;
    type = json['type'];
    courses = json['courses'] ?? {};
  }
}

class DynamicTopicModel {
  DynamicTopicModel({
    this.id,
    this.jumpUrl,
    this.name,
  });

  int? id;
  String? jumpUrl;
  String? name;

  DynamicTopicModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] is String ? int.tryParse(json['id']) : json['id'];
    jumpUrl = json['jump_url'];
    name = json['name'];
  }
}

class DynamicArchiveModel {
  DynamicArchiveModel({
    this.aid,
    this.badge,
    this.bvid,
    this.cover,
    this.desc,
    this.disablePreview,
    this.durationText,
    this.jumpUrl,
    this.stat,
    this.title,
    this.type,
    this.epid,
    this.seasonId,
  });

  int? aid;
  Map? badge;
  String? bvid;
  String? cover;
  String? desc;
  int? disablePreview;
  String? durationText;
  String? jumpUrl;
  Stat? stat;
  String? title;
  int? type;
  int? epid;
  int? seasonId;

  DynamicArchiveModel.fromJson(Map<String, dynamic> json) {
    aid = _safeToInt(json['aid']);
    badge = json['badge'];
    bvid = json['bvid'] ?? json['epid']?.toString() ?? ' ';
    cover = json['cover'];
    disablePreview = json['disable_preview'];
    durationText = json['duration_text'];
    jumpUrl = json['jump_url'];
    stat = json['stat'] != null ? Stat.fromJson(json['stat']) : null;
    title = json['title'];
    type = _safeToInt(json['type']);
    epid = _safeToInt(json['epid']);
    seasonId = _safeToInt(json['season_id']);
  }
}

class DynamicDrawModel {
  DynamicDrawModel({
    this.id,
    this.items,
  });

  int? id;
  List<DynamicDrawItemModel>? items;

  DynamicDrawModel.fromJson(Map<String, dynamic> json) {
    id = _safeToInt(json['id']);
    // ignore: prefer_null_aware_operators
    items = json['items'] != null
        ? json['items']
            .map<DynamicDrawItemModel>((e) => DynamicDrawItemModel.fromJson(e))
            .toList()
        : null;
  }
}

class DynamicOpusModel {
  DynamicOpusModel({
    this.jumpUrl,
    this.pics,
    this.summary,
    this.title,
  });

  String? jumpUrl;
  List<OpusPicsModel>? pics;
  SummaryModel? summary;
  String? title;
  DynamicOpusModel.fromJson(Map<String, dynamic> json) {
    jumpUrl = json['jump_url'];
    pics = json['pics'] != null
        ? json['pics']
            .map<OpusPicsModel>((e) => OpusPicsModel.fromJson(e))
            .toList()
        : [];
    summary =
        json['summary'] != null ? SummaryModel.fromJson(json['summary']) : null;
    title = json['title'];
  }
}

class DynamicCommonModel {
  DynamicCommonModel({
    this.badge,
    this.jumpUrl,
    this.cover,
    this.label,
    this.desc,
    this.id,
    this.sketchId,
    this.style,
    this.title,
  });

  Map? badge;
  String? jumpUrl;
  String? cover;
  String? label;
  String? desc;
  String? id;
  String? sketchId;
  int? style;
  String? title;

  DynamicCommonModel.fromJson(Map<String, dynamic> json) {
    badge = json['badge'];
    jumpUrl = json['jump_url'];
    cover = json['cover'];
    label = json['label'];
    desc = json['desc'];
    id = json['id'];
    sketchId = json['sketch_id'];
    style = json['style'];
    title = json['title'];
  }
}

class SummaryModel {
  SummaryModel({
    this.richTextNodes,
    this.text,
  });

  List<RichTextNodeItem>? richTextNodes;
  String? text;

  SummaryModel.fromJson(Map<String, dynamic> json) {
    richTextNodes = json['rich_text_nodes']
        .map<RichTextNodeItem>((e) => RichTextNodeItem.fromJson(e))
        .toList();
    text = json['text'];
  }
}

class RichTextNodeItem {
  RichTextNodeItem({
    this.emoji,
    this.origText,
    this.text,
    this.type,
    this.rid,
  });
  Emoji? emoji;
  String? origText;
  String? text;
  String? type;
  String? rid;

  RichTextNodeItem.fromJson(Map<String, dynamic> json) {
    emoji = json['emoji'] != null ? Emoji.fromJson(json['emoji']) : null;
    origText = json['orig_text'];
    text = json['text'];
    type = json['type'];
    rid = json['rid'];
  }
}

class Emoji {
  Emoji({
    this.iconUrl,
    this.size,
    this.text,
    this.type,
  });

  String? iconUrl;
  double? size;
  String? text;
  int? type;
  Emoji.fromJson(Map<String, dynamic> json) {
    iconUrl = json['icon_url'];
    size = json['size'] != null
        ? (json['size'] is num ? json['size'].toDouble() : null)
        : null;
    text = json['text'];
    type = json['type'] is String ? int.tryParse(json['type']) : json['type'];
  }
}

class DynamicNoneModel {
  DynamicNoneModel({
    this.tips,
  });
  String? tips;
  DynamicNoneModel.fromJson(Map<String, dynamic> json) {
    tips = json['tips'];
  }
}

class OpusPicsModel {
  OpusPicsModel({
    this.width,
    this.height,
    this.size,
    this.src,
    this.url,
  });

  int? width;
  int? height;
  int? size;
  String? src;
  String? url;

  OpusPicsModel.fromJson(Map<String, dynamic> json) {
    width = json['width'];
    height = json['height'];
    if (json['size'] is String) {
      size = int.tryParse(json['size']) ?? 0;
    } else {
      size = json['size'] != null ? json['size'].toInt() : 0;
    }
    src = json['src'];
    url = json['url'];
  }
}

class DynamicDrawItemModel {
  DynamicDrawItemModel({
    this.height,
    this.size,
    this.src,
    this.tags,
    this.width,
  });
  int? height;
  int? size;
  String? src;
  List? tags;
  int? width;
  DynamicDrawItemModel.fromJson(Map<String, dynamic> json) {
    height = json['height'];
    if (json['size'] is String) {
      size = int.tryParse(json['size']) ?? 0;
    } else {
      size = json['size'] != null ? json['size'].toInt() : 0;
    }
    src = json['src'];
    tags = json['tags'];
    width = json['width'];
  }
}

class DynamicLiveModel {
  DynamicLiveModel({
    this.content,
  });

  String? content;
  int? type;
  Map? livePlayInfo;
  int? uid;
  String? parentAreaName;
  int? roomId;
  String? liveId;
  int? liveStatus;
  String? cover;
  int? online;
  String? areaName;
  String? title;
  int? liveStartTime;
  Map? watchedShow;

  DynamicLiveModel.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    if (json['content'] != null) {
      Map<String, dynamic> data = jsonDecode(json['content']);

      type = data['type'];
      Map livePlayInfo = data['live_play_info'];
      uid = livePlayInfo['uid'] is String
          ? int.tryParse(livePlayInfo['uid'])
          : livePlayInfo['uid'];
      parentAreaName = livePlayInfo['parent_area_name'];
      roomId = livePlayInfo['room_id'] is String
          ? int.tryParse(livePlayInfo['room_id'])
          : livePlayInfo['room_id'];
      liveId = livePlayInfo['live_id'] is String
          ? livePlayInfo['live_id']
          : livePlayInfo['live_id'].toString();
      liveStatus = livePlayInfo['live_status'] is String
          ? int.tryParse(livePlayInfo['live_status'])
          : livePlayInfo['live_status'];
      cover = livePlayInfo['cover'];
      online = livePlayInfo['online'] is String
          ? int.tryParse(livePlayInfo['online'])
          : livePlayInfo['online'];
      areaName = livePlayInfo['area_name'];
      title = livePlayInfo['title'];
      liveStartTime = livePlayInfo['live_start_time'] is String
          ? int.tryParse(livePlayInfo['live_start_time'])
          : livePlayInfo['live_start_time'];
      watchedShow = livePlayInfo['watched_show'];
    }
  }
}

class DynamicLive2Model {
  DynamicLive2Model({
    this.badge,
    this.cover,
    this.descFirst,
    this.descSecond,
    this.id,
    this.jumpUrl,
    this.liveState,
    this.reserveType,
    this.title,
  });

  Map? badge;
  String? cover;
  String? descFirst;
  String? descSecond;
  int? id;
  String? jumpUrl;
  int? liveState;
  int? reserveType;
  String? title;

  DynamicLive2Model.fromJson(Map<String, dynamic> json) {
    badge = json['badge'];
    cover = json['cover'];
    descFirst = json['desc_first'];
    descSecond = json['desc_second'];
    id = json['id'] is String ? int.tryParse(json['id']) : json['id'];
    jumpUrl = json['jump_url'];
    liveState = json['liv_state'] is String
        ? int.tryParse(json['liv_state'])
        : json['liv_state'];
    reserveType = json['reserve_type'] is String
        ? int.tryParse(json['reserve_type'])
        : json['reserve_type'];
    title = json['title'];
  }
}

// 动态状态 转发、评论、点赞
class ModuleStatModel {
  ModuleStatModel({
    this.comment,
    this.forward,
    this.like,
  });

  Comment? comment;
  ForWard? forward;
  Like? like;

  ModuleStatModel.fromJson(Map<String, dynamic> json) {
    comment = Comment.fromJson(json['comment']);
    forward = ForWard.fromJson(json['forward']);
    like = Like.fromJson(json['like']);
  }
}

// 动态状态 评论
class Comment {
  Comment({
    this.count,
    this.forbidden,
  });

  String? count;
  bool? forbidden;

  Comment.fromJson(Map<String, dynamic> json) {
    count = json['count'] == 0 ? null : json['count'].toString();
    forbidden = json['forbidden'];
  }
}

class ForWard {
  ForWard({this.count, this.forbidden});
  String? count;
  bool? forbidden;

  ForWard.fromJson(Map<String, dynamic> json) {
    count = json['count'] == 0 ? null : json['count'].toString();
    forbidden = json['forbidden'];
  }
}

// 动态状态 点赞
class Like {
  Like({
    this.count,
    this.forbidden,
    this.status,
  });

  String? count;
  bool? forbidden;
  bool? status;

  Like.fromJson(Map<String, dynamic> json) {
    count = json['count'] == 0 ? null : json['count'].toString();
    forbidden = json['forbidden'];
    status = json['status'];
  }
}

class Stat {
  Stat({
    this.danmu,
    this.play,
  });

  String? danmu;
  String? play;

  Stat.fromJson(Map<String, dynamic> json) {
    danmu = json['danmaku'];
    play = json['play'];
  }
}

// 游戏推广卡片
class AddCommon {
  AddCommon({
    this.button,
    this.cover,
    this.desc1,
    this.desc2,
    this.jumpUrl,
    this.title,
  });

  AddButton? button;
  String? cover;
  String? desc1;
  String? desc2;
  String? jumpUrl;
  String? title;

  AddCommon.fromJson(Map<String, dynamic> json) {
    button = json['button'] != null ? AddButton.fromJson(json['button']) : null;
    cover = json['cover'];
    desc1 = json['desc1'];
    desc2 = json['desc2'];
    jumpUrl = json['jump_url'];
    title = json['title'];
  }
}

// 比赛信息卡片
class AddMatch {
  AddMatch({
    this.button,
    this.jumpUrl,
    this.matchInfo,
  });

  AddButton? button;
  String? jumpUrl;
  MatchInfo? matchInfo;

  AddMatch.fromJson(Map<String, dynamic> json) {
    button = json['button'] != null ? AddButton.fromJson(json['button']) : null;
    jumpUrl = json['jump_url'];
    matchInfo = json['match_info'] != null
        ? MatchInfo.fromJson(json['match_info'])
        : null;
  }
}

class MatchInfo {
  MatchInfo({
    this.title,
    this.subTitle,
    this.leftTeam,
    this.rightTeam,
    this.centerTop,
    this.centerBottom,
  });

  String? title;
  String? subTitle;
  MatchTeam? leftTeam;
  MatchTeam? rightTeam;
  List<String>? centerTop;
  String? centerBottom;

  MatchInfo.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    subTitle = json['sub_title'];
    leftTeam = json['left_team'] != null
        ? MatchTeam.fromJson(json['left_team'])
        : null;
    rightTeam = json['right_team'] != null
        ? MatchTeam.fromJson(json['right_team'])
        : null;
    centerTop = json['center_top'] != null
        ? List<String>.from(json['center_top'])
        : null;
    centerBottom = json['center_bottom'];
  }
}

class MatchTeam {
  MatchTeam({
    this.name,
    this.pic,
  });

  String? name;
  String? pic;

  MatchTeam.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    pic = json['pic'];
  }
}

class AddButton {
  AddButton({
    this.icon,
    this.jumpUrl,
    this.text,
    this.jumpStyle,
  });

  String? icon;
  String? jumpUrl;
  String? text;
  JumpStyle? jumpStyle;

  AddButton.fromJson(Map<String, dynamic> json) {
    icon = json['icon'];
    jumpUrl = json['jump_url'];
    text = json['text'];
    jumpStyle = json['jump_style'] != null
        ? JumpStyle.fromJson(json['jump_style'])
        : null;
  }
}

class JumpStyle {
  JumpStyle({
    this.text,
  });

  String? text;

  JumpStyle.fromJson(Map<String, dynamic> json) {
    text = json['text'];
  }
}
