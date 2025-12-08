# Design Document

## Overview

本设计文档描述了 pilipalax 视频评论功能的增强方案。核心目标是实现一个完整的富文本评论系统，支持文本、表情、图片、@用户、视频进度、视频截图等多种内容类型。设计参考 piliplus 项目的成熟实现，采用富文本编辑器架构，提供流畅的用户体验。

主要特性：
- 富文本编辑器：支持多种内容类型的混合编辑
- 图片管理：支持多图上传、预览、裁剪、删除
- 用户提及：@用户搜索和插入
- 视频相关：插入视频进度、截图、视频/专栏链接
- 表情系统：文本表情和图片表情
- 工具栏系统：可扩展的功能面板架构
- 鸿蒙系统优化：针对鸿蒙手机系统的触摸交互和UI适配

## Architecture

### 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    VideoReplyNewDialog                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           RichTextEditingController                    │  │
│  │  - items: List<RichTextItem>                          │  │
│  │  - buildTextSpan()                                    │  │
│  │  - syncRichText()                                     │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              RichTextField                             │  │
│  │  - 富文本输入框                                         │  │
│  │  - 支持表情、@用户等富文本显示                          │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              ImagePreviewList                          │  │
│  │  - 图片缩略图列表                                       │  │
│  │  - 图片预览、编辑、删除                                 │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                 Toolbar                                │  │
│  │  [键盘] [表情] [@] [更多] ... [取消] [发送]            │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                 Panel Area                             │  │
│  │  - EmotePanel (表情面板)                               │  │
│  │  - MorePanel (更多功能面板)                            │  │
│  │  - MentionPanel (用户搜索面板)                         │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 数据流

```
用户输入 → RichTextEditingController → RichTextItem列表 → 显示
                                                    ↓
                                              提交时转换
                                                    ↓
                                          API JSON格式
```

## Components and Interfaces

### 1. RichTextEditingController

富文本编辑控制器，继承自 TextEditingController，管理富文本内容。

```dart
class RichTextEditingController extends TextEditingController {
  // 富文本项列表
  final List<RichTextItem> items = <RichTextItem>[];
  
  // @用户回调
  final VoidCallback? onMention;
  
  // 纯文本内容（用于显示）
  String get plainText;
  
  // 原始文本内容（用于提交）
  String get rawText;
  
  // 同步富文本变化
  void syncRichText(TextEditingDelta delta);
  
  // 构建文本样式
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  });
}
```

### 2. RichTextItem

富文本项，表示评论中的一个内容片段。

```dart
enum RichTextType { 
  text,      // 普通文本
  composing, // 输入法组合文本
  at,        // @用户
  emoji,     // 表情
  vote,      // 投票
  common     // 通用富文本
}

class RichTextItem {
  late RichTextType type;
  late String text;           // 显示文本
  String? _rawText;           // 原始文本
  late TextRange range;       // 文本范围
  Emote? emote;              // 表情信息
  String? id;                // 关联ID（用户ID、投票ID等）
  
  String get rawText => _rawText ?? text;
  bool get isText => type == RichTextType.text;
  bool get isComposing => type == RichTextType.composing;
  bool get isRich => !isText && !isComposing;
}
```

### 3. Emote

表情数据模型。

```dart
class Emote {
  late String url;      // 表情图片URL
  late double width;    // 宽度
  late double height;   // 高度
}
```

### 4. RichTextField

富文本输入框组件，支持富文本显示和编辑。

```dart
class RichTextField extends StatefulWidget {
  final RichTextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final TextStyle? style;
  // ... 其他TextField参数
}
```

### 5. VideoReplyNewDialog

评论发布对话框，整合所有功能。

```dart
class VideoReplyNewDialog extends StatefulWidget {
  final int? oid;              // 目标ID
  final int? root;             // 根评论ID
  final int? parent;           // 父评论ID
  final ReplyType? replyType;  // 评论类型
  final ReplyItemModel? replyItem; // 回复的评论
}

class _VideoReplyNewDialogState extends State<VideoReplyNewDialog> {
  late RichTextEditingController _replyContentController;
  late FocusNode replyContentFocusNode;
  late RxList<String> pathList; // 图片路径列表
  
  String toolbarType = 'input'; // 当前工具栏类型
  double emoteHeight = 0.0;     // 表情面板高度
  double keyboardHeight = 0.0;  // 键盘高度
  
  // 选择图片
  void onPickImage();
  
  // 裁剪图片
  Future<void> onCropImage(int index);
  
  // 选择表情
  void onChooseEmote(dynamic emote, double? width, double? height);
  
  // @用户
  Future<void> onMention([bool fromClick = false]);
  
  // 插入文本
  void onInsertText(
    String text,
    RichTextType type, {
    String? rawText,
    Emote? emote,
    String? id,
    bool? fromClick,
  });
  
  // 插入视频进度
  void onInsertVideoProgress();
  
  // 插入视频截图
  Future<void> onInsertScreenshot();
  
  // 获取富文本内容
  List<Map<String, dynamic>>? getRichContent();
  
  // 提交评论
  Future<void> onPublish();
}
```

### 6. EmotePanel

表情选择面板。

```dart
class EmotePanel extends StatefulWidget {
  final Function(Packages package, Emote emote) onChoose;
}
```

### 7. MentionPanel

用户搜索和选择面板。

```dart
class DynMentionPanel {
  static Future<dynamic> onDynMention(
    BuildContext context, {
    required double offset,
    required Function(double) callback,
  });
}
```

### 8. MorePanel

更多功能面板，包含图片、视频进度、截图等功能。

```dart
class MorePanel extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onInsertProgress;
  final VoidCallback onInsertScreenshot;
  final VoidCallback onInsertVideo;
}
```

## Data Models

### RichTextItem 数据结构

```dart
{
  "type": RichTextType,      // 类型
  "text": String,            // 显示文本
  "rawText": String?,        // 原始文本
  "range": TextRange,        // 文本范围
  "emote": Emote?,          // 表情信息
  "id": String?             // 关联ID
}
```

### API 提交格式

根据 bilibili API 文档，评论提交时需要将富文本转换为以下格式：

```json
[
  {
    "raw_text": "普通文本",
    "type": 1,
    "biz_id": ""
  },
  {
    "raw_text": "@用户名",
    "type": 2,
    "biz_id": "用户ID"
  },
  {
    "raw_text": "[表情文本]",
    "type": 9,
    "biz_id": ""
  },
  {
    "raw_text": "投票标题",
    "type": 4,
    "biz_id": "投票ID"
  }
]
```

类型代码：
- 1: 普通文本
- 2: @用户
- 4: 投票
- 9: 表情

### 图片上传数据

```dart
{
  "img_width": int,      // 图片宽度
  "img_height": int,     // 图片高度
  "img_size": double,    // 图片大小
  "img_src": String      // 图片URL
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. 
Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: 富文本项列表一致性

*For any* 富文本编辑操作（插入、删除、替换），RichTextItem 列表的文本范围应该连续且不重叠，所有项的文本拼接应该等于控制器的文本内容
**Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5**

### Property 2: 图片数量限制

*For any* 图片选择操作，当已选择图片数量达到上限（9张）时，系统应该阻止继续选择并显示提示
**Validates: Requirements 1.6**

### Property 3: 表情插入正确性

*For any* 表情选择操作，文本表情应该插入表情文本，图片表情应该插入占位符并记录表情信息
**Validates: Requirements 6.2, 6.3**

### Property 4: @用户格式正确性

*For any* @用户操作，插入的文本应该是 "@用户名 " 格式，并且包含用户ID信息
**Validates: Requirements 2.3, 2.5**

### Property 5: 富文本转换正确性

*For any* 富文本内容，转换为 API 格式时应该保持内容完整性，类型映射正确
**Validates: Requirements 10.6**

### Property 6: 图片上传顺序性

*For any* 包含图片的评论提交，应该先完成所有图片上传，然后再提交评论内容
**Validates: Requirements 1.7**

### Property 7: 发送按钮状态

*For any* 评论内容变化，当内容为空且无图片时发送按钮应该禁用，否则应该启用
**Validates: Requirements 8.5, 8.6**

### Property 8: 面板高度一致性

*For any* 面板切换操作，表情面板和更多功能面板的高度应该与键盘高度一致
**Validates: Requirements 7.4, 7.6**

### Property 9: 光标位置正确性

*For any* 富文本插入操作，插入后光标应该位于插入内容的末尾
**Validates: Requirements 2.3, 3.2, 6.2, 6.3**

### Property 10: 图片删除后状态更新

*For any* 图片删除操作，如果删除后图片列表为空且文本内容为空，发送按钮应该禁用
**Validates: Requirements 1.4, 8.5**

## Error Handling

### 1. 图片上传失败

- 场景：网络错误、文件过大、格式不支持
- 处理：显示错误提示，取消评论提交，保留用户输入内容
- 用户反馈：Toast 提示具体错误信息

### 2. 评论提交失败

- 场景：网络错误、内容违规、频率限制
- 处理：显示错误提示，保留用户输入内容和已上传图片
- 用户反馈：Toast 提示 API 返回的错误信息

### 3. 图片选择失败

- 场景：权限不足、文件读取错误
- 处理：显示错误提示，不影响已选择的图片
- 用户反馈：Toast 提示错误信息

### 4. 用户搜索失败

- 场景：网络错误、搜索超时
- 处理：显示错误提示，允许用户重试
- 用户反馈：在搜索面板中显示错误状态

### 5. 视频截图失败

- 场景：视频未加载、播放器错误
- 处理：显示错误提示，不影响其他功能
- 用户反馈：Toast 提示错误信息

### 6. 富文本解析错误

- 场景：数据格式异常、类型不匹配
- 处理：降级为普通文本处理，记录错误日志
- 用户反馈：不影响用户操作，静默处理

## Testing Strategy

### Unit Tests

1. **RichTextEditingController 测试**
   - 测试文本插入、删除、替换操作
   - 测试富文本项列表的更新逻辑
   - 测试光标位置计算
   - 测试文本范围计算

2. **RichTextItem 测试**
   - 测试不同类型的富文本项创建
   - 测试文本范围更新
   - 测试富文本项合并和分割

3. **富文本转换测试**
   - 测试 RichTextItem 列表转换为 API 格式
   - 测试不同类型的映射正确性
   - 测试边界情况（空列表、单项、多项）

4. **图片管理测试**
   - 测试图片添加、删除
   - 测试图片数量限制
   - 测试图片路径管理

5. **表情处理测试**
   - 测试文本表情插入
   - 测试图片表情插入
   - 测试表情占位符处理

### Property-Based Tests

使用 Dart 的 `test` 包和 `faker` 包进行属性测试。

1. **Property 1: 富文本项列表一致性测试**
   - 生成随机的编辑操作序列
   - 验证每次操作后列表的一致性
   - 验证文本拼接结果

2. **Property 2: 图片数量限制测试**
   - 生成随机数量的图片选择操作
   - 验证数量限制的正确性

3. **Property 5: 富文本转换正确性测试**
   - 生成随机的富文本项列表
   - 验证转换后的 JSON 格式正确性
   - 验证类型映射正确性

4. **Property 7: 发送按钮状态测试**
   - 生成随机的内容变化
   - 验证发送按钮状态的正确性

### Integration Tests

1. **完整评论流程测试**
   - 打开评论对话框
   - 输入文本
   - 添加图片
   - 选择表情
   - @用户
   - 提交评论
   - 验证评论显示

2. **图片上传流程测试**
   - 选择多张图片
   - 验证缩略图显示
   - 删除部分图片
   - 提交评论
   - 验证图片上传和评论提交

3. **富文本编辑测试**
   - 混合输入文本、表情、@用户
   - 验证显示效果
   - 验证光标位置
   - 提交评论
   - 验证评论内容

4. **面板切换测试**
   - 切换键盘、表情、更多面板
   - 验证面板显示和隐藏
   - 验证面板高度
   - 验证焦点状态

## Implementation Notes

### 1. 富文本编辑器实现

参考 piliplus 的实现，使用自定义的 RichTextEditingController 和 RichTextField。关键点：

- 使用 TextEditingDelta 监听编辑操作
- 维护 RichTextItem 列表表示富文本内容
- 重写 buildTextSpan 方法自定义文本显示
- 处理光标位置和选择范围

### 2. 图片管理实现

- 使用 image_picker 选择图片
- 使用 image_cropper 裁剪图片（移动端）
- 使用 RxList 管理图片列表，支持响应式更新
- 移动端临时文件需要在 dispose 时清理

### 3. 表情系统实现

- 复用现有的 EmotePanel 组件
- 文本表情直接插入文本
- 图片表情使用 Unicode 占位符 '\uFFFC'
- 在 buildTextSpan 中将占位符替换为 WidgetSpan 显示图片

### 4. @用户实现

- 实现用户搜索面板
- 支持关键词搜索
- 支持单选和多选
- 插入时自动添加空格
- 处理 @ 符号自动触发

### 5. 视频相关功能实现

- 视频进度：从 PlPlayerController 获取当前播放位置
- 视频截图：使用视频播放器的截图 API
- 视频链接：实现内容搜索面板

### 6. 工具栏和面板系统

- 使用状态管理切换不同面板
- 监听键盘高度变化
- 使用 WidgetsBindingObserver 监听视图变化
- 使用防抖处理键盘高度更新

### 7. API 集成

- 图片上传使用 BFS 服务
- 评论提交使用现有的 replyAdd API
- 添加富文本内容参数
- 处理 API 错误响应

### 8. 鸿蒙系统适配

- 针对鸿蒙手机系统优化触摸交互
- 支持长按删除图片
- 支持图片裁剪功能
- 优化触摸反馈和手势操作
- 适配鸿蒙系统的键盘行为

### 9. 性能优化

- 使用 EasyThrottle 防抖处理频繁操作
- 图片缩略图使用低质量过滤
- 延迟加载表情面板
- 使用 Obx 局部刷新

### 10. 状态管理

- 使用 GetX 的响应式状态管理
- pathList 使用 RxList
- toolbarType 使用 String 状态
- enablePublish 使用 RxBool

## File Structure

```
lib/pages/video/reply_new/
├── view.dart                          # 主对话框
├── controller.dart                    # 控制器（如需要）
├── widgets/
│   ├── rich_text_field.dart          # 富文本输入框
│   ├── image_preview_list.dart       # 图片预览列表
│   ├── toolbar.dart                  # 工具栏
│   ├── more_panel.dart               # 更多功能面板
│   └── mention_panel.dart            # 用户搜索面板

lib/common/widgets/
├── rich_text/
│   ├── controller.dart               # 富文本控制器
│   ├── text_field.dart               # 富文本输入框基础组件
│   └── models.dart                   # 富文本数据模型

lib/http/
├── reply.dart                        # 评论 API（更新）
└── msg.dart                          # 图片上传 API（更新）

lib/models/video/reply/
└── rich_text.dart                    # 富文本数据模型
```

## Dependencies

需要添加的依赖：

```yaml
dependencies:
  # 图片选择
  image_picker: ^latest
  
  # 图片裁剪
  image_cropper: ^latest
  
  # 防抖节流
  easy_debounce: ^latest
  
  # 状态管理（已有）
  get: ^latest
  
  # 响应式编程（已有）
  flutter_smart_dialog: ^latest
```

## Migration Plan

### Phase 1: 基础架构（1-2天）

1. 创建富文本数据模型
2. 实现 RichTextEditingController
3. 实现 RichTextField 基础组件
4. 编写单元测试

### Phase 2: 图片功能（1-2天）

1. 实现图片选择功能
2. 实现图片预览列表
3. 实现图片裁剪（移动端）
4. 实现图片删除
5. 实现图片上传 API
6. 编写单元测试和集成测试

### Phase 3: 表情和@用户（1-2天）

1. 集成表情面板
2. 实现表情插入逻辑
3. 实现用户搜索面板
4. 实现@用户插入逻辑
5. 编写单元测试

### Phase 4: 视频相关功能（1天）

1. 实现视频进度插入
2. 实现视频截图
3. 实现视频/专栏链接插入
4. 编写单元测试

### Phase 5: 工具栏和面板系统（1天）

1. 实现工具栏组件
2. 实现更多功能面板
3. 实现面板切换逻辑
4. 实现键盘高度适配
5. 编写集成测试

### Phase 6: API 集成和测试（1天）

1. 更新评论提交 API
2. 实现富文本转换逻辑
3. 处理错误情况
4. 完整流程测试
5. 性能优化

### Phase 7: UI 优化和鸿蒙系统适配（1天）

1. UI 细节优化
2. 鸿蒙系统触摸交互优化
3. 键盘行为适配
4. 动画效果优化
5. 最终测试

总计：7-9天
