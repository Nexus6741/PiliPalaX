class TopicItem {
  final int id;
  final String name;
  final String? description;
  final int? view;
  final int? discuss;
  final String? statDesc;
  final String? cover;
  final bool? showInteractData;

  TopicItem({
    required this.id,
    required this.name,
    this.description,
    this.view,
    this.discuss,
    this.statDesc,
    this.cover,
    this.showInteractData,
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
    };
  }

  // 兼容旧版本的 discussCount 属性
  int? get discussCount => discuss;
}
