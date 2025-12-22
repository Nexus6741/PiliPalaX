# 用户空间投稿Tab合集功能实施计划

## 目标
完全按照 PiliPlus 实现投稿Tab的合集/列表筛选功能，包括所有UI细节和交互逻辑。

## PiliPlus 功能分析

### 1. Tab结构
投稿Tab包含多个子Tab，每个子Tab对应不同类型的内容：
- **视频** - 普通投稿视频
- **充电专属** - 需要充电才能观看的视频
- **图文** - 图文内容
- **音频** - 音频内容
- **漫画** - 漫画内容
- **合集视频** - 用户创建的合集（如"世界大战三部曲"）
- **列表视频** - 用户创建的视频列表
- **全部合集/列表** - 查看所有合集和列表

### 2. 数据来源
从 `SpaceData.tab2` 中获取 `contribute` 项，该项包含：
```dart
SpaceTab2 {
  title: "投稿",
  param: "contribute",
  items: [
    SpaceTab2Item {
      title: "视频",
      param: "video"
    },
    SpaceTab2Item {
      title: "充电专属",
      param: "charging_video"
    },
    SpaceTab2Item {
      title: "世界大战三部曲",
      param: "season_video",
      seasonId: 123456
    },
    // ... 更多项
  ]
}
```

### 3. UI布局
```
┌─────────────────────────────────────────┐
│ [视频] [充电专属] [图文] [合集1] [合集2] │ ← TabBar
├─────────────────────────────────────────┤
│                                         │
│         视频列表内容区域                  │
│                                         │
└─────────────────────────────────────────┘
```

**TabBar 样式**：
- 可横向滚动
- 选中Tab有圆角背景色（secondaryContainer）
- 未选中Tab为灰色文字（outline）
- 指示器为圆角矩形，覆盖整个Tab
- 左对齐（tabAlignment: TabAlignment.start）

### 4. 页面类型映射

| param          | 页面类型         | 说明                     |
| -------------- | ---------------- | ------------------------ |
| video          | MemberVideo      | 普通视频                 |
| charging_video | MemberVideo      | 充电专属视频             |
| article        | MemberArticle    | 专栏文章                 |
| opus           | MemberOpus       | 图文动态                 |
| audio          | MemberAudio      | 音频                     |
| comic          | MemberComic      | 漫画                     |
| season_video   | MemberVideo      | 合集视频（需要seasonId） |
| series         | MemberVideo      | 列表视频（需要seriesId） |
| ugcSeason      | SeasonSeriesPage | 全部合集/列表            |

## 实施步骤

### 阶段一：数据模型完善 ✅
1. ✅ 为 `SpaceTab2Item` 添加 `seasonId` 和 `seriesId` 字段
2. ✅ 确保 `SpaceTab2` 包含 `items` 字段

### 阶段二：创建 MemberContribute 页面
1. 创建 `lib/pages/member_contribute/controller.dart`
   - 从 MemberController 获取 contribute 的 items
   - 如果有合集/列表，添加"全部合集/列表"项
   - 创建 TabController
   - 管理Tab切换

2. 创建 `lib/pages/member_contribute/view.dart`
   - 实现TabBar UI（完全按照PiliPlus样式）
   - 实现TabBarView
   - 根据 param 类型渲染不同页面

### 阶段三：创建各类型页面
1. 复用现有的 `MemberArchivePage` 作为 `MemberVideo`
2. 创建其他类型页面的占位符（如果不存在）：
   - MemberArticle（专栏）
   - MemberOpus（图文）
   - MemberAudio（音频）
   - MemberComic（漫画）

### 阶段四：集成到用户空间
1. 修改 `lib/pages/member/view.dart`
   - 将 `contribute` case 改为使用 `MemberContribute`
   - 传递必要的参数（mid, heroTag）

### 阶段五：测试和优化
1. 测试Tab切换
2. 测试合集视频加载
3. 测试列表视频加载
4. 优化UI细节

## 关键技术点

### 1. TabBar 样式
```dart
TabBar(
  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  splashFactory: NoSplash.splashFactory,
  padding: const EdgeInsets.symmetric(horizontal: 8),
  isScrollable: true,
  tabAlignment: TabAlignment.start,
  dividerHeight: 0,
  indicatorWeight: 0,
  indicatorPadding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
  indicator: BoxDecoration(
    color: theme.colorScheme.secondaryContainer,
    borderRadius: const BorderRadius.all(Radius.circular(20)),
  ),
  indicatorSize: TabBarIndicatorSize.tab,
  labelColor: theme.colorScheme.onSecondaryContainer,
  unselectedLabelColor: theme.colorScheme.outline,
)
```

### 2. 动态添加"全部合集/列表"Tab
```dart
if (_ctr.hasSeasonOrSeries == true) {
  items!.add(
    const SpaceTab2Item(
      param: 'ugcSeason',
      title: '全部合集/列表',
    ),
  );
}
```

### 3. 页面类型判断
```dart
Widget _getPageFromType(SpaceTab2Item item) {
  return switch (item.param) {
    'video' => MemberVideo(...),
    'season_video' => MemberVideo(seasonId: item.seasonId, ...),
    'series' => MemberVideo(seriesId: item.seriesId, ...),
    // ... 其他类型
  };
}
```

## 注意事项

1. **不简化任何功能** - 完全按照PiliPlus实现
2. **保持UI一致性** - TabBar样式、间距、颜色都要一致
3. **处理边界情况**：
   - 只有一个Tab时不显示TabBar
   - 没有items时显示错误提示
4. **性能优化**：
   - 使用 `AutomaticKeepAliveClientMixin` 保持页面状态
   - TabBarView 使用 `NeverScrollableScrollPhysics`

## 参考文件

### PiliPlus
- `PiliPlus/lib/pages/member_contribute/view.dart`
- `PiliPlus/lib/pages/member_contribute/controller.dart`
- `PiliPlus/lib/pages/member_video/view.dart`
- `PiliPlus/lib/pages/member_season_series/view.dart`

### 当前项目
- `lib/pages/member_archive/view.dart` - 将作为 MemberVideo 的基础
- `lib/pages/member/view.dart` - 需要修改集成点
- `lib/models/member/space_data.dart` - 数据模型

## 预期效果

完成后，投稿Tab应该：
1. ✅ 显示所有类型的Tab（视频、充电专属、图文、合集等）
2. ✅ Tab可以横向滚动
3. ✅ 选中Tab有圆角背景高亮
4. ✅ 点击Tab切换内容
5. ✅ 合集Tab显示对应合集的视频
6. ✅ "全部合集/列表"Tab显示所有合集和列表
7. ✅ UI样式与PiliPlus完全一致
