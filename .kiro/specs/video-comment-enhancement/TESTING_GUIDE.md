# 视频评论增强功能测试指南

## 测试前准备

### 1. 代码问题修复状态
✅ 已修复所有编译警告：
- 修复了 `lib/http/msg.dart` 中的重复键问题
- 修复了未使用变量 `fileSize` 的警告
- 修复了 `File.delete().catchError()` 的返回类型问题

### 2. 当前实现状态

#### 已完成的核心功能
- ✅ 富文本数据模型 (`RichTextItem`, `Emote`)
- ✅ 富文本编辑控制器 (`RichTextEditingController`)
- ✅ 富文本输入框组件 (`RichTextField`)
- ✅ 图片预览列表组件 (`ImagePreviewList`)
- ✅ 用户提及面板 (`MentionPanel`)
- ✅ 图片上传 API (`MsgHttp.uploadBfs`)
- ✅ 增强评论对话框 (`VideoReplyNewDialogEnhanced`)

#### 待完善的功能（标记为 TODO）
- ⏳ 图片选择功能（需要 image_picker 依赖）
- ⏳ 图片裁剪功能（需要 image_cropper 依赖）
- ⏳ 图片预览功能
- ⏳ 视频进度获取（需要 PlPlayerController 集成）
- ⏳ 视频截图功能（需要视频播放器 API）
- ⏳ 用户搜索 API（当前使用模拟数据）

## 测试方法

### 方法 1: 直接运行应用（推荐）

```bash
# 使用 fvm 运行 release 版本
fvm flutter run --release

# 或者运行 debug 版本（更快）
fvm flutter run
```

### 方法 2: 集成到现有评论功能

要测试 `VideoReplyNewDialogEnhanced`，需要在现有代码中替换 `VideoReplyNewDialog`。

#### 临时测试集成步骤：

1. **在 `lib/pages/video/reply_new/index.dart` 中导出新组件**：
```dart
library video_reply_new;

export 'view.dart';
export 'view_enhanced.dart';  // 添加这行
```

2. **在测试位置替换对话框**（例如 `lib/pages/video/reply/view.dart`）：
```dart
// 原代码
import 'package:PiliPalaX/pages/video/reply_new/index.dart';

// 在 showModalBottomSheet 中
return VideoReplyNewDialog(  // 原来的
  oid: _videoReplyController.aid,
  // ...
);

// 改为
return VideoReplyNewDialogEnhanced(  // 新的增强版
  oid: _videoReplyController.aid,
  // ...
);
```

### 方法 3: 静态代码分析

```bash
# 检查语法错误
fvm flutter analyze lib/common/widgets/rich_text/
fvm flutter analyze lib/pages/video/reply_new/

# 检查特定文件
fvm flutter analyze lib/pages/video/reply_new/view_enhanced.dart
```

## 测试场景

### 1. 基础文本输入测试
- [ ] 打开评论对话框
- [ ] 输入普通文本
- [ ] 验证发送按钮状态（有内容时启用）
- [ ] 提交评论
- [ ] 验证评论成功发送

### 2. 表情功能测试
- [ ] 点击表情按钮
- [ ] 选择表情
- [ ] 验证表情插入到光标位置
- [ ] 验证表情在输入框中正确显示
- [ ] 提交包含表情的评论

### 3. 键盘和面板切换测试
- [ ] 点击输入框，验证键盘弹出
- [ ] 点击表情按钮，验证表情面板显示
- [ ] 点击键盘按钮，验证键盘重新显示
- [ ] 验证面板高度自适应

### 4. 发送按钮状态测试
- [ ] 空内容时按钮禁用
- [ ] 输入文本后按钮启用
- [ ] 删除所有文本后按钮禁用
- [ ] 只有空格时按钮禁用

### 5. 图片功能测试（需要完善依赖）
- [ ] 点击图片按钮（当前显示"开发中"提示）
- [ ] 验证提示信息正确显示

### 6. 视频进度插入测试（使用模拟数据）
- [ ] 点击视频进度按钮
- [ ] 验证时间戳插入（当前为模拟的 02:03）
- [ ] 验证时间戳格式正确

### 7. 错误处理测试
- [ ] 网络错误时的提示
- [ ] 提交失败时的错误处理
- [ ] 验证内容保留（失败后不清空）

## 已知限制

### 1. 依赖缺失
以下功能需要添加依赖才能完整测试：
- `image_picker`: 图片选择
- `image_cropper`: 图片裁剪

### 2. API 集成
以下功能需要实际 API 集成：
- 用户搜索（当前使用模拟数据）
- 图片上传到 BFS（API 端点可能需要验证）

### 3. 播放器集成
以下功能需要视频播放器集成：
- 获取当前播放位置
- 视频截图

## 测试结果记录

### 编译测试
- [x] 代码无语法错误
- [x] 所有警告已修复
- [ ] Release 版本编译成功
- [ ] Debug 版本编译成功

### 功能测试
- [ ] 基础文本输入
- [ ] 表情选择和插入
- [ ] 键盘/面板切换
- [ ] 发送按钮状态管理
- [ ] 评论提交
- [ ] 错误处理

### 性能测试
- [ ] 键盘弹出流畅度
- [ ] 面板切换流畅度
- [ ] 输入响应速度
- [ ] 内存使用正常

## 下一步行动

### 立即可测试
1. 运行 `fvm flutter run --release` 启动应用
2. 导航到视频页面
3. 临时替换评论对话框为 `VideoReplyNewDialogEnhanced`
4. 测试基础功能

### 需要完善
1. 添加 `image_picker` 和 `image_cropper` 依赖
2. 实现用户搜索 API 调用
3. 集成视频播放器 API
4. 完善图片选择和裁剪功能

## 回滚方案

如果测试发现问题，可以快速回滚：
1. 保持原有的 `VideoReplyNewDialog` 不变
2. `VideoReplyNewDialogEnhanced` 作为独立组件存在
3. 不影响现有功能

## 测试命令快速参考

```bash
# 运行应用（推荐用于实际测试）
fvm flutter run --release

# 代码分析
fvm flutter analyze --no-pub

# 检查特定文件
fvm flutter analyze lib/pages/video/reply_new/view_enhanced.dart

# 清理并重新构建
fvm flutter clean
fvm flutter pub get
fvm flutter run
```
