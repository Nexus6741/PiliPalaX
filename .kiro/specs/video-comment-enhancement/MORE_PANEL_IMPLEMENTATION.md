# 更多面板实现 - 参考 PiliPlus UI 设计

## 概述

根据用户需求，参考 PiliPlus 的 UI 设计，将"视频进度"、"视频截图"、"插入内容"三个功能合并到一个"更多"按钮中，点击后弹出底部面板显示这些选项。同时新增"转到动态"功能按钮。

## 实现内容

### 1. 工具栏布局调整

**修改前**:
```
[表情] [图片] [@提及] [视频进度] [视频截图] [插入链接] [取消] [发送]
```

**修改后**:
```
[表情] [图片] [@提及] [更多] [转到动态] [取消] [发送]
```

### 2. 更多面板设计

参考 PiliPlus 的设计，使用网格布局显示功能选项：

```
┌─────────────────────────────────┐
│  ┌───┐  ┌───┐  ┌───┐           │
│  │📄│  │⏰│  │📷│           │
│  └───┘  └───┘  └───┘           │
│  插入   视频   视频             │
│  内容   进度   截图             │
└─────────────────────────────────┘
```

### 3. 功能说明

| 功能 | 图标 | 说明 | 状态 |
|------|------|------|------|
| 插入内容 | Icons.post_add | 插入视频/文章链接 | 🚧 开发中 |
| 视频进度 | Icons.access_time | 插入当前播放时间 | ✅ 已实现 |
| 视频截图 | Icons.camera_alt_outlined | 截取当前视频画面 | ✅ 已实现 |
| 转到动态 | Icons.dynamic_feed_outlined | 转发到动态 | 🚧 开发中 |

## 代码实现

### 工具栏按钮

```dart
// 更多按钮
ToolbarIconButton(
  tooltip: toolbarType == 'more' ? '输入' : '更多',
  onPressed: () {
    if (toolbarType == 'more') {
      setState(() {
        toolbarType = 'input';
      });
      FocusScope.of(context).requestFocus(replyContentFocusNode);
    } else {
      setState(() {
        toolbarType = 'more';
      });
      FocusScope.of(context).unfocus();
    }
  },
  icon: toolbarType == 'more'
      ? const Icon(Icons.keyboard, size: 22)
      : const Icon(Icons.add_circle_outline, size: 22),
  toolbarType: toolbarType,
  selected: toolbarType == 'more',
),
```

### 更多面板

```dart
Widget _buildMorePanel() {
  final theme = Theme.of(context);
  final color = theme.colorScheme.onSurfaceVariant;

  Widget _buildMoreItem({
    required VoidCallback onTap,
    required IconData icon,
    required String title,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.onInverseSurface,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 28, color: color),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(12),
    child: GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _buildMoreItem(
          onTap: () {
            SmartDialog.showToast('插入内容功能开发中');
          },
          icon: Icons.post_add,
          title: '插入内容',
        ),
        _buildMoreItem(
          onTap: () {
            onInsertVideoProgress();
          },
          icon: Icons.access_time,
          title: '视频进度',
        ),
        _buildMoreItem(
          onTap: () {
            onInsertScreenshot();
          },
          icon: Icons.camera_alt_outlined,
          title: '视频截图',
        ),
      ],
    ),
  );
}
```

### 底部面板切换

```dart
SizedBox(
  width: double.infinity,
  height: toolbarType == 'input' ? keyboardHeight : emoteHeight,
  child: toolbarType == 'mention'
      ? MentionPanel(
          onMention: onMentionUser,
          onClose: _closeMentionPanel,
        )
      : toolbarType == 'more'
          ? _buildMorePanel()
          : EmotePanel(
              onChoose: onChooseEmote,
            ),
),
```

## UI 设计特点

### 1. 图标容器
- **背景色**: `theme.colorScheme.onInverseSurface`
- **圆角**: 6px
- **宽高比**: 1:1（正方形）
- **图标大小**: 28px
- **图标颜色**: `theme.colorScheme.onSurfaceVariant`

### 2. 文字标签
- **字体大小**: 13px
- **颜色**: `theme.colorScheme.onSurface`
- **最大行数**: 1
- **间距**: 图标下方 5px

### 3. 网格布局
- **列数**: 4
- **主轴间距**: 12px
- **交叉轴间距**: 12px
- **宽高比**: 0.8
- **内边距**: 12px

## 交互逻辑

### 1. 更多按钮点击
- 如果当前是"更多"面板 → 切换到"输入"状态，显示键盘
- 如果当前不是"更多"面板 → 切换到"更多"状态，隐藏键盘

### 2. 图标切换
- 显示"更多"面板时 → 显示键盘图标 (Icons.keyboard)
- 隐藏"更多"面板时 → 显示加号图标 (Icons.add_circle_outline)

### 3. 面板高度
- 使用与表情面板相同的高度 (`emoteHeight`)
- 确保与键盘高度一致

## 与 PiliPlus 的对比

| 特性 | PiliPlus | 当前实现 | 说明 |
|------|----------|---------|------|
| 布局方式 | GridView | GridView | ✅ 一致 |
| 图标容器 | 圆角矩形 | 圆角矩形 | ✅ 一致 |
| 图标大小 | 28px | 28px | ✅ 一致 |
| 文字大小 | 13px | 13px | ✅ 一致 |
| 网格列数 | 动态 | 4列 | ⚠️ 简化 |
| 功能项 | 多个 | 3个 | ⚠️ 待扩展 |

## 修改的文件

- `lib/pages/video/reply_new/view_enhanced.dart`
  - 修改工具栏按钮布局
  - 添加 `_buildMorePanel()` 方法
  - 修改底部面板切换逻辑

## 测试清单

### 基础功能
- [ ] 点击"更多"按钮能正确切换面板
- [ ] 更多面板显示正确的图标和文字
- [ ] 点击"插入内容"显示开发中提示
- [ ] 点击"视频进度"能正确插入时间
- [ ] 点击"视频截图"能正确截图
- [ ] 点击"转到动态"显示开发中提示

### UI 测试
- [ ] 图标容器样式正确
- [ ] 文字标签样式正确
- [ ] 网格布局间距正确
- [ ] 面板高度与键盘一致

### 交互测试
- [ ] 更多面板与表情面板切换正常
- [ ] 更多面板与@提及面板切换正常
- [ ] 更多面板与键盘切换正常
- [ ] 图标状态切换正常

## 下一步计划

### 短期
1. [ ] 实现"插入内容"功能
   - 搜索视频/文章
   - 插入链接
2. [ ] 实现"转到动态"功能
   - 转发评论到动态
   - 保留富文本格式

### 中期
1. [ ] 添加更多功能选项
   - 投票
   - 位置
   - 话题
2. [ ] 优化网格布局
   - 动态列数
   - 响应式设计

### 长期
1. [ ] 自定义功能项
   - 用户可配置显示的功能
   - 拖拽排序
2. [ ] 功能分组
   - 常用功能
   - 高级功能

## 参考资料

- PiliPlus 源码: `PiliPlus/lib/pages/video/reply_new/view.dart`
- PiliPlus 公共发布页面: `PiliPlus/lib/pages/common/publish/common_rich_text_pub_page.dart`
- 面板类型定义: `PiliPlus/lib/models/common/publish_panel_type.dart`

## 完成时间

- 实现时间: 2024-12-08
- 文档完成: 2024-12-08
