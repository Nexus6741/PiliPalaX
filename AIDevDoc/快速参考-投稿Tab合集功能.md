# 快速参考 - 投稿Tab合集功能

## 功能概述
用户空间投稿Tab现在支持显示多个子Tab，包括视频、充电专属、合集、列表等，完全按照PiliPlus实现。

## 核心文件
```
lib/models/common/member/contribute_type.dart  # 投稿类型枚举
lib/pages/member_contribute/controller.dart    # Controller
lib/pages/member_contribute/view.dart          # View
lib/pages/member/view.dart                     # 集成点
lib/http/api.dart                              # API端点定义
lib/http/member.dart                           # spaceArchive方法
```

## 最新更新（2024-12-22）

### ✅ 已添加API支持
- `spaceArchive` - 普通投稿视频（游标分页）
- `spaceChargingArchive` - 充电专属视频
- `spaceSeason` - 合集视频
- `spaceSeries` - 列表视频
- `spaceArticle` - 专栏
- `spaceAudio` - 音频
- `spaceComic` - 漫画
- `seasonSeries` - 全部合集/列表

### ✅ 已实现spaceArchive方法
统一的API调用方法，支持：
- 4种视频类型（video, charging, season, series）
- 游标分页和普通分页
- 排序（最新发布、最多播放）
- 合集ID和列表ID参数
- 自动签名和access_key

## 快速使用

### 调用spaceArchive API
```dart
// 普通视频
var res = await MemberHttp.spaceArchive(
  type: 'video',
  mid: 123456,
  order: 'pubdate',
);

// 合集视频
var res = await MemberHttp.spaceArchive(
  type: 'season',
  mid: 123456,
  seasonId: 789,
  sort: 'desc',
);

// 列表视频
var res = await MemberHttp.spaceArchive(
  type: 'series',
  mid: 123456,
  seriesId: 456,
);
```

## 快速测试

### 1. 查看投稿Tab
1. 打开应用
2. 进入任意用户空间
3. 点击"投稿"Tab
4. 应该看到横向滚动的子Tab（如果有多个）

### 2. 测试Tab切换
1. 点击不同的Tab（视频、充电专属、合集等）
2. 内容应该正确切换
3. 选中的Tab有圆角背景高亮

### 3. 测试合集检测
1. 进入有合集的UP主空间
2. 投稿Tab应该显示合集名称
3. 最后应该有"全部合集/列表"Tab

## 数据结构

### SpaceTab2Item
```dart
class SpaceTab2Item {
  String? title;      // Tab标题
  String? param;      // 类型参数
  int? seasonId;      // 合集ID
  int? seriesId;      // 列表ID
}
```

### 类型映射
- `video` → 普通视频（API: spaceArchive）
- `charging_video` → 充电专属（API: spaceChargingArchive）
- `season_video` → 合集视频（API: spaceSeason，需要seasonId）
- `series` → 列表视频（API: spaceSeries，需要seriesId）
- `article` → 专栏（API: spaceArticle）
- `audio` → 音频（API: spaceAudio）
- `comic` → 漫画（API: spaceComic）
- `ugcSeason` → 全部合集/列表（API: seasonSeries）

## UI样式

### TabBar配置
```dart
overlayColor: Colors.transparent        # 无覆盖色
splashFactory: NoSplash                 # 无水波纹
isScrollable: true                      # 可滚动
tabAlignment: TabAlignment.start        # 左对齐
indicator: 圆角矩形背景                  # 指示器样式
labelColor: onSecondaryContainer        # 选中颜色
unselectedLabelColor: outline           # 未选中颜色
```

## 当前状态

### ✅ 已完成
- Tab动态生成
- 合集/列表检测
- TabBar样式
- Tab切换
- 状态保持
- API端点定义
- spaceArchive统一方法
- 类型支持（video, charging, season, series）

### 🚧 待完善
- 改进MemberArchivePage以使用新API
- 根据type、seasonId、seriesId加载对应视频
- 创建专栏、音频、漫画页面
- 创建全部合集/列表页面
- 完善数据模型

## 调试

### 查看API请求
spaceArchive方法会自动输出：
```
========== spaceArchive API Request ==========
Type: season
API URL: https://app.bilibili.com/x/v2/space/season/videos
Season ID: 789
Order: null
==============================================
```

### 查看API响应
```
========== spaceArchive API Response ==========
Response code: 0
Message: 0
==============================================
```

### 查看Tab数据
在 `MemberContributeController.onInit()` 中添加：
```dart
print('Contribute items: ${items?.map((e) => e.title).toList()}');
print('Has season or series: $hasSeasonOrSeries');
```

## 常见问题

### Q: 为什么不显示TabBar？
A: 只有一个Tab时不显示TabBar，直接显示内容。

### Q: 为什么没有"全部合集/列表"Tab？
A: 只有检测到合集或列表时才会添加。

### Q: 合集视频为什么显示普通视频？
A: 当前MemberArchivePage还未使用新的spaceArchive API，需要改进以支持seasonId参数。

### Q: 其他类型为什么显示占位符？
A: 专栏、图文、音频、漫画等页面还未实现，当前显示"功能开发中"占位符。

### Q: API返回-400错误？
A: 检查是否正确添加了access_key和签名。使用`print()`查看请求参数。

## 下一步

### 立即可做
1. 改进MemberArchivePage
   - 添加type、seasonId、seriesId参数
   - 使用MemberHttp.spaceArchive方法
   - 根据type调整UI和排序选项

2. 测试不同类型
   - 测试普通视频加载
   - 测试合集视频加载（需要有合集的UP主）
   - 测试列表视频加载

### 后续计划
1. 创建专栏页面（MemberArticle）
2. 创建音频页面（MemberAudio）
3. 创建漫画页面（MemberComic）
4. 创建全部合集/列表页面（SeasonSeriesPage）
5. 完善数据模型

## 相关文档
- `AIDevDoc/用户空间投稿Tab合集功能实施计划.md` - 原始计划
- `AIDevDoc/用户空间投稿合集标签实现指南.md` - 基础实现
- `AIDevDoc/用户空间投稿Tab合集功能完善.md` - API完善

