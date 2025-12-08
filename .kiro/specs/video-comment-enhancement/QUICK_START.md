# 富文本评论功能 - 快速开始

## 功能概览

✅ **表情插入** - 选择表情自动插入到光标位置
✅ **图片上传** - 支持最多 9 张图片，自动上传到 BFS
✅ **视频进度** - 插入当前播放位置的时间戳
✅ **@提及** - 支持 @用户（开发中）
✅ **正确的文本管理** - 所有元素位置准确

## 使用方式

### 1. 选择表情

用户点击表情按钮 → 选择表情 → 自动插入到光标位置

```dart
void onChooseEmote(dynamic package, emote_model.Emote emote) {
  if (emote.text == null) return;
  onInsertText(
    emote.text!,
    RichTextType.emoji,
    rawText: emote.text!,
  );
}
```

### 2. 上传图片

用户点击图片按钮 → 选择图片 → 显示预览 → 发送时自动上传

```dart
Future<void> onPickImage() async {
  final ImagePicker picker = ImagePicker();
  final List<XFile> images = await picker.pickMultiImage();
  for (var image in images) {
    pathList.add(image.path);
  }
}
```

### 3. 插入视频进度

用户点击"更多" → 选择"视频进度" → 插入时间戳

```dart
void onInsertVideoProgress() {
  final duration = const Duration(seconds: 123);
  final timeStr = _formatDuration(duration);
  onInsertText(timeStr, RichTextType.common, rawText: timeStr);
}
```

## 数据结构

### RichTextItem

```dart
class RichTextItem {
  RichTextType type;      // 元素类型
  String text;            // 显示文本
  String? rawText;        // 原始文本（用于提交）
  TextRange range;        // 文本范围
  Emote? emote;          // 表情信息
  String? id;            // 关联ID
}
```

### RichTextType

```dart
enum RichTextType {
  text,       // 普通文本
  composing,  // 输入法组合文本
  at,         // @用户
  emoji,      // 表情
  vote,       // 投票
  common      // 通用富文本（视频进度等）
}
```

## 提交流程

1. **收集图片**
   - 遍历 `pathList`
   - 调用 `MsgHttp.uploadBfs()` 上传每张图片
   - 收集返回的图片元数据

2. **构建评论**
   - 获取文本：`_replyContentController.text`
   - 获取富文本项：`_replyContentController.items`
   - 构建 API 请求

3. **发送评论**
   - 调用 `VideoHttp.replyAdd()`
   - 传递 `pictures` 参数
   - 处理响应

## 关键文件

| 文件 | 说明 |
|------|------|
| `lib/common/widgets/rich_text/models.dart` | 数据模型 |
| `lib/common/widgets/rich_text/controller.dart` | 控制器 |
| `lib/common/widgets/rich_text/text_field.dart` | 文本字段 |
| `lib/pages/video/reply_new/view_enhanced.dart` | UI 实现 |

## 常见问题

### Q: 表情为什么显示为文本而不是图片？
A: 这是设计选择。B站服务器会自动识别 `[emote_name]` 格式并渲染为图片。实时预览需要 Flutter 版本升级。

### Q: 如何修改表情插入格式？
A: 修改 `onChooseEmote()` 中的 `emote.text!` 即可。

### Q: 支持多少张图片？
A: 最多 9 张，可在 `imageLimit` 常量中修改。

### Q: 如何获取当前播放位置？
A: 需要从 `PlPlayerController` 获取，目前使用模拟数据。

## 测试清单

- [ ] 输入文本 + 插入表情 + 输入文本
- [ ] 连续插入多个表情
- [ ] 在表情后输入文本（验证文本不被插入到 `[]` 中）
- [ ] 上传 1-9 张图片
- [ ] 插入视频进度
- [ ] 发送评论并验证显示效果

## 下一步

1. 实现 @提及功能
2. 获取真实的播放位置
3. 实现视频截图功能
4. 升级 Flutter 版本以支持实时表情预览
