# 表情实时显示实现

## 问题描述

用户希望在评论输入框中实时显示表情图片，而不是文本形式的 `[happy]`，类似 PiliPlus 的实现。

## 解决方案

实现了一个完整的富文本系统，支持在输入框中使用 `WidgetSpan` 渲染表情图片。

## 核心实现

### 1. 表情数据模型 (`lib/common/widgets/rich_text/models.dart`)

```dart
class Emote {
  late String url;      // 表情图片URL
  late double width;    // 宽度
  late double height;   // 高度

  Emote({
    required this.url,
    required this.width,
    double? height,
  }) : height = height ?? width;
}
```

### 2. 富文本控制器 (`lib/common/widgets/rich_text/controller.dart`)

#### 关键方法：`insertEmote`

```dart
void insertEmote(String text, Emote emote) {
  // 在光标位置插入表情
  // 创建 RichTextItem，类型为 emoji
  // 更新所有后续项的范围
  // 更新控制器的文本和光标位置
}
```

#### 关键方法：`buildTextSpan`

```dart
@override
TextSpan buildTextSpan({
  required BuildContext context,
  TextStyle? style,
  required bool withComposing,
}) {
  // 遍历 items，根据类型渲染
  // 对于 emoji 类型，使用 WidgetSpan 渲染表情图片
  case RichTextType.emoji:
    final emote = e.emote;
    if (emote != null && emote.url.isNotEmpty) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Image.network(
            emote.url,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text(e.text);
            },
          ),
        ),
      );
    }
    return TextSpan(text: e.text);
}
```

#### 同步机制：`_syncItems`

```dart
void _syncItems() {
  // 当文本变化时，同步 items 列表
  // 移除超出范围的项
  // 更新项的范围
  // 确保 items 与文本内容一致
}
```

### 3. 表情插入 (`lib/pages/video/reply_new/view_enhanced.dart`)

```dart
void onChooseEmote(dynamic package, emote_model.Emote emote) {
  if (emote.text == null || emote.url == null) {
    return;
  }

  // 创建表情对象
  final emotePair = rich_text_models.Emote(
    url: emote.url!,
    width: 22,
    height: 22,
  );

  // 插入表情
  _replyContentController.insertEmote(emote.text!, emotePair);
  enablePublish.value = true;
}
```

## 工作流程

### 1. 用户选择表情

用户点击表情面板中的表情，触发 `onChooseEmote` 回调。

### 2. 创建表情对象

从 B站 API 返回的表情数据中提取 URL、宽度、高度等信息，创建 `Emote` 对象。

### 3. 插入表情

调用 `insertEmote` 方法：
- 在光标位置插入表情文本（如 `[doge]`）
- 创建 `RichTextItem`，类型为 `emoji`，包含表情对象
- 更新所有后续项的范围
- 更新控制器的文本和光标位置

### 4. 渲染表情

`TextField` 调用 `buildTextSpan` 方法：
- 遍历 `items` 列表
- 对于 `emoji` 类型的项，使用 `WidgetSpan` 渲染表情图片
- 其他类型的项正常渲染为文本

### 5. 同步 items

当用户编辑文本时（删除、修改等），`_syncItems` 方法自动：
- 检查 items 是否仍在文本范围内
- 移除超出范围的项
- 更新项的范围

## 关键特性

### ✅ 实时显示表情图片

表情在输入框中实时显示为图片，而不是文本。

### ✅ 正确处理删除

当用户删除表情时，对应的 `RichTextItem` 会被自动移除。

### ✅ 光标定位

光标可以正确定位在表情前后，支持正常的文本编辑。

### ✅ 发送时保留文本

发送评论时，表情仍然以文本形式（如 `[doge]`）发送给服务器，B站会自动识别并渲染。

### ✅ 错误处理

如果表情图片加载失败，会自动降级显示为文本。

## 与 PiliPlus 的对比

| 功能 | PiliPlus | 我们的实现 |
|------|---------|---------|
| 表情实时显示 | ✅ | ✅ |
| 使用 WidgetSpan | ✅ | ✅ |
| 复杂的 TextEditingDelta 处理 | ✅ (1000+ 行) | ❌ (简化版) |
| 支持多种富文本类型 | ✅ | ✅ |
| 代码复杂度 | 高 | 中 |
| 维护性 | 低 | 高 |

我们的实现更简洁，专注于表情功能，避免了 PiliPlus 的过度设计。

## 测试验证

修复后，用户应该能够：

1. ✅ 点击表情面板选择表情
2. ✅ 表情在输入框中实时显示为图片
3. ✅ 正常输入其他文本内容
4. ✅ 正常删除表情和文本
5. ✅ 发送评论后，表情在评论区自动渲染为图片

## 相关文件

- `lib/common/widgets/rich_text/controller.dart` - 富文本控制器
- `lib/common/widgets/rich_text/models.dart` - 数据模型
- `lib/common/widgets/rich_text/text_field.dart` - 富文本输入框
- `lib/pages/video/reply_new/view_enhanced.dart` - 表情插入逻辑

## 未来优化

1. **缓存表情图片** - 使用 `CachedNetworkImage` 缓存表情图片
2. **表情预加载** - 预加载常用表情
3. **表情搜索** - 支持表情搜索和快速访问
4. **自定义表情大小** - 允许用户调整表情大小

