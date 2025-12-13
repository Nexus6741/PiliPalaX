import 'package:flutter/material.dart';
import 'models.dart';

/// 富文本编辑控制器
/// 使用占位符字符来表示表情，在 buildTextSpan 中渲染为图片
class RichTextEditingController extends TextEditingController {
  RichTextEditingController({
    this.onMention,
  });

  final VoidCallback? onMention;

  /// 表情映射：占位符 -> 表情信息
  final Map<String, EmoteInfo> _emoteMap = {};

  /// @用户映射：文本范围 -> 用户信息
  final Map<String, AtUserInfo> _atUserMap = {};

  /// 占位符计数器
  int _placeholderCounter = 0;

  /// 标记是否正在更新值（防止递归）
  bool _isUpdatingValue = false;

  /// 获取所有占位符集合
  Set<String> get _placeholders => _emoteMap.keys.toSet();

  /// 获取富文本项列表（用于发布）
  List<RichTextItem> getRichTextItems() {
    final items = <RichTextItem>[];
    final currentText = text;

    if (currentText.isEmpty) {
      return items;
    }

    // 提取所有@用户
    final mentions = _extractMentions(currentText);

    // 构建富文本项
    int lastEnd = 0;

    for (int i = 0; i < currentText.length; i++) {
      final char = currentText[i];

      // 检查是否是表情占位符
      if (_placeholders.contains(char)) {
        final emoteInfo = _emoteMap[char];
        if (emoteInfo != null) {
          // 添加表情前的文本
          if (i > lastEnd) {
            final beforeText = currentText.substring(lastEnd, i);
            _addTextItems(items, beforeText, lastEnd, mentions);
          }

          // 添加表情项
          items.add(RichTextItem(
            type: RichTextType.emoji,
            text: char,
            rawText: emoteInfo.originalText,
            range: TextRange(start: i, end: i + 1),
            emote: emoteInfo.emote,
          ));

          lastEnd = i + 1;
        }
      }
    }

    // 添加最后的文本
    if (lastEnd < currentText.length) {
      final afterText = currentText.substring(lastEnd);
      _addTextItems(items, afterText, lastEnd, mentions);
    }

    return items;
  }

  /// 添加文本项（可能包含@用户）
  void _addTextItems(
    List<RichTextItem> items,
    String text,
    int offset,
    List<_MentionSpan> allMentions,
  ) {
    // 找出在当前文本范围内的@提及
    final mentions = allMentions.where((m) {
      return m.start >= offset && m.end <= offset + text.length;
    }).toList();

    if (mentions.isEmpty) {
      // 没有@提及，添加普通文本
      items.add(RichTextItem(
        type: RichTextType.text,
        text: text,
        range: TextRange(start: offset, end: offset + text.length),
      ));
      return;
    }

    // 有@提及，分段处理
    int lastEnd = 0;

    for (final mention in mentions) {
      final localStart = mention.start - offset;
      final localEnd = mention.end - offset;

      // 添加@提及前的文本
      if (localStart > lastEnd) {
        final beforeText = text.substring(lastEnd, localStart);
        items.add(RichTextItem(
          type: RichTextType.text,
          text: beforeText,
          range: TextRange(start: offset + lastEnd, end: offset + localStart),
        ));
      }

      // 添加@提及项
      final atUserInfo = _atUserMap[mention.text];
      final username =
          mention.text.substring(1, mention.text.length - 1); // 去掉@和空格

      items.add(RichTextItem(
        type: RichTextType.at,
        text: mention.text,
        rawText: username,
        range: TextRange(start: mention.start, end: mention.end),
        id: atUserInfo?.uid,
      ));

      lastEnd = localEnd;
    }

    // 添加最后的文本
    if (lastEnd < text.length) {
      final afterText = text.substring(lastEnd);
      items.add(RichTextItem(
        type: RichTextType.text,
        text: afterText,
        range: TextRange(start: offset + lastEnd, end: offset + text.length),
      ));
    }
  }

  /// 插入@用户
  void insertAtUser(String username, String uid) {
    final selection = value.selection;
    if (!selection.isValid) {
      return;
    }

    final atText = '@$username ';

    // 保存用户信息
    _atUserMap[atText] = AtUserInfo(
      uid: uid,
      username: username,
    );

    final oldText = text;
    final newText = oldText.substring(0, selection.start) +
        atText +
        oldText.substring(selection.end);

    // 更新控制器
    _isUpdatingValue = true;
    value = TextEditingValue(
      text: newText,
      selection:
          TextSelection.collapsed(offset: selection.start + atText.length),
    );
    _isUpdatingValue = false;
  }

  /// 生成唯一的占位符（使用 Unicode 私有区域字符）
  String _generatePlaceholder() {
    // 使用 Unicode 私有区域字符 U+E000 - U+F8FF
    final code = 0xE000 + (_placeholderCounter % 0x18FF);
    _placeholderCounter++;
    return String.fromCharCode(code);
  }

  /// 插入表情
  void insertEmote(String emoteText, Emote emote) {
    if (emoteText.isEmpty) {
      return;
    }

    final selection = value.selection;
    if (!selection.isValid) {
      return;
    }

    // 生成占位符
    final placeholder = _generatePlaceholder();

    // 保存表情信息
    _emoteMap[placeholder] = EmoteInfo(
      placeholder: placeholder,
      originalText: emoteText,
      emote: emote,
    );

    final oldText = text;
    final newText = oldText.substring(0, selection.start) +
        placeholder +
        oldText.substring(selection.end);

    // 更新控制器（使用标记防止递归处理）
    _isUpdatingValue = true;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 1),
    );
    _isUpdatingValue = false;
  }

  /// 获取原始文本（用于发送）
  String get originalText {
    String result = text;
    for (var entry in _emoteMap.entries) {
      result = result.replaceAll(entry.key, entry.value.originalText);
    }
    return result;
  }

  /// 识别 @提及文本（格式：@用户名 ）
  List<_MentionSpan> _extractMentions(String text) {
    final List<_MentionSpan> mentions = [];
    final regex = RegExp(r'@[\u4e00-\u9fff\w]+\s');

    for (final match in regex.allMatches(text)) {
      mentions.add(_MentionSpan(
        start: match.start,
        end: match.end,
        text: match.group(0)!,
      ));
    }

    return mentions;
  }

  /// 识别视频进度文本（格式：MM:SS 或 HH:MM:SS，前后有空格）
  List<_VideoProgressSpan> _extractVideoProgress(String text) {
    final List<_VideoProgressSpan> progresses = [];
    // 匹配 MM:SS 或 HH:MM:SS 格式，前后必须有空格或在文本开头/结尾
    final regex = RegExp(r'(?:^|\s)(\d{1,2}:\d{2}(?::\d{2})?)(?:\s|$)');

    for (final match in regex.allMatches(text)) {
      final timeStr = match.group(1)!;
      progresses.add(_VideoProgressSpan(
        start: match.start,
        end: match.end,
        text: match.group(0)!,
        timeStr: timeStr,
      ));
    }

    return progresses;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    // 提取 @提及文本
    final mentions = _extractMentions(text);

    // 提取视频进度文本
    final videoProgresses = _extractVideoProgress(text);

    // 如果没有表情、@提及和视频进度，直接返回普通文本
    if (_emoteMap.isEmpty && mentions.isEmpty && videoProgresses.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    // 构建混合内容
    final List<InlineSpan> children = [];
    final currentText = text;
    int lastEnd = 0;

    for (int i = 0; i < currentText.length; i++) {
      final char = currentText[i];

      // 检查当前字符是否是占位符（表情）
      if (_placeholders.contains(char)) {
        final emoteInfo = _emoteMap[char];

        if (emoteInfo != null) {
          // 添加表情前的文本（可能包含 @提及）
          if (i > lastEnd) {
            final beforeText = currentText.substring(lastEnd, i);
            if (beforeText.isNotEmpty) {
              _addTextWithMentions(children, beforeText, style, lastEnd);
            }
          }

          // 添加表情图片
          children.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Image.network(
                emoteInfo.emote.url,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    emoteInfo.originalText,
                    style: style,
                  );
                },
              ),
            ),
          ));

          lastEnd = i + 1;
        }
      }
    }

    // 添加最后的文本（可能包含 @提及）
    if (lastEnd < currentText.length) {
      final afterText = currentText.substring(lastEnd);
      if (afterText.isNotEmpty) {
        _addTextWithMentions(children, afterText, style, lastEnd);
      }
    }

    return TextSpan(style: style, children: children);
  }

  /// 添加文本，并高亮 @提及和视频进度部分
  void _addTextWithMentions(
    List<InlineSpan> children,
    String text,
    TextStyle? baseStyle,
    int offset,
  ) {
    final mentions = _extractMentions(text);
    final videoProgresses = _extractVideoProgress(text);

    if (mentions.isEmpty && videoProgresses.isEmpty) {
      // 没有 @提及和视频进度，直接添加文本
      children.add(TextSpan(text: text, style: baseStyle));
      return;
    }

    // 合并所有需要高亮的部分，按位置排序
    final List<_HighlightSpan> highlights = [];
    for (final mention in mentions) {
      highlights.add(_HighlightSpan(
        start: mention.start,
        end: mention.end,
        text: mention.text,
        type: 'mention',
      ));
    }
    for (final progress in videoProgresses) {
      highlights.add(_HighlightSpan(
        start: progress.start,
        end: progress.end,
        text: progress.text,
        type: 'progress',
      ));
    }
    highlights.sort((a, b) => a.start.compareTo(b.start));

    // 分段处理
    int lastEnd = 0;

    for (final highlight in highlights) {
      // 添加高亮前的普通文本
      if (highlight.start > lastEnd) {
        final beforeText = text.substring(lastEnd, highlight.start);
        children.add(TextSpan(text: beforeText, style: baseStyle));
      }

      // 添加高亮文本
      TextStyle highlightStyle;
      if (highlight.type == 'mention') {
        highlightStyle = (baseStyle ?? const TextStyle()).copyWith(
          color: const Color(0xFF1890FF), // 蓝色高亮
          fontWeight: FontWeight.w500,
        );
      } else {
        // 视频进度 - 橙色高亮
        highlightStyle = (baseStyle ?? const TextStyle()).copyWith(
          color: const Color(0xFFFF7A45), // 橙色高亮
          fontWeight: FontWeight.w500,
        );
      }
      children.add(TextSpan(text: highlight.text, style: highlightStyle));

      lastEnd = highlight.end;
    }

    // 添加最后的普通文本
    if (lastEnd < text.length) {
      final afterText = text.substring(lastEnd);
      children.add(TextSpan(text: afterText, style: baseStyle));
    }
  }

  @override
  void clear() {
    _emoteMap.clear();
    _placeholderCounter = 0;
    super.clear();
  }

  @override
  set value(TextEditingValue newValue) {
    // 如果正在更新值，直接调用父类方法
    if (_isUpdatingValue) {
      super.value = newValue;
      return;
    }

    // 检查是否有表情被删除
    final newText = newValue.text;

    // 找出被删除的占位符
    final toRemove = <String>[];
    for (var placeholder in _emoteMap.keys) {
      if (!newText.contains(placeholder)) {
        toRemove.add(placeholder);
      }
    }

    // 移除被删除的表情
    for (var placeholder in toRemove) {
      _emoteMap.remove(placeholder);
    }

    super.value = newValue;
  }
}

/// 表情信息
class EmoteInfo {
  final String placeholder;
  final String originalText;
  final Emote emote;

  EmoteInfo({
    required this.placeholder,
    required this.originalText,
    required this.emote,
  });
}

/// @用户信息
class AtUserInfo {
  final String uid;
  final String username;

  AtUserInfo({
    required this.uid,
    required this.username,
  });
}

/// @提及文本信息
class _MentionSpan {
  final int start;
  final int end;
  final String text;

  _MentionSpan({
    required this.start,
    required this.end,
    required this.text,
  });
}

/// 视频进度文本信息
class _VideoProgressSpan {
  final int start;
  final int end;
  final String text;
  final String timeStr;

  _VideoProgressSpan({
    required this.start,
    required this.end,
    required this.text,
    required this.timeStr,
  });
}

/// 高亮文本信息
class _HighlightSpan {
  final int start;
  final int end;
  final String text;
  final String type; // 'mention' 或 'progress'

  _HighlightSpan({
    required this.start,
    required this.end,
    required this.text,
    required this.type,
  });
}
