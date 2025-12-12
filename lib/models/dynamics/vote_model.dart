class VoteInfo {
  final int? voteId;
  final String title;
  final List<VoteOption> options;
  final int? endTime;
  final bool multiChoice;
  final int? choiceCount;
  final int? duration; // 投票持续时间（秒）

  VoteInfo({
    this.voteId,
    required this.title,
    required this.options,
    this.endTime,
    this.multiChoice = false,
    this.choiceCount,
    this.duration,
  });

  factory VoteInfo.fromJson(Map<String, dynamic> json) {
    return VoteInfo(
      voteId: json['vote_id'],
      title: json['title'] ?? '',
      options: (json['options'] as List?)
              ?.map((e) => VoteOption.fromJson(e))
              .toList() ??
          [],
      endTime: json['end_time'],
      multiChoice: json['multi_choice'] ?? false,
      choiceCount: json['choice_count'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    // 计算 choice_cnt：如果是多选，则为选项数量，否则为1
    final int calculatedChoiceCnt = multiChoice ? options.length : 1;

    return {
      if (voteId != null) 'vote_id': voteId,
      'title': title,
      'desc': '', // 投票描述，可为空
      'type': 0, // 0: 文字投票, 1: 图片投票
      'choice_cnt': choiceCount ?? calculatedChoiceCnt,
      'duration': getDurationInSeconds(),
      'options': options.map((e) => e.toJson()).toList(),
    };
  }

  // 获取投票持续时间（秒）
  int getDurationInSeconds() {
    if (duration != null) {
      return duration!;
    }
    if (endTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return endTime! - now;
    }
    return 7 * 24 * 60 * 60; // 默认7天
  }
}

class VoteOption {
  final String text;
  final int? count;
  final bool? selected;

  VoteOption({
    required this.text,
    this.count,
    this.selected,
  });

  factory VoteOption.fromJson(Map<String, dynamic> json) {
    return VoteOption(
      text: json['text'] ?? '',
      count: json['count'],
      selected: json['selected'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opt_desc': text, // API 需要的字段名是 opt_desc
      if (count != null) 'cnt': count,
    };
  }
}
