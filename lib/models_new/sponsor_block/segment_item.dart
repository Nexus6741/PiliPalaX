class SegmentItemModel {
  String? cid;
  String category;
  String? actionType;
  List<int> segment;
  String uuid;
  num? videoDuration;
  int? votes;

  SegmentItemModel({
    this.cid,
    required this.category,
    this.actionType,
    required this.segment,
    required this.uuid,
    this.videoDuration,
    this.votes,
  });

  factory SegmentItemModel.fromJson(Map<String, dynamic> json) =>
      SegmentItemModel(
        cid: json["cid"],
        category: json["category"],
        actionType: json["actionType"],
        segment: (json["segment"] as List)
            .map((e) => ((e as num) * 1000).round())
            .toList(),
        uuid: json["UUID"],
        videoDuration: json["videoDuration"] == null
            ? null
            : (json["videoDuration"] as num) * 1000,
        votes: json["votes"],
      );

  /// 从番剧 API 返回的片头片尾数据创建
  factory SegmentItemModel.fromPgcJson(
    Map<String, dynamic> json,
    num? videoDuration,
  ) {
    String category;
    final clipType = json['clipType'];
    if (clipType == 'CLIP_TYPE_OP') {
      category = 'intro';
    } else if (clipType == 'CLIP_TYPE_ED') {
      category = 'outro';
    } else {
      category = 'sponsor';
    }

    return SegmentItemModel(
      category: category,
      segment: [
        ((json['start'] as num) * 1000).round(),
        ((json['end'] as num) * 1000).round(),
      ],
      uuid: '',
      videoDuration: videoDuration,
    );
  }
}
