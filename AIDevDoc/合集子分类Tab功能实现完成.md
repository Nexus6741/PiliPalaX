# 合集订阅状态查询功能实现完成

## 问题描述
用户反馈：退出视频后再打开，合集订阅状态显示不正确。需要每次打开合集列表时都查询一次实际的订阅状态。

## 解决方案

### 1. 添加视频关系查询API
参考PiliPlus的实现，使用B站的 `/x/web-interface/archive/relation` API来查询视频的各种关系状态，包括：
- `attention`: 是否关注UP主
- `favorite`: 是否收藏视频
- `season_fav`: **是否订阅合集**（关键字段）
- `like`: 是否点赞
- `coin`: 投币数量

### 2. 实现代码

#### 2.1 添加API端点常量
**文件**: `lib/http/api.dart`
```dart
/// 查询视频关系（点赞、投币、收藏、合集订阅等）
static const String videoRelation = '/x/web-interface/archive/relation';
```

#### 2.2 添加查询方法
**文件**: `lib/http/user.dart`
```dart
// 查询视频关系（包括合集订阅状态）
static Future<dynamic> queryVideoRelation({String? bvid, int? aid}) async {
  if (bvid == null && aid == null) {
    return {'status': false, 'msg': 'bvid和aid至少需要一个'};
  }
  
  var res = await Request().get(
    Api.videoRelation,
    data: {
      if (bvid != null) 'bvid': bvid,
      if (aid != null) 'aid': aid,
    },
  );
  
  if (res.data['code'] == 0) {
    return {'status': true, 'data': res.data['data']};
  } else {
    return {'status': false, 'msg': res.data['message']};
  }
}
```

#### 2.3 更新订阅状态查询逻辑
**文件**: `lib/common/widgets/list_sheet.dart`

在 `_checkSubscriptionStatus()` 方法中：
```dart
Future<void> _checkSubscriptionStatus() async {
  if (widget.ugcSeason?.id == null) return;

  try {
    // 查询视频关系，获取真实的订阅状态
    final res = await UserHttp.queryVideoRelation(
      bvid: widget.bvid,
      aid: widget.aid,
    );

    if (res['status'] && res['data'] != null) {
      final data = res['data'];
      // season_fav字段表示是否订阅了合集
      final seasonFav = data['season_fav'] ?? false;
      
      if (mounted) {
        setState(() {
          isSubscribed = seasonFav;
        });
        
        // 如果状态与ugcSeason不一致，更新它
        if (widget.ugcSeason!.signState != (seasonFav ? 1 : 0)) {
          widget.ugcSeason!.signState = seasonFav ? 1 : 0;
          // 通知外部状态已更新
          widget.onSubscriptionChanged?.call(seasonFav);
        }
      }
    }
  } catch (e) {
    // 查询失败时，使用ugcSeason中的状态
    if (mounted) {
      setState(() {
        isSubscribed = widget.ugcSeason!.signState == 1;
      });
    }
  }
}
```

## 工作流程

1. **打开合集列表时**：
   - `initState()` 中首先使用 `ugcSeason.signState` 初始化UI状态
   - 立即调用 `_checkSubscriptionStatus()` 异步查询真实状态

2. **查询真实状态**：
   - 调用 `UserHttp.queryVideoRelation()` API
   - 从返回的 `season_fav` 字段获取真实订阅状态
   - 更新UI显示和 `ugcSeason.signState`

3. **状态同步**：
   - 如果查询到的状态与缓存不一致，自动更新
   - 通过 `onSubscriptionChanged` 回调通知外部组件
   - 确保videoDetail中的状态也得到更新

## 优势

1. **实时准确**：每次打开都查询最新状态，不依赖缓存
2. **用户体验好**：先显示缓存状态（快速响应），再异步更新真实状态
3. **容错性强**：查询失败时回退到缓存状态，不影响使用
4. **状态一致**：通过回调机制确保所有相关组件状态同步

## 测试要点

1. ✅ 订阅合集后，关闭再打开，状态正确显示为已订阅
2. ✅ 取消订阅后，关闭再打开，状态正确显示为未订阅
3. ✅ 退出视频后重新进入，订阅状态依然正确
4. ✅ 在其他设备订阅/取消订阅后，本设备打开能看到最新状态
5. ✅ 网络异常时，使用缓存状态，不影响基本功能

## 参考资料

- PiliPlus实现：`PiliPlus/lib/http/video.dart` - `videoRelation()` 方法
- PiliPlus模型：`PiliPlus/lib/models_new/video/video_relation/data.dart`
- API端点：`/x/web-interface/archive/relation`

## 实现目标
在视频播放页面的合集列表弹窗顶部，添加子合集分类Tab、订阅按钮和定位当前播放按钮，完全按照PiliPlus的实现，包括UI布局和交互细节。

## 功能说明

### 1. 应用场景
当用户在视频播放页面点击右侧"合集"按钮时，弹出合集列表。如果该合集包含多个section（分组），则在列表顶部显示横向滚动的Tab栏，用于切换不同分组的视频。

**使用流程：**
1. 用户观看视频
2. 点击右侧"合集 (20)"按钮
3. 弹出合集列表侧边栏/底部弹窗
4. 标题栏显示：合集（3） [订阅] [定位] [↑] [↓] [排序] [×]
5. 下方显示Tab：[逐集剧情分析] [剧情盘点] [人物志] [剧情对比]
6. 点击Tab切换显示对应分组的视频
7. 点击订阅按钮订阅/取消订阅合集
8. 点击定位按钮快速定位到当前播放的视频

### 2. 功能列表

#### 子合集分类Tab
- 自动定位到包含当前播放视频的section
- 横向滚动，支持多个Tab
- 选中Tab有圆角背景高亮（secondaryContainer）
- 未选中Tab为灰色背景（surfaceContainerHighest）
- 点击Tab切换显示对应分组的视频
- 切换后自动滚动到列表顶部

#### 订阅功能
- 显示当前订阅状态（已订阅/订阅）
- 点击切换订阅状态
- 已订阅显示金色实心星星图标（Icons.star + Colors.amber）
- 未订阅显示空心星星图标（Icons.star_border）
- 订阅中禁用按钮防止重复点击
- 调用真实的B站订阅API
  - 订阅：`POST /x/v3/fav/season/fav`
  - 取消订阅：`POST /x/v3/fav/season/unfav`
- 操作成功后显示提示并更新状态

#### 定位当前播放
- 点击定位按钮快速滚动到当前播放的视频
- 如果当前视频在其他section，自动切换到对应section
- 使用平滑滚动动画（300ms）
- 定位成功后显示提示

### 3. UI布局

#### 横屏模式（右侧侧边栏）
```
┌─────────────────────────────────────────┐
│ 合集（3） [订阅] [定位] [↑] [↓] [排序] [×] │ ← 标题栏
├─────────────────────────────────────────┤
│ [逐集剧情分析] [剧情盘点] [人物志] ...    │ ← Section Tab (横向滚动)
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ [封面] 守望落云-吕洛                 │ │
│ │        2025-12-20 13:48             │ │
│ │        👁 29.5万  💬 1579           │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ [封面] 天选打工人-钟吾               │ │
│ │        2025-11-15 10:39             │ │
│ │        👁 6.6万  💬 286             │ │
│ └─────────────────────────────────────┘ │
│                ...                      │
└─────────────────────────────────────────┘
```

#### 竖屏模式（底部弹窗）
```
┌─────────────────────────────────────────┐
│ 合集（3） [订阅] [定位] [↑] [↓] [排序] [×] │ ← 标题栏
├─────────────────────────────────────────┤
│ [逐集剧情分析] [剧情盘点] [人物志] ...    │ ← Section Tab
├─────────────────────────────────────────┤
│              视频列表内容区域              │
└─────────────────────────────────────────┘
```

## 实现细节

### 1. 数据模型

#### SectionItem (已存在)
```dart
class SectionItem {
  int? seasonId;
  int? id;
  String? title;
  int? type;
  List<EpisodeItem>? episodes;
}
```

#### UgcSeason (已存在)
```dart
class UgcSeason {
  int? id;
  String? title;
  List<SectionItem>? sections;  // 包含多个分组
  // ... 其他字段
}
```

### 2. ListSheet组件扩展

#### 新增参数
```dart
class ListSheet {
  final dynamic episodes;           // 单个section的episodes（兼容旧代码）
  final List<SectionItem>? sections;  // 多个sections（新功能）
  // ... 其他参数
}
```

#### ListSheetContent状态管理
```dart
class _ListSheetContentState extends State<ListSheetContent> {
  late List<dynamic> displayEpisodes;  // 当前显示的episodes
  int currentSectionIndex = 0;         // 当前选中的section索引
  List<SectionItem>? allSections;      // 所有sections
  
  @override
  void initState() {
    super.initState();
    
    // 初始化sections和episodes
    if (widget.sections != null && widget.sections!.isNotEmpty) {
      allSections = widget.sections;
      // 找到包含当前视频的section
      for (int i = 0; i < allSections!.length; i++) {
        final section = allSections![i];
        final found = section.episodes!.any((e) => 
          e.cid == widget.currentCid || 
          e.bvid == widget.bvid || 
          e.aid == widget.aid
        );
        if (found) {
          currentSectionIndex = i;
          break;
        }
      }
      displayEpisodes = allSections![currentSectionIndex].episodes!;
    } else {
      // 兼容旧代码：直接使用episodes
      displayEpisodes = widget.episodes!;
    }
  }
}
```

#### 切换Section
```dart
void _changeSection(int index) {
  if (allSections == null || index == currentSectionIndex) return;
  setState(() {
    currentSectionIndex = index;
    displayEpisodes = allSections![index].episodes!;
    currentIndex = 0;
    // 滚动到顶部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemScrollController.isAttached) {
        itemScrollController.jumpTo(index: 0);
      }
    });
  });
}
```

### 3. SeasonPanel调用修改

#### 修改前
```dart
ListSheet(
  episodes: episodes,  // 只传递当前section的episodes
  // ...
)
```

#### 修改后
```dart
ListSheet(
  sections: widget.ugcSeason.sections,  // 传递所有sections
  // ...
)
```

## UI样式规范

### Tab样式
- **高度**: 48px
- **内边距**: 水平8px，垂直4px
- **Tab间距**: 8px
- **Tab圆角**: 20px
- **Tab内边距**: 水平16px，垂直8px
- **字体大小**: 14px
- **底部分隔线**: 1px，透明度0.1

### 颜色方案
- **选中背景**: `theme.colorScheme.secondaryContainer`
- **选中文字**: `theme.colorScheme.onSecondaryContainer`
- **未选中背景**: `theme.colorScheme.surfaceContainerHighest`
- **未选中文字**: `theme.colorScheme.outline`

### 布局特点
- Tab栏固定在顶部
- 横向滚动，不换行
- 自动定位到包含当前视频的section
- 切换section时列表自动滚动到顶部

## 数据流程

1. **初始加载**
   - 视频播放页面获取视频详情
   - 解析ugcSeason.sections字段
   - 用户点击"合集"按钮
   - 传递sections到ListSheet
   - 自动定位到包含当前视频的section
   - 显示该section的视频列表

2. **切换Section**
   - 用户点击Tab
   - 调用_changeSection(index)
   - 更新currentSectionIndex
   - 更新displayEpisodes为新section的episodes
   - 重置currentIndex为0
   - 自动滚动到列表顶部
   - UI自动刷新（setState）

3. **兼容性处理**
   - 如果传递了sections，使用新逻辑
   - 如果只传递了episodes，使用旧逻辑（兼容分P视频）
   - 只有多个sections时才显示Tab栏

## API数据结构

### 视频详情API
```
GET /x/web-interface/view
参数:
- bvid: 视频BV号
```

### 响应（包含合集信息）
```json
{
  "code": 0,
  "data": {
    "ugc_season": {
      "id": 789,
      "title": "凡人修仙传",
      "sections": [
        {
          "id": 123456,
          "title": "逐集剧情分析",
          "season_id": 789,
          "episodes": [
            {
              "id": 1,
              "aid": 123,
              "cid": 456,
              "bvid": "BV1xx411c7mD",
              "title": "第1话",
              "long_title": "守望落云-吕洛",
              "cover": "http://...",
              "page": {
                "duration": 1161
              },
              "arc": {
                "stat": {
                  "view": 295000,
                  "danmaku": 1579
                }
              }
            }
          ]
        },
        {
          "id": 123457,
          "title": "剧情盘点",
          "season_id": 789,
          "episodes": [...]
        }
      ]
    }
  }
}
```

## 测试要点

### 功能测试
1. ✅ 播放包含多个section的合集视频
2. ✅ 点击"合集"按钮，弹出列表
3. ✅ 顶部显示section Tab栏
4. ✅ 自动定位到包含当前视频的section
5. ✅ 点击其他Tab，切换到对应分组的视频
6. ✅ Tab可以横向滚动
7. ✅ 选中Tab有高亮效果
8. ✅ 切换Tab时列表滚动到顶部
9. ✅ 标题栏显示当前section的视频数量

### UI测试
1. ✅ Tab样式与PiliPlus一致
2. ✅ 圆角、间距、颜色正确
3. ✅ 选中/未选中状态清晰
4. ✅ 横向滚动流畅
5. ✅ 横屏和竖屏模式都正常显示

### 边界测试
1. ✅ 只有一个section时不显示Tab
2. ✅ 没有sections数据时不显示Tab
3. ✅ 分P视频（非合集）不显示Tab
4. ✅ 切换section后反序功能正常
5. ✅ 切换section后跳转功能正常

## 与PiliPlus对比

### 完全一致的功能
- ✅ Tab布局和样式
- ✅ 横向滚动
- ✅ 选中高亮效果
- ✅ 自动定位到当前视频所在section
- ✅ 视频切换逻辑
- ✅ 响应式更新
- ✅ 横屏和竖屏适配

### 实现细节
- ✅ 使用Material + InkWell实现点击效果
- ✅ 使用setState实现状态更新
- ✅ 使用ListView.separated实现横向滚动
- ✅ 兼容旧代码（分P视频）
- ✅ 自动滚动到列表顶部

## 文件修改清单

### 修改的文件
1. `lib/common/widgets/list_sheet.dart`
   - ListSheet类新增sections参数
   - ListSheetContent类新增sections参数
   - _ListSheetContentState新增section相关状态管理
   - 新增_changeSection方法
   - 修改build方法添加Section Tab UI
   - 使用displayEpisodes替代widget.episodes

2. `lib/pages/video/introduction/widgets/season.dart`
   - 修改ListSheet调用，传递sections而不是episodes

### 新增的文件
- `AIDevDoc/合集子分类Tab功能实现完成.md` (本文档)

## 使用示例

### 播放合集视频
```dart
// 用户观看视频，视频详情包含ugcSeason
VideoDetailRes {
  ugcSeason: UgcSeason {
    id: 789,
    title: "凡人修仙传",
    sections: [
      SectionItem {
        id: 123456,
        title: "逐集剧情分析",
        episodes: [...]
      },
      SectionItem {
        id: 123457,
        title: "剧情盘点",
        episodes: [...]
      }
    ]
  }
}
```

### 点击合集按钮
```dart
// SeasonPanel调用ListSheet
ListSheet(
  sections: widget.ugcSeason.sections,  // 传递所有sections
  bvid: _videoDetailController.bvid,
  aid: _videoDetailController.oid.value,
  currentCid: cid,
  changeFucCall: widget.changeFuc,
  context: context,
  pages: _videoIntroController.videoDetail.value.pages,
).buildShowBottomSheet();
```

### 效果
1. 弹出合集列表（横屏右侧/竖屏底部）
2. 顶部显示Tab栏：[逐集剧情分析] [剧情盘点] [人物志] [剧情对比]
3. 自动选中包含当前视频的section
4. 显示该section的视频列表
5. 点击其他Tab切换到对应分组
6. 列表自动滚动到顶部

## 注意事项

1. **兼容性**
   - 支持新的sections参数（多section合集）
   - 兼容旧的episodes参数（分P视频）
   - 只在有多个sections时显示Tab
   - 不影响分P视频的显示

2. **状态管理**
   - 使用displayEpisodes存储当前显示的列表
   - 使用currentSectionIndex跟踪选中的section
   - 切换section时自动更新UI（setState）

3. **自动定位**
   - 初始化时自动找到包含当前视频的section
   - 确保用户看到的是正在播放的视频所在分组

4. **用户体验**
   - Tab可以横向滚动，支持任意数量的分组
   - 选中状态清晰，易于识别
   - 切换流畅，自动滚动到顶部
   - 标题栏显示当前section的视频数量

5. **性能优化**
   - 只在切换section时更新列表
   - 使用itemScrollController精确控制滚动
   - 避免不必要的重建

## 后续优化建议

1. **记忆功能**
   - 记住用户上次选中的section
   - 下次打开时自动选中

2. **动画效果**
   - 添加Tab切换的过渡动画
   - 视频列表切换时的淡入淡出效果

3. **统计信息**
   - 在Tab上显示该分组的视频数量
   - 如：[逐集剧情分析 (12)]

4. **手势优化**
   - 支持左右滑动切换section
   - 类似TabBarView的手势交互

## 总结

本次实现完全按照PiliPlus的设计，在视频播放页面的合集列表弹窗中实现了子分类Tab功能。功能包括：
- ✅ 横向滚动的Tab栏
- ✅ 自动定位到当前视频所在section
- ✅ 选中高亮效果
- ✅ 视频切换逻辑
- ✅ 响应式UI更新
- ✅ 完整的样式还原
- ✅ 兼容旧代码（分P视频）
- ✅ 横屏和竖屏适配

实现细节严格遵循PiliPlus的UI规范，没有任何简化，确保用户体验一致。同时保持了对旧代码的兼容性，不影响分P视频的正常显示。
