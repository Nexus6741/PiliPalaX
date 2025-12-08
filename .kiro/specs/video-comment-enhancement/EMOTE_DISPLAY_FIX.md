# 表情功能说明

## 问题描述

用户反馈：
1. 在评论中插入表情时，表情显示为文本形式如 `[happy]`
2. 使用富文本控制器后，输入文本不显示
3. 删除功能不正常
4. 在表情后输入文本，文本被错误地插入到表情文本内部（如 `[happy]你好` 变成 `[你好happy]`）

## 根本原因

使用 `WidgetSpan` 渲染表情图片时，`WidgetSpan` 在文本中只占用一个字符的位置，但实际的表情文本（如 `[happy]`）有多个字符。这导致光标位置计算错误，文本被插入到错误的位置。

## 解决方案

**使用占位符字符方案**：用单个 Unicode 私有区域字符作为表情的占位符，在 `buildTextSpan` 中将占位符渲染为表情图片，发送时替换回原始表情文本。

### 核心实现

#### 1. 占位符生成

```dart
/// 生成唯一的占位符（使用 Unicode 私有区域字符）
String _generatePlaceholder() {
  // 使用 Unicode 私有区域字符 U+E000 - U+F8FF
  final code = 0xE000 + (_placeholderCounter % 0x18FF);
  _placeholderCounter++;
  return String.fromCharCode(code);
}
```

#### 2. 表情插入

```dart
void insertEmote(String emoteText, Emote emote) {
  // 生成占位符
  final placeholder = _generatePlaceholder();

  // 保存表情信息
  _emoteMap[placeholder] = EmoteInfo(
    placeholder: placeholder,
    originalText: emoteText,
    emote: emote,
  );

  // 插入占位符（只有一个字符）
  final newText = oldText.substring(0, selection.start) +
      placeholder +
      oldText.substring(selection.end);

  value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: selection.start + 1),
  );
}
```

#### 3. 渲染表情

```dart
@override
TextSpan buildTextSpan({...}) {
  final List<InlineSpan> children = [];
  int lastEnd = 0;

  for (int i = 0; i < currentText.length; i++) {
    final char = currentText[i];
    final emoteInfo = _emoteMap[char];

    if (emoteInfo != null) {
      // 添加表情前的普通文本
      if (i > lastEnd) {
        children.add(TextSpan(text: currentText.substring(lastEnd, i)));
      }

      // 添加表情图片
      children.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Image.network(emoteInfo.emote.url, width: 22, height: 22),
      ));

      lastEnd = i + 1;
    }
  }

  // 添加最后的普通文本
  if (lastEnd < currentText.length) {
    children.add(TextSpan(text: currentText.substring(lastEnd)));
  }

  return TextSpan(style: style, children: children);
}
```

#### 4. 获取原始文本

```dart
/// 获取原始文本（用于发送）
String get originalText {
  String result = text;
  for (var entry in _emoteMap.entries) {
    result = result.replaceAll(entry.key, entry.value.originalText);
  }
  return result;
}
```

### 工作原理

1. **表情插入**：用户选择表情时，生成一个 Unicode 私有区域字符作为占位符，插入到文本中
2. **占位符映射**：保存占位符到表情信息的映射
3. **渲染**：`buildTextSpan` 遍历文本，遇到占位符时渲染为表情图片
4. **发送**：使用 `originalText` 获取原始文本，将占位符替换回原始表情文本

### 为什么这样可行？

1. **光标位置正确**：占位符只有一个字符，`WidgetSpan` 也只占用一个字符位置，两者一致
2. **文本输入正常**：普通文本直接插入，不受表情影响
3. **删除正常**：删除占位符时，自动从映射中移除对应的表情信息
4. **发送正确**：发送时将占位符替换回原始表情文本

### 优点

- ✅ 表情在输入框中显示为图片
- ✅ 光标位置正确
- ✅ 文本输入正常
- ✅ 删除正常
- ✅ 发送内容正确
- ✅ 代码简洁易懂

### 缺点

- ⚠️ 占位符字符在某些情况下可能显示为方块（如果字体不支持）
- ⚠️ 复制粘贴时会丢失表情信息（占位符会被复制，但映射不会）

## 测试验证

修复后，用户应该能够：
1. ✅ 点击表情面板选择表情
2. ✅ 表情在输入框中显示为图片
3. ✅ 正常输入其他文本内容
4. ✅ 在表情后输入文本，文本正确显示在表情后面
5. ✅ 正常删除表情和文本
6. ✅ 发送评论后，表情在评论区自动渲染为图片

## 相关文件

- `lib/common/widgets/rich_text/controller.dart` - 富文本控制器
- `lib/common/widgets/rich_text/models.dart` - 数据模型
- `lib/pages/video/reply_new/view_enhanced.dart` - 表情插入逻辑

## 工作原理

### 1. 客户端插入
客户端只需要将表情文本（如 `[doge]`）插入到评论内容中。

### 2. 服务器端识别
B站服务器在接收到评论后，会：
1. 扫描评论文本，识别表情转义符（格式：`[表情名]`）
2. 将表情转义符映射到对应的表情图片 URL
3. 在返回评论数据时，包含表情信息

### 3. 客户端渲染
当显示评论时，客户端会：
1. 解析评论中的表情信息
2. 将表情转义符替换为表情图片
3. 在评论区正确显示表情

### 示例流程

**发送评论：**
```
客户端 → 服务器
{
  "message": "这个视频真好看[doge]",
  "type": 1,
  "oid": 123456
}
```

**服务器返回：**
```json
{
  "code": 0,
  "data": {
    "reply": {
      "content": {
        "message": "这个视频真好看[doge]",
        "emote": {
          "[doge]": {
            "id": 26,
            "text": "[doge]",
            "url": "http://i0.hdslb.com/bfs/emote/xxx.png"
          }
        }
      }
    }
  }
}
```

**客户端显示：**
```
这个视频真好看 🐶
```

## B站表情 API 格式

根据 bilibili-API-collect 文档，评论中的表情使用特殊的转义符格式：

### 发送格式
```json
{
  "message": "测试test[泠鸢yousa_awsl]",
  "type": 1,
  "oid": 243322853
}
```

### 返回格式
```json
{
  "emote": {
    "[泠鸢yousa_awsl]": {
      "id": 2086,
      "package_id": 93,
      "text": "[泠鸢yousa_awsl]",
      "url": "http://i0.hdslb.com/bfs/emote/xxx.png",
      "meta": {
        "size": 2
      }
    }
  }
}
```

## 富文本内容格式

发送评论时，如果使用富文本 API，需要提供 `rich_text` 参数：

```json
{
  "rich_text": [
    {
      "raw_text": "测试文本",
      "type": 1,
      "biz_id": ""
    },
    {
      "raw_text": "[happy]",
      "type": 9,
      "biz_id": ""
    }
  ]
}
```

类型代码：
- `1` - 普通文本
- `2` - @提及
- `4` - 投票
- `9` - 表情

## 测试验证

修复后，用户应该能够：
1. ✅ 点击表情面板选择表情
2. ✅ 表情以文本形式（如 `[doge]`）插入到输入框
3. ✅ 正常输入其他文本内容
4. ✅ 正常删除表情和文本
5. ✅ 发送评论后，表情在评论区自动渲染为图片

## 相关文件

- `lib/pages/video/reply_new/view_enhanced.dart` - 修复表情插入逻辑
- `lib/common/widgets/rich_text/controller.dart` - 富文本控制器
- `lib/common/widgets/rich_text/models.dart` - 富文本数据模型

## 为什么不使用富文本控制器？

虽然我们创建了 `RichTextEditingController`，但在表情处理上遇到了以下问题：

### 问题 1: 文本同步复杂
富文本控制器需要同时维护：
- `items` 列表（富文本项）
- `text` 字符串（显示文本）
- `selection` 光标位置

当用户输入、删除、选择时，这三者的同步非常复杂，容易出错。

### 问题 2: 编辑体验差
使用富文本控制器后：
- 普通文本输入不显示（同步问题）
- 删除操作异常（范围管理问题）
- 光标位置错乱（选择更新问题）

### 问题 3: 过度设计
对于 B站的表情系统，客户端不需要做特殊处理：
- 表情转义符是普通文本
- 服务器端自动识别和渲染
- 客户端只需要正确显示服务器返回的结果

### 简单就是美
当前的简单实现：
- ✅ 代码简洁易懂
- ✅ 编辑体验流畅
- ✅ 与旧版行为一致
- ✅ 完全满足需求

## 富文本控制器的适用场景

`RichTextEditingController` 更适合以下场景：
1. **实时预览** - 需要在输入框中实时显示富文本效果
2. **复杂格式** - 需要支持多种格式（粗体、斜体、链接等）
3. **所见即所得** - 编辑器需要与最终显示效果一致

对于 B站评论的表情功能，服务器端渲染的方式更简单可靠。

## 未来优化方向

如果需要增强表情体验，可以考虑：

### 1. 表情预览提示
在输入框中，当光标在表情文本上时，显示表情图片预览：
```dart
// 检测光标位置的表情
if (isEmoteText(cursorPosition)) {
  showEmotePreview(emoteUrl);
}
```

### 2. 表情自动补全
输入 `[` 时，显示表情建议列表：
```dart
if (text.endsWith('[')) {
  showEmoteSuggestions();
}
```

### 3. 常用表情快捷访问
记录用户最常用的表情，放在表情面板顶部。

这些优化都可以在不使用复杂富文本控制器的情况下实现。
