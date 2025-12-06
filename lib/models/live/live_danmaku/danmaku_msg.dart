class BaseEmote {
  int? id;
  int? emoticon;
  int? emoticonId;
  String? emoteName;
  String? emoticonUnique;
  String? text;
  int? perm;
  String? url;
  int? isEmoji;
  int? emoticonValueType;
  int? inPlayerArea;
  int? bulgeDisplay;
  int? height;
  int? width;

  BaseEmote({
    this.id,
    this.emoticon,
    this.emoticonId,
    this.emoteName,
    this.emoticonUnique,
    this.text,
    this.perm,
    this.url,
    this.isEmoji,
    this.emoticonValueType,
    this.inPlayerArea,
    this.bulgeDisplay,
    this.height,
    this.width,
  });

  factory BaseEmote.fromJson(Map<String, dynamic> json) => BaseEmote(
        id: json['id'] as int?,
        emoticon: json['emoticon'] as int?,
        emoticonId: json['emoticon_id'] as int?,
        emoteName: json['emotename'] as String?,
        emoticonUnique: json['emoticon_unique'] as String?,
        text: json['text'] as String?,
        perm: json['perm'] as int?,
        url: json['url'] as String?,
        isEmoji: json['is_emoji'] as int?,
        emoticonValueType: json['emoticon_value_type'] as int?,
        inPlayerArea: json['in_player_area'] as int?,
        bulgeDisplay: json['bulge_display'] as int?,
        height: json['height'] as int?,
        width: json['width'] as int?,
      );
}

class DanmakuMsg {
  String? name;
  int? uid;
  String? text;
  Map<String, BaseEmote>? emots;
  BaseEmote? uemote;
  bool isSystem;
  bool isGift;

  DanmakuMsg({
    this.name,
    this.uid,
    this.text,
    this.emots,
    this.uemote,
    this.isSystem = false,
    this.isGift = false,
  });

  factory DanmakuMsg.fromPrefetch(Map<String, dynamic> json) {
    return DanmakuMsg(
      name: json['nickname'] as String?,
      uid: json['uid'] as int?,
      text: json['text'] as String?,
    );
  }
}
