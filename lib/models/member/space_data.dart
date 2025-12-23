// 用户空间数据模型（简化版，逐步完善）
class SpaceData {
  int? relation;
  String? defaultTab;
  SpaceCard? card;
  SpaceImages? images;
  SpaceLive? live;
  SpaceArchive? archive;
  SpaceFavourite2? favourite2;
  SpaceCoinArchive? coinArchive;
  SpaceLikeArchive? likeArchive;
  List<SpaceTab2>? tab2;
  int? relSpecial;
  bool? hasItem;
  int? silence;

  SpaceData({
    this.relation,
    this.defaultTab,
    this.card,
    this.images,
    this.live,
    this.archive,
    this.favourite2,
    this.coinArchive,
    this.likeArchive,
    this.tab2,
    this.relSpecial,
    this.hasItem,
    this.silence,
  });

  SpaceData.fromJson(Map<String, dynamic> json) {
    try {
      relation = json['relation'] as int?;
      defaultTab = json['default_tab'] as String?;

      // 解析card，添加更多错误处理
      if (json['card'] != null) {
        try {
          card = SpaceCard.fromJson(json['card'] as Map<String, dynamic>);
        } catch (e) {
          // print('Error parsing card: $e');
        }
      }

      // 解析images，添加更多错误处理
      if (json['images'] != null) {
        try {
          images = SpaceImages.fromJson(json['images'] as Map<String, dynamic>);
        } catch (e) {
          // print('Error parsing images: $e');
        }
      }

      live = json['live'] == null
          ? null
          : SpaceLive.fromJson(json['live'] as Map<String, dynamic>);
      archive = json['archive'] == null
          ? null
          : SpaceArchive.fromJson(json['archive'] as Map<String, dynamic>);
      favourite2 = json['favourite2'] == null
          ? null
          : SpaceFavourite2.fromJson(
              json['favourite2'] as Map<String, dynamic>);
      coinArchive = json['coin_archive'] == null
          ? null
          : SpaceCoinArchive.fromJson(
              json['coin_archive'] as Map<String, dynamic>);
      likeArchive = json['like_archive'] == null
          ? null
          : SpaceLikeArchive.fromJson(
              json['like_archive'] as Map<String, dynamic>);
      tab2 = (json['tab2'] as List<dynamic>?)
          ?.map((e) => SpaceTab2.fromJson(e as Map<String, dynamic>))
          .toList();
      relSpecial = (json['rel_special'] as num?)?.toInt();
      silence = (json['silence'] as num?)?.toInt();
      hasItem = archive?.item?.isNotEmpty == true ||
          favourite2?.item?.isNotEmpty == true ||
          coinArchive?.item?.isNotEmpty == true ||
          likeArchive?.item?.isNotEmpty == true;
    } catch (e) {
      // print('Error in SpaceData.fromJson: $e');
      rethrow;
    }
  }
}

// 用户卡片信息
class SpaceCard {
  String? mid;
  String? name;
  String? face;
  String? sign;
  int? fans;
  int? attention;
  SpaceVip? vip;
  SpaceLevelInfo? levelInfo;
  SpaceOfficialVerify? officialVerify;
  SpaceNameplate? nameplate;
  SpacePendant? pendant;
  SpaceLikes? likes;
  SpaceRelation? relation;
  List<SpaceTag>? spaceTag;
  SpacePrInfo? prInfo;

  SpaceCard({
    this.mid,
    this.name,
    this.face,
    this.sign,
    this.fans,
    this.attention,
    this.vip,
    this.levelInfo,
    this.officialVerify,
    this.nameplate,
    this.pendant,
    this.likes,
    this.relation,
    this.spaceTag,
    this.prInfo,
  });

  SpaceCard.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;

    try {
      mid = json['mid']?.toString();
      name = json['name'] as String?;
      face = json['face'] as String?;
      sign = json['sign'] as String?;
      fans = (json['fans'] as num?)?.toInt();
      attention = (json['attention'] as num?)?.toInt();
      vip = json['vip'] == null
          ? null
          : SpaceVip.fromJson(json['vip'] as Map<String, dynamic>);
      levelInfo = json['level_info'] == null
          ? null
          : SpaceLevelInfo.fromJson(json['level_info'] as Map<String, dynamic>);
      officialVerify = json['official_verify'] == null
          ? null
          : SpaceOfficialVerify.fromJson(
              json['official_verify'] as Map<String, dynamic>);
      nameplate = json['nameplate'] == null
          ? null
          : SpaceNameplate.fromJson(json['nameplate'] as Map<String, dynamic>);
      pendant = json['pendant'] == null
          ? null
          : SpacePendant.fromJson(json['pendant'] as Map<String, dynamic>);
      likes = json['likes'] == null
          ? null
          : SpaceLikes.fromJson(json['likes'] as Map<String, dynamic>);
      relation = json['relation'] == null
          ? null
          : SpaceRelation.fromJson(json['relation'] as Map<String, dynamic>);
      spaceTag = (json['space_tag'] as List<dynamic>?)
          ?.map((e) => SpaceTag.fromJson(e as Map<String, dynamic>))
          .toList();
      prInfo = json['pr_info'] == null
          ? null
          : SpacePrInfo.fromJson(json['pr_info'] as Map<String, dynamic>);
    } catch (e) {
      // print('Error in SpaceCard.fromJson: $e');
      rethrow;
    }
  }
}

// VIP信息
class SpaceVip {
  int? status;
  int? type;
  Map<String, dynamic>? label;

  SpaceVip({this.status, this.type, this.label});

  SpaceVip.fromJson(Map<String, dynamic> json) {
    status = (json['status'] as num?)?.toInt();
    type = (json['type'] as num?)?.toInt();
    label = json['label'] as Map<String, dynamic>?;
  }
}

// 等级信息
class SpaceLevelInfo {
  int? currentLevel;
  int? identity;

  SpaceLevelInfo({this.currentLevel, this.identity});

  SpaceLevelInfo.fromJson(Map<String, dynamic> json) {
    currentLevel = (json['current_level'] as num?)?.toInt();
    identity = (json['identity'] as num?)?.toInt();
  }
}

// 认证信息
class SpaceOfficialVerify {
  int? type;
  String? desc;
  String? icon;

  String? get spliceTitle => desc;

  SpaceOfficialVerify({this.type, this.desc, this.icon});

  SpaceOfficialVerify.fromJson(Map<String, dynamic> json) {
    type = (json['type'] as num?)?.toInt();
    desc = json['desc'] as String?;
    icon = json['icon'] as String?;
  }
}

// 勋章
class SpaceNameplate {
  String? imageSmall;

  SpaceNameplate({this.imageSmall});

  SpaceNameplate.fromJson(Map<String, dynamic> json) {
    imageSmall = json['image_small'] as String?;
  }
}

// 挂件
class SpacePendant {
  String? image;

  SpacePendant({this.image});

  SpacePendant.fromJson(Map<String, dynamic> json) {
    image = json['image'] as String?;
  }
}

// 获赞数
class SpaceLikes {
  int? likeNum;

  SpaceLikes({this.likeNum});

  SpaceLikes.fromJson(Map<String, dynamic> json) {
    likeNum = (json['like_num'] as num?)?.toInt();
  }
}

// 关系
class SpaceRelation {
  int? status;
  int? isFollow;
  int? isFollowed;

  SpaceRelation({this.status, this.isFollow, this.isFollowed});

  SpaceRelation.fromJson(Map<String, dynamic> json) {
    status = (json['status'] as num?)?.toInt();
    isFollow = (json['is_follow'] as num?)?.toInt();
    isFollowed = (json['is_followed'] as num?)?.toInt();
  }
}

// 空间标签
class SpaceTag {
  String? title;
  String? uri;

  SpaceTag({this.title, this.uri});

  SpaceTag.fromJson(Map<String, dynamic> json) {
    title = json['title'] as String?;
    uri = json['uri'] as String?;
  }
}

// 推广信息
class SpacePrInfo {
  String? content;
  String? icon;
  String? iconNight;
  String? url;
  String? bgColor;
  String? bgColorNight;
  String? textColor;
  String? textColorNight;

  SpacePrInfo({
    this.content,
    this.icon,
    this.iconNight,
    this.url,
    this.bgColor,
    this.bgColorNight,
    this.textColor,
    this.textColorNight,
  });

  SpacePrInfo.fromJson(Map<String, dynamic> json) {
    content = json['content'] as String?;
    icon = json['icon'] as String?;
    iconNight = json['icon_night'] as String?;
    url = json['url'] as String?;
    bgColor = json['bg_color'] as String?;
    bgColorNight = json['bg_color_night'] as String?;
    textColor = json['text_color'] as String?;
    textColorNight = json['text_color_night'] as String?;
  }
}

// 背景图
class SpaceImages {
  String? imgUrl;
  String? nightImgurl;

  SpaceImages({this.imgUrl, this.nightImgurl});

  SpaceImages.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    imgUrl = json['imgUrl'] as String?;
    nightImgurl = json['night_imgurl'] as String?;
  }
}

// 直播信息
class SpaceLive {
  int? liveStatus;
  int? roomid;

  SpaceLive({this.liveStatus, this.roomid});

  SpaceLive.fromJson(Map<String, dynamic> json) {
    liveStatus = (json['liveStatus'] as num?)?.toInt();
    roomid = (json['roomid'] as num?)?.toInt();
  }
}

// Tab配置
class SpaceTab2 {
  String? title;
  String? param;
  List<SpaceTab2Item>? items;

  SpaceTab2({this.title, this.param, this.items});

  SpaceTab2.fromJson(Map<String, dynamic> json) {
    title = json['title'] as String?;
    param = json['param'] as String?;
    items = (json['items'] as List<dynamic>?)
        ?.map((e) => SpaceTab2Item.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class SpaceTab2Item {
  String? title;
  String? param;
  int? seasonId;
  int? seriesId;

  SpaceTab2Item({this.title, this.param, this.seasonId, this.seriesId});

  SpaceTab2Item.fromJson(Map<String, dynamic> json) {
    title = json['title'] as String?;
    param = json['param'] as String?;
    seasonId = (json['season_id'] as num?)?.toInt();
    seriesId = (json['series_id'] as num?)?.toInt();
  }
}

// 投稿
class SpaceArchive {
  int? count;
  List<SpaceArchiveItem>? item;

  SpaceArchive({this.count, this.item});

  SpaceArchive.fromJson(Map<String, dynamic> json) {
    count = (json['count'] as num?)?.toInt();
    item = (json['item'] as List<dynamic>?)
        ?.map((e) => SpaceArchiveItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class SpaceArchiveItem {
  String? bvid;
  String? pic;
  String? cover; // API 返回的字段名
  String? title;
  int? pubdate;
  int? play;
  int? duration;
  int? cid; // first_cid
  String? param; // aid 的字符串形式
  String? goto;
  String? publishTimeText;
  int? ugcPay; // 充电视频标识
  bool? isCooperation; // 合作视频标识

  SpaceArchiveItem({
    this.bvid,
    this.pic,
    this.cover,
    this.title,
    this.pubdate,
    this.play,
    this.duration,
    this.cid,
    this.param,
    this.goto,
    this.publishTimeText,
    this.ugcPay,
    this.isCooperation,
  });

  SpaceArchiveItem.fromJson(Map<String, dynamic> json) {
    bvid = json['bvid'] as String?;
    // API 可能返回 pic 或 cover
    pic = json['pic'] as String?;
    cover = json['cover'] as String?;
    // 优先使用 cover，如果没有则使用 pic
    if (pic == null && cover != null) {
      pic = cover;
    } else if (cover == null && pic != null) {
      cover = pic;
    }
    title = json['title'] as String?;
    pubdate = (json['pubdate'] as num?)?.toInt();
    play = (json['play'] as num?)?.toInt();
    duration = (json['duration'] as num?)?.toInt();
    cid = (json['first_cid'] as num?)?.toInt();
    param = json['param'] as String?;
    goto = json['goto'] as String?;
    publishTimeText = json['publish_time_text'] as String?;
    ugcPay = (json['ugc_pay'] as num?)?.toInt();
    isCooperation = json['is_cooperation'] as bool?;
  }
}

// 收藏
class SpaceFavourite2 {
  int? count;
  List<SpaceFavouriteItem>? item;

  SpaceFavourite2({this.count, this.item});

  SpaceFavourite2.fromJson(Map<String, dynamic> json) {
    count = (json['count'] as num?)?.toInt();
    item = (json['item'] as List<dynamic>?)
        ?.map((e) => SpaceFavouriteItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class SpaceFavouriteItem {
  int? id;
  int? fid;
  int? mediaId;
  String? title;
  int? mediaCount;
  int? count;
  String? cover;
  int? isPublic;

  SpaceFavouriteItem({
    this.id,
    this.fid,
    this.mediaId,
    this.title,
    this.mediaCount,
    this.count,
    this.cover,
    this.isPublic,
  });

  SpaceFavouriteItem.fromJson(Map<String, dynamic> json) {
    id = (json['id'] as num?)?.toInt();
    fid = (json['fid'] as num?)?.toInt();
    mediaId = (json['media_id'] as num?)?.toInt();
    title = json['title'] as String?;
    mediaCount = (json['media_count'] as num?)?.toInt();
    count = (json['count'] as num?)?.toInt();
    cover = json['cover'] as String?;
    isPublic = (json['is_public'] as num?)?.toInt();
  }
}

// 投币视频
class SpaceCoinArchive {
  int? count;
  List<SpaceArchiveItem>? item;

  SpaceCoinArchive({this.count, this.item});

  SpaceCoinArchive.fromJson(Map<String, dynamic> json) {
    count = (json['count'] as num?)?.toInt();
    item = (json['item'] as List<dynamic>?)
        ?.map((e) => SpaceArchiveItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// 点赞视频
class SpaceLikeArchive {
  int? count;
  List<SpaceArchiveItem>? item;

  SpaceLikeArchive({this.count, this.item});

  SpaceLikeArchive.fromJson(Map<String, dynamic> json) {
    count = (json['count'] as num?)?.toInt();
    item = (json['item'] as List<dynamic>?)
        ?.map((e) => SpaceArchiveItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
