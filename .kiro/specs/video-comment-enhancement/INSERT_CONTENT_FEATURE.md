# 插入内容功能实现

## 功能概述

插入内容功能允许用户在评论中快速插入视频或专栏的链接和标题。用户可以搜索视频或专栏，选择后自动将标题插入到评论框中。

### 核心特性
- **历史记录**：首次打开时自动显示最近使用过的视频和专栏
- **搜索功能**：支持搜索新的视频或专栏
- **双标签页**：支持视频和专栏两种内容类型
- **自动保存**：选择内容后自动保存到历史记录

## 实现细节

### 1. 搜索页面 (`insert_content_search.dart`)

创建了一个新的搜索页面 `InsertContentSearchPage`，包含以下功能：

- **历史记录加载**：初始化时自动从本地存储加载历史记录
- **双标签页面**：支持视频和专栏两种内容类型的搜索
- **搜索功能**：使用 `SearchHttp.searchByType()` API 进行搜索
- **结果展示**：以列表形式展示搜索结果或历史记录，包含标题和描述
- **内容选择**：点击结果项后返回标题和 URL，并自动保存到历史记录

### 2. 主要方法

#### `_loadHistory()`
- 从本地存储加载历史记录
- 将保存的 JSON 数据转换为搜索结果对象
- 分别加载视频和专栏历史记录

#### `_search()`
- 获取搜索关键词
- 根据当前标签页选择搜索类型（视频或专栏）
- 调用 `SearchHttp.searchByType()` 进行搜索
- 更新结果列表
- 标记为非历史记录状态

#### `_selectItem()`
- 处理用户选择的内容
- 提取标题和生成 URL
- 调用 `_saveToHistory()` 保存到历史记录
- 返回结果给调用者

#### `_saveToHistory()`
- 将选择的内容保存到本地存储
- 移除重复项（同一内容只保留一条）
- 将新项添加到列表开头
- 只保留最近 10 条记录

#### `_buildResultList()`
- 构建搜索结果或历史记录列表
- 当显示历史记录时，在列表顶部显示"历史记录"标题
- 根据内容类型显示不同的字段
- 支持点击选择

### 3. 集成到评论面板

在 `view_enhanced.dart` 中：

#### `onInsertContent()` 方法
```dart
Future<void> onInsertContent() async {
  final result = await Get.to<Map<String, String>>(
    const InsertContentSearchPage(),
  );

  if (result != null) {
    final title = result['title'] ?? '';

    if (title.isNotEmpty) {
      // 在光标位置插入标题
      final int cursorPosition = _replyContentController.selection.baseOffset;
      final String currentText = _replyContentController.text;
      final String insertText = '$title ';

      final String newText = currentText.substring(0, cursorPosition) +
          insertText +
          currentText.substring(cursorPosition);

      _replyContentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: cursorPosition + insertText.length),
      );
      enablePublish.value = true;
      SmartDialog.showToast('已插入内容: $title');
    }
  }
}
```

#### 更新 `_buildMorePanel()`
- 将"插入内容"按钮的点击事件从 `SmartDialog.showToast('插入内容功能开发中')` 改为 `onInsertContent()`

### 4. 支持的内容类型

#### 视频
- 搜索类型：`SearchType.video`
- 返回模型：`SearchVideoItemModel`
- URL 格式：`https://www.bilibili.com/video/{bvid}`

#### 专栏
- 搜索类型：`SearchType.article`
- 返回模型：`SearchArticleItemModel`
- URL 格式：`https://www.bilibili.com/read/cv{id}`

## 使用流程

### 首次使用（显示历史记录）
1. 用户点击"更多"按钮打开更多面板
2. 点击"插入内容"按钮
3. 打开搜索页面，自动显示历史记录
4. 从历史记录中选择要插入的内容
5. 标题自动插入到评论框中

### 搜索新内容
1. 在搜索框中输入关键词
2. 点击搜索按钮或按 Enter 键
3. 显示搜索结果
4. 从结果中选择要插入的内容
5. 标题自动插入到评论框中，内容自动保存到历史记录

### 清空搜索
1. 点击搜索框右侧的清空按钮
2. 返回显示历史记录

## 技术细节

### 使用的 API
- `SearchHttp.searchByType()` - 执行搜索

### 使用的模型
- `SearchVideoModel` - 视频搜索结果容器
- `SearchVideoItemModel` - 单个视频项
- `SearchArticleModel` - 专栏搜索结果容器
- `SearchArticleItemModel` - 单个专栏项

### 使用的枚举
- `SearchType` - 搜索类型枚举

### 本地存储
- 使用 `GStorage.localCache` 存储历史记录
- 视频历史记录键：`insert_content_video_history`
- 专栏历史记录键：`insert_content_article_history`
- 每种类型最多保存 10 条记录

### 历史记录数据结构
```dart
// 视频历史记录
{
  'type': 'video',
  'title': '视频标题',
  'bvid': 'BV...',
  'description': '视频描述'
}

// 专栏历史记录
{
  'type': 'article',
  'title': '专栏标题',
  'id': 12345,
  'desc': '专栏描述'
}
```

## 文件列表

- `lib/pages/video/reply_new/widgets/insert_content_search.dart` - 搜索页面实现
- `lib/pages/video/reply_new/view_enhanced.dart` - 集成到评论面板

## 测试建议

1. 搜索视频内容，验证结果正确显示
2. 搜索专栏内容，验证结果正确显示
3. 选择内容后，验证标题正确插入到评论框
4. 验证插入后的文本可以正常发送
5. 验证多次插入内容的功能
