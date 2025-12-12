class TopicItem {
  int id;
  String name;
  String? description;
  int? view;
  int? discuss;
  String? statDesc;
  String? cover;
  bool? showInteractData;
  int fav;
  int like;
  int? dynamics;
  String? jumpUrl;
  String? backColor;
  String? sharePic;
  String? shareUrl;
  int? ctime;
  bool? isFav;
  bool? isLike;

  TopicItem({
    required this.id,
    required this.name,
    this.description,
    this.view,
    this.discuss,
    this.statDesc,
    this.cover,
    this.showInteractData,
    this.fav = 0,
    this.like = 0,
    this.dynamics,
    this.jumpUrl,
    this.backColor,
    this.sharePic,
    this.shareUrl,
    this.ctime,
    this.isFav,
    this.isLike,
  });

  factory TopicItem.fromJson(Map<String, dynamic> json) {
    return TopicItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      view: json['view'],
      discuss: json['discuss'],
      statDesc: json['stat_desc'],
      cover: json['cover'],
      showInteractData: json['show_interact_data'],
      fav: json['fav'] ?? 0,
      like: json['like'] ?? 0,
      dynamics: json['dynamics'] as int?,
      jumpUrl: json['jump_url'] as String?,
      backColor: json['back_color'] as String?,
      sharePic: json['share_pic'] as String?,
      shareUrl: json['share_url'] as String?,
      ctime: json['ctime'] as int?,
      isFav: json['is_fav'] as bool?,
      isLike: json['is_like'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'view': view,
      'discuss': discuss,
      'stat_desc': statDesc,
      'cover': cover,
      'show_interact_data': showInteractData,
      'fav': fav,
      'like': like,
      'dynamics': dynamics,
      'jump_url': jumpUrl,
      'back_color': backColor,
      'share_pic': sharePic,
      'share_url': shareUrl,
      'ctime': ctime,
      'is_fav': isFav,
      'is_like': isLike,
    };
  }

  // 兼容旧版本的 discussCount 属性
  int? get discussCount => discuss;
}
