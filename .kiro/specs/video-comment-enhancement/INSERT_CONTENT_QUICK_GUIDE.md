# 插入内容功能 - 快速参考

## 功能特点

✅ **历史记录**：首次打开自动显示最近使用的视频和专栏
✅ **搜索功能**：支持搜索新的视频或专栏
✅ **双标签页**：视频和专栏两种内容类型
✅ **自动保存**：选择后自动保存到历史记录
✅ **智能去重**：同一内容只保留最新的一条

## 使用方式

### 打开插入内容
1. 点击评论框下方的"更多"按钮
2. 点击"插入内容"

### 从历史记录选择
1. 页面打开时自动显示历史记录
2. 直接点击要插入的内容
3. 标题自动插入到评论框

### 搜索新内容
1. 在搜索框输入关键词
2. 点击搜索按钮或按 Enter
3. 从结果中选择内容
4. 内容自动保存到历史记录

### 清空搜索
- 点击搜索框右侧的清空按钮
- 返回显示历史记录

## 存储信息

- **位置**：本地存储（GStorage.localCache）
- **视频历史**：最多 10 条
- **专栏历史**：最多 10 条
- **保存内容**：标题、ID、描述

## 文件位置

- 搜索页面：`lib/pages/video/reply_new/widgets/insert_content_search.dart`
- 集成代码：`lib/pages/video/reply_new/view_enhanced.dart`

## 关键代码

### 打开搜索页面
```dart
Future<void> onInsertContent() async {
  final result = await Get.to<Map<String, String>>(
    const InsertContentSearchPage(),
  );
  // 处理返回结果...
}
```

### 历史记录键
```dart
static const String _videoHistoryKey = 'insert_content_video_history';
static const String _articleHistoryKey = 'insert_content_article_history';
```

## 测试建议

1. ✅ 首次打开时显示历史记录（如果有的话）
2. ✅ 搜索视频内容
3. ✅ 搜索专栏内容
4. ✅ 选择内容后自动插入标题
5. ✅ 验证历史记录自动保存
6. ✅ 验证同一内容不重复保存
7. ✅ 验证最多保存 10 条记录
8. ✅ 清空搜索后返回历史记录
