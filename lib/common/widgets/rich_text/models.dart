import 'package:flutter/material.dart';

/// 富文本类型枚举
enum RichTextType {
  text, // 普通文本
  composing, // 输入法组合文本
  at, // @用户
  emoji, // 表情
  vote, // 投票
  common, // 通用富文本
  videoProgress, // 视频进度
}

/// 表情数据模型
class Emote {
  late String url; // 表情图片URL
  late double width; // 宽度
  late double height; // 高度

  Emote({
    required this.url,
    required this.width,
    double? height,
  }) : height = height ?? width;
}

/// 富文本表情别名
typedef RichTextEmote = Emote;

/// 富文本项，表示评论中的一个内容片段
class RichTextItem {
  late RichTextType type;
  late String text; // 显示文本
  String? _rawText; // 原始文本
  late TextRange range; // 文本范围
  Emote? emote; // 表情信息
  String? id; // 关联ID（用户ID、投票ID等）

  String get rawText => _rawText ?? text;

  bool get isText => type == RichTextType.text;

  bool get isComposing => type == RichTextType.composing;

  bool get isRich => !isText && !isComposing;

  RichTextItem({
    this.type = RichTextType.text,
    required this.text,
    String? rawText,
    required this.range,
    this.emote,
    this.id,
  }) {
    _rawText = rawText;
  }

  RichTextItem.fromStart(
    this.text, {
    String? rawText,
    this.type = RichTextType.text,
    this.emote,
    this.id,
  }) {
    range = TextRange(start: 0, end: text.length);
    _rawText = rawText;
  }

  @override
  String toString() {
    return '\ntype: [${type.name}],'
        'text: [$text],'
        'rawText: [$_rawText],'
        '\nrange: [TextRange(start: ${range.start}, end: ${range.end})]\n';
  }
}
