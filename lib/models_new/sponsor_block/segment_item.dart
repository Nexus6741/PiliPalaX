class SegmentItemModel {
  final String uuid;
  final List<int> segment;
  final String category;
  final int? videoDuration;
  final int? actionType;
  final int? locked;
  final int? votes;
  final String? description;

  SegmentItemModel({
    required this.uuid,
    required this.segment,
    required this.category,
    this.videoDuration,
    this.actionType,
    this.locked,
    this.votes,
    this.description,
  });

  factory SegmentItemModel.fromJson(Map<String, dynamic> json) {
    try {
      // 解析 segment 数组（API 返回秒，需要转换为毫秒）
      List<int> segment = [];
      if (json['segment'] is List) {
        segment = (json['segment'] as List).map((e) {
          double seconds = 0;
          if (e is int) {
            seconds = e.toDouble();
          } else if (e is double) {
            seconds = e;
          } else if (e is String) {
            seconds = double.tryParse(e) ?? 0;
          } else if (e is num) {
            seconds = e.toDouble();
          }
          // 转换为毫秒
          return (seconds * 1000).round();
        }).toList();
      }

      // 安全解析整数字段
      int? parseIntField(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value);
        if (value is num) return value.toInt();
        return null;
      }

      return SegmentItemModel(
        uuid: json['UUID']?.toString() ?? '',
        segment: segment,
        category: json['category']?.toString() ?? 'sponsor',
        videoDuration: parseIntField(json['videoDuration']),
        actionType: parseIntField(json['actionType']),
        locked: parseIntField(json['locked']),
        votes: parseIntField(json['votes']),
        description: json['description']?.toString(),
      );
    } catch (e) {
      print('❌ SegmentItemModel.fromJson 解析失败: $e');
      print('   JSON 数据: $json');
      rethrow;
    }
  }

  /// 从番剧片头片尾数据创建
  factory SegmentItemModel.fromPgcJson(
    Map<String, dynamic> json,
    int? videoDuration,
  ) {
    String category;
    switch (json['clipType']) {
      case 'CLIP_TYPE_OP':
        category = 'intro';
        break;
      case 'CLIP_TYPE_ED':
        category = 'outro';
        break;
      default:
        category = 'sponsor';
    }

    return SegmentItemModel(
      uuid: '',
      segment: [
        ((json['start'] as num) * 1000).round(),
        ((json['end'] as num) * 1000).round(),
      ],
      category: category,
      videoDuration: videoDuration,
    );
  }
}
