# 视频进度高亮显示功能

## 功能说明

现在视频进度插入功能已经升级，具有以下特性：

### 1. 自动添加空格

视频进度在插入时会自动在前后加上空格，防止与其他文字混淆：

```
插入前：这是一个评论
插入后：这是一个评论 12:34 
```

### 2. 高亮显示

视频进度会在输入框中以**橙色高亮**显示，便于识别：

- **颜色**：橙色 (#FF7A45)
- **背景**：浅橙色 (#FFFFE8DC)
- **字重**：加粗 (FontWeight.w500)

### 3. 与 @提及兼容

视频进度高亮与 @提及高亮兼容：
- **@提及**：蓝色高亮 (#1890FF)
- **视频进度**：橙色高亮 (#FF7A45)

## 实现细节

### 1. 新增富文本类型

在 `lib/common/widgets/rich_text/models.dart` 中添加了新的富文本类型：

```dart
enum RichTextType {
  text,
  composing,
  at,
  emoji,
  vote,
  common,
  videoProgress, // 新增
}
```

### 2. 视频进度识别

在 `lib/common/widgets/rich_text/controller.dart` 中添加了 `_extractVideoProgress()` 方法：

```dart
/// 识别视频进度文本（格式：MM:SS 或 HH:MM:SS，前后有空格）
List<_VideoProgressSpan> _extractVideoProgress(String text) {
  final List<_VideoProgressSpan> progresses = [];
  // 匹配 MM:SS 或 HH:MM:SS 格式，前后必须有空格或在文本开头/结尾
  final regex = RegExp(r'(?:^|\s)(\d{1,2}:\d{2}(?::\d{2})?)(?:\s|$)');
  // ...
}
```

**正则表达式说明**：
- `(?:^|\s)` - 开头或空格（非捕获）
- `(\d{1,2}:\d{2}(?::\d{2})?)` - 捕获 MM:SS 或 HH:MM:SS
- `(?:\s|$)` - 空格或结尾（非捕获）

### 3. 高亮渲染

修改了 `_addTextWithMentions()` 方法来处理视频进度的高亮：

```dart
if (highlight.type == 'progress') {
  highlightStyle = (baseStyle ?? const TextStyle()).copyWith(
    color: const Color(0xFFFF7A45), // 橙色
    fontWeight: FontWeight.w500,
    backgroundColor: const Color(0xFFFFE8DC), // 浅橙色背景
  );
}
```

### 4. 自动添加空格

在 `lib/pages/video/reply_new/view_enhanced.dart` 中修改了 `onInsertVideoProgress()` 方法：

```dart
// 在前后加上空格，防止文字干扰
final progressText = ' $timeStr ';
```

## 使用示例

### 示例 1：基本使用

```
输入：这是一个很好的视频
点击"视频进度"按钮（当前播放位置：12:34）
结果：这是一个很好的视频 12:34 
```

### 示例 2：与 @提及结合

```
输入：@用户名 这是一个很好的视频
点击"视频进度"按钮（当前播放位置：05:20）
结果：@用户名 这是一个很好的视频 05:20 
```

显示效果：
- `@用户名` - 蓝色高亮
- `05:20` - 橙色高亮

### 示例 3：多个视频进度

```
输入：开头很好 中间也不错 结尾也可以
点击"视频进度"按钮三次（分别在 02:10, 08:45, 15:30）
结果：开头很好 02:10  中间也不错 08:45  结尾也可以 15:30 
```

显示效果：三个时间戳都会以橙色高亮显示

## 技术细节

### 正则表达式匹配

视频进度的正则表达式会匹配以下格式：

✅ 有效格式：
- ` 12:34 ` - 两位数分钟和秒
- ` 1:05 ` - 一位数分钟
- ` 01:05:30 ` - 完整的小时:分钟:秒
- `12:34` - 在文本开头
- `12:34 ` - 在文本结尾

❌ 无效格式：
- `12:34` - 没有前后空格（除非在开头/结尾）
- `12:345` - 秒数超过两位
- `12:3` - 秒数只有一位

### 高亮优先级

当文本中同时存在 @提及和视频进度时，按照出现顺序分别高亮，不会相互覆盖。

## 测试步骤

1. 打开任意视频
2. 等待视频开始播放
3. 点击评论按钮
4. 在输入框中输入一些文字
5. 点击"更多" → "视频进度"
6. 观察：
   - ✅ 视频进度前后有空格
   - ✅ 视频进度以橙色高亮显示
   - ✅ 其他文字保持正常颜色
7. 继续输入文字，再次点击"视频进度"
8. 观察：
   - ✅ 新的视频进度也被正确高亮
   - ✅ 之前的视频进度仍然保持高亮

## 相关文件

- `lib/common/widgets/rich_text/models.dart` - 富文本类型定义
- `lib/common/widgets/rich_text/controller.dart` - 富文本控制器和高亮逻辑
- `lib/pages/video/reply_new/view_enhanced.dart` - 视频进度插入逻辑

## 颜色参考

| 元素 | 颜色 | 十六进制 | RGB |
|------|------|---------|-----|
| @提及 | 蓝色 | #1890FF | rgb(24, 144, 255) |
| 视频进度 | 橙色 | #FF7A45 | rgb(255, 122, 69) |
| 视频进度背景 | 浅橙色 | #FFFFE8DC | rgb(255, 232, 220) |

## 未来改进

可能的改进方向：
- [ ] 支持点击视频进度跳转到该时间点
- [ ] 支持自定义高亮颜色
- [ ] 支持视频进度的编辑和删除
- [ ] 支持视频进度的复制
