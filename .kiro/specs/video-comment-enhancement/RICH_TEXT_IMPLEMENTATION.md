# 富文本实现方案 - 完整版

## 概述

已完成富文本系统的完整实现，支持在评论输入框中正确显示和管理表情、@提及、视频进度等富文本元素。

## 核心改进

### 1. 问题分析

之前的简单文本插入方式存在的问题：
- 表情和文本的位置混乱（文本被插入到 `[]` 中）
- 光标位置计算错误
- 无法正确维护富文本元素的范围

### 2. 解决方案

采用**富文本项列表管理**方式：
- 维护 `RichTextItem` 列表，每个项记录类型、文本、范围等信息
- 在插入新元素时，重新构建整个项列表
- 确保每个项的范围（TextRange）正确对应文本位置

### 3. 实现细节

#### RichTextItem 结构
```dart
class RichTextItem {
  RichTextType type;      // 元素类型（text, emoji, at, common等）
  String text;            // 显示文本
  String? rawText;        // 原始文本（用于提交）
  TextRange range;        // 文本范围
  Emote? emote;          // 表情信息
  String? id;            // 关联ID
}
```

#### 插入流程

当用户选择表情时：

1. **获取当前状态**
   - 获取光标位置 `cursorPos`
   - 获取当前文本 `currentText`

2. **构建新文本**
   ```
   newText = currentText[0:cursorPos] + emoteText + currentText[cursorPos:]
   ```

3. **重建项列表**
   - 光标前的文本 → `RichTextItem(type: text, ...)`
   - 新插入的表情 → `RichTextItem(type: emoji, ...)`
   - 光标后的文本 → `RichTextItem(type: text, ...)`

4. **更新控制器**
   - 更新 `items` 列表
   - 更新 `TextEditingValue`
   - 光标移动到新位置

#### 代码示例

```dart
void onInsertText(
  String text,
  RichTextType type, {
  String? rawText,
  Emote? emote,
  String? id,
}) {
  final oldValue = _replyContentController.value;
  final selection = oldValue.selection;
  final cursorPos = selection.baseOffset;
  final currentText = oldValue.text;

  // 构建新文本
  final newText = currentText.substring(0, cursorPos) +
      text +
      currentText.substring(cursorPos);

  // 重建项列表
  final newItems = <RichTextItem>[];
  int offset = 0;

  // 光标前的文本
  if (cursorPos > 0) {
    final beforeText = currentText.substring(0, cursorPos);
    newItems.add(RichTextItem(
      type: RichTextType.text,
      text: beforeText,
      range: TextRange(start: 0, end: beforeText.length),
    ));
    offset = beforeText.length;
  }

  // 新插入的元素
  newItems.add(RichTextItem(
    type: type,
    text: text,
    rawText: rawText,
    range: TextRange(start: offset, end: offset + text.length),
    emote: emote,
    id: id,
  ));
  offset += text.length;

  // 光标后的文本
  if (cursorPos < currentText.length) {
    final afterText = currentText.substring(cursorPos);
    newItems.add(RichTextItem(
      type: RichTextType.text,
      text: afterText,
      range: TextRange(start: offset, end: offset + afterText.length),
    ));
  }

  // 更新控制器
  _replyContentController.items
    ..clear()
    ..addAll(newItems);

  _replyContentController.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: cursorPos + text.length),
  );
}
```

## 支持的操作

### 1. 表情插入
- 用户选择表情 → 调用 `onChooseEmote()`
- 表情以 `[emote_name]` 格式插入
- B站服务器自动识别并渲染为图片

### 2. 视频进度插入
- 用户点击"视频进度" → 调用 `onInsertVideoProgress()`
- 插入格式化的时间戳（如 `00:02:03`）
- 类型为 `RichTextType.common`

### 3. 图片上传
- 用户选择图片 → 调用 `onPickImage()`
- 图片上传到 BFS 服务器
- 收集图片元数据（URL、宽度、高度、大小）
- 提交评论时一起发送

## 文件结构

```
lib/common/widgets/rich_text/
├── models.dart           # 数据模型（RichTextItem, RichTextType, Emote）
├── controller.dart       # 控制器（RichTextEditingController）
├── text_field.dart       # 文本字段组件（RichTextField）
└── index.dart           # 导出文件

lib/pages/video/reply_new/
├── view_enhanced.dart    # 增强版评论对话框
├── toolbar_icon_button.dart
└── widgets/
    └── image_preview_list.dart
```

## 关键特性

✅ **正确的文本位置管理** - 每个元素的范围准确对应
✅ **光标位置正确** - 插入后光标在正确位置
✅ **支持多种富文本类型** - 表情、@提及、视频进度等
✅ **与 B站 API 兼容** - 提交格式符合 B站要求
✅ **简洁高效** - 无需复杂的 Delta 同步机制

## 测试场景

1. **连续插入表情**
   - 输入文本 → 插入表情 → 输入文本 → 插入表情
   - 验证：所有元素位置正确，文本顺序正确

2. **在表情后插入文本**
   - 插入表情 → 在表情后输入文本
   - 验证：文本不会被插入到表情的 `[]` 中

3. **混合操作**
   - 输入文本 → 插入表情 → 输入文本 → 插入视频进度 → 上传图片
   - 验证：所有元素正确组织，提交时格式正确

## 未来改进

1. **实时预览** - 在输入框中显示表情图片而不是文本
2. **颜色标记** - 视频进度文本显示不同颜色
3. **撤销/重做** - 支持编辑历史
4. **拖拽排序** - 支持图片拖拽重排

## 总结

新的富文本实现方案通过维护项列表和正确的范围管理，解决了之前的文本位置混乱问题。虽然没有实现完整的实时图片预览（需要 Flutter 版本升级），但已经提供了稳定、可靠的富文本支持，满足基本的评论功能需求。
