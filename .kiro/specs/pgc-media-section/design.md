# 影视分区功能设计文档

## 概述

本文档描述了PiliPalaX应用中影视分区（电影、电视剧、纪录片、综艺）功能的技术设计。该功能参照PiliPlus项目的实现，提供完整的影视内容浏览、追剧、推荐和索引功能。

## 架构

### 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                      主页 (Home)                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  标签栏: 番剧 | 影视 | ...                            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   影视页面 (PgcPage)                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  最近追剧区域 (FavPgcList)                           │  │
│  │  - 横向滚动列表                                      │  │
│  │  - 追剧卡片 (PgcCardV)                              │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  推荐区域 (Recommendation)                           │  │
│  │  - 网格布局                                          │  │
│  │  - 推荐卡片 (PgcCardVPgcIndex)                      │  │
│  │  - 分页加载                                          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
        ┌──────────────────┐   ┌──────────────────┐
        │  视频播放页面    │   │  索引页面        │
        │  (VideoPage)     │   │  (PgcIndexPage)  │
        │                  │   │                  │
        │  - 播放器        │   │  - 标签栏        │
        │  - 集数列表      │   │  - 筛选条件      │
        │  - 评论          │   │  - 内容网格      │
        └──────────────────┘   └──────────────────┘
```

### 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                      UI 层 (View)                            │
│  - PgcPage (影视页面)                                       │
│  - PgcIndexPage (索引页面)                                  │
│  - PgcCardV (追剧卡片)                                      │
│  - PgcCardVPgcIndex (推荐卡片)                              │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                   业务逻辑层 (Controller)                    │
│  - PgcController (影视页面控制器)                           │
│  - PgcIndexController (索引页面控制器)                      │
│  - 状态管理 (GetX)                                          │
│  - 数据加载逻辑                                             │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    数据访问层 (HTTP)                         │
│  - PgcHttp (PGC API)                                        │
│  - FavHttp (收藏 API)                                       │
│  - 请求/响应处理                                           │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    数据模型层 (Models)                       │
│  - FavPgcItemModel (追剧项目)                               │
│  - PgcIndexItem (推荐/索引项目)                             │
│  - TimelineResult (时间表)                                  │
│  - LoadingState (加载状态)                                  │
└─────────────────────────────────────────────────────────────┘
```

## 组件和接口

### 页面组件

#### 1. PgcPage (影视页面)

**职责**: 显示影视分区的主页面，包含追剧、推荐等内容

**属性**:
- `tabType: HomeTabType` - 标签类型（影视）

**主要方法**:
- `build()` - 构建页面UI
- `_buildFollow()` - 构建追剧区域
- `_buildRcmd()` - 构建推荐区域
- `_buildTimeline()` - 构建时间表（仅番剧）

**状态管理**:
- 使用 `PgcController` 管理状态
- 使用 `AutomaticKeepAliveClientMixin` 保持页面状态

#### 2. PgcIndexPage (索引页面)

**职责**: 显示影视内容的分类索引，支持多标签切换

**属性**:
- `indexType: int?` - 索引类型（null=番剧, 102=全部, 2=电影, 5=电视剧, 3=纪录片, 7=综艺）

**主要方法**:
- `build()` - 构建页面UI
- `_buildBody()` - 构建主体内容
- `_buildSortsWidget()` - 构建筛选条件
- `_buildList()` - 构建内容列表

**状态管理**:
- 使用 `PgcIndexController` 管理状态
- 支持多个标签的独立状态

### 卡片组件

#### 1. PgcCardV (追剧卡片)

**职责**: 显示单个追剧项目的卡片

**属性**:
- `item: FavPgcItemModel` - 追剧项目数据

**显示内容**:
- 封面图片
- 标题
- 评分
- 观看进度
- 新集数提示

#### 2. PgcCardVPgcIndex (推荐/索引卡片)

**职责**: 显示单个推荐或索引项目的卡片

**属性**:
- `item: PgcIndexItem` - 推荐/索引项目数据

**显示内容**:
- 封面图片
- 标题
- 评分
- 作品类型
- 地区和年份

### 控制器

#### 1. PgcController

**职责**: 管理影视页面的业务逻辑和状态

**主要属性**:
```dart
class PgcController extends CommonListController<List<PgcIndexItem>?, PgcIndexItem> {
  final HomeTabType tabType;
  
  // 追剧相关
  late int followPage = 1;
  late RxInt followCount = (-1).obs;
  late bool followLoading = false;
  late bool followEnd = false;
  late Rx<LoadingState<List<FavPgcItemModel>?>> followState;
  ScrollController? followController;
  
  // 推荐相关
  late Rx<LoadingState<List<PgcIndexItem>?>> loadingState;
  
  // 账户服务
  AccountService accountService;
}
```

**主要方法**:
- `onInit()` - 初始化，加载追剧和推荐数据
- `onRefresh()` - 刷新所有数据
- `queryPgcFollow()` - 加载追剧列表
- `customGetData()` - 加载推荐数据
- `onLoadMore()` - 加载更多推荐

#### 2. PgcIndexController

**职责**: 管理索引页面的业务逻辑和状态

**主要属性**:
```dart
class PgcIndexController extends CommonListController<PgcIndexResult, PgcIndexItem> {
  int? indexType;
  Rx<LoadingState<PgcIndexConditionData>> conditionState;
  late final RxBool isExpand = false.obs;
  RxMap<String, dynamic> indexParams = <String, dynamic>{}.obs;
}
```

**主要方法**:
- `onInit()` - 初始化，加载筛选条件
- `getPgcIndexCondition()` - 加载筛选条件
- `customGetData()` - 加载索引数据

## 数据模型

### 1. FavPgcItemModel (追剧项目)

**来源**: Bilibili API `/x/v2/fav/pgc`

**主要字段**:
```dart
class FavPgcItemModel {
  int? seasonId;           // 季度ID
  int? mediaId;            // 媒体ID
  int? seasonType;         // 季度类型 (1=番剧, 2=电影, 5=电视剧)
  String? title;           // 标题
  String? cover;           // 封面图片URL
  int? totalCount;         // 总集数
  int? isFinish;           // 是否完结 (0=未完结, 1=完结)
  String? progress;        // 观看进度
  Rating? rating;          // 评分信息
  NewEp? newEp;            // 最新集数信息
  // ... 其他字段
}
```

### 2. PgcIndexItem (推荐/索引项目)

**来源**: Bilibili API `/pgc/season/index`

**主要字段**:
```dart
class PgcIndexItem {
  int? seasonId;           // 季度ID
  int? mediaId;            // 媒体ID
  String? title;           // 标题
  String? cover;           // 封面图片URL
  String? score;           // 评分
  int? seasonType;         // 季度类型
  int? seasonStatus;       // 季度状态
  String? subTitle;        // 副标题
  // ... 其他字段
}
```

### 3. LoadingState (加载状态)

**定义**:
```dart
sealed class LoadingState<T> {
  const LoadingState();
  
  factory LoadingState.loading() => Loading<T>();
  factory LoadingState.success(T data) => Success<T>(data);
  factory LoadingState.error(String message) => Error<T>(message);
  
  bool get isSuccess => this is Success;
  bool get isLoading => this is Loading;
  bool get isError => this is Error;
  
  T? get dataOrNull => this is Success ? (this as Success).data : null;
}

class Loading<T> extends LoadingState<T> {}
class Success<T> extends LoadingState<T> {
  final T data;
  Success(this.data);
}
class Error<T> extends LoadingState<T> {
  final String message;
  Error(this.message);
}
```

## API 接口

### 1. 获取追剧列表

**端点**: `GET /x/v2/fav/pgc`

**参数**:
- `vmid` - 用户ID
- `type` - 类型 (1=番剧, 2=影视)
- `pn` - 页码
- `follow_status` - 关注状态（可选）

**响应**:
```json
{
  "code": 0,
  "data": {
    "list": [FavPgcItemModel],
    "total": 10
  }
}
```

### 2. 获取推荐内容

**端点**: `GET /pgc/season/index`

**参数**:
- `st` - 排序类型
- `order` - 排序方式
- `season_type` - 季度类型 (1=番剧)
- `type` - 内容类型 (1=番剧)
- `page` - 页码
- `pagesize` - 每页数量
- `index_type` - 索引类型 (102=全部, 2=电影, 5=电视剧, 3=纪录片, 7=综艺)

**响应**:
```json
{
  "code": 0,
  "data": {
    "list": [PgcIndexItem],
    "has_next": 1
  }
}
```

### 3. 获取索引筛选条件

**端点**: `GET /pgc/season/index/condition`

**参数**:
- `season_type` - 季度类型
- `type` - 内容类型
- `index_type` - 索引类型

**响应**:
```json
{
  "code": 0,
  "data": {
    "order": [PgcConditionOrder],
    "filter": [PgcConditionFilter]
  }
}
```

## 路由和导航

### 路由定义

```dart
// 影视页面
GetPage(
  name: '/pgc',
  page: () => const PgcPage(tabType: HomeTabType.cinema),
)

// 索引页面
GetPage(
  name: '/pgcIndex',
  page: () => const PgcIndexPage(),
)

// 视频播放页面
GetPage(
  name: '/video',
  page: () => const VideoPage(),
)

// 收藏页面
GetPage(
  name: '/fav',
  page: () => const FavPage(),
)
```

### 导航流程

```
影视页面
  ├─ 点击追剧卡片 → 视频播放页面 (传递 seasonId, episodeId)
  ├─ 点击"查看全部" → 收藏页面 (定位到影视分类)
  └─ 点击"更多" → 索引页面

索引页面
  ├─ 点击标签 → 切换分类
  ├─ 点击内容卡片 → 视频播放页面
  └─ 返回 → 影视页面

视频播放页面
  └─ 返回 → 影视页面或索引页面
```

## 状态管理

### GetX 状态管理

**影视页面状态**:
```dart
// 追剧状态
Rx<LoadingState<List<FavPgcItemModel>?>> followState;
RxInt followCount;
RxBool followLoading;
RxBool followEnd;

// 推荐状态
Rx<LoadingState<List<PgcIndexItem>?>> loadingState;
RxInt page;
RxBool isEnd;
```

**索引页面状态**:
```dart
// 筛选条件状态
Rx<LoadingState<PgcIndexConditionData>> conditionState;
RxMap<String, dynamic> indexParams;
RxBool isExpand;

// 内容列表状态
Rx<LoadingState<List<PgcIndexItem>?>> loadingState;
RxInt page;
RxBool isEnd;
```

### 状态转换

```
初始化
  ↓
加载中 (Loading)
  ├─ 成功 → 成功 (Success) → 显示数据
  └─ 失败 → 错误 (Error) → 显示错误信息

刷新
  ↓
重置页码和数据
  ↓
加载中 (Loading)
  ├─ 成功 → 成功 (Success) → 显示新数据
  └─ 失败 → 错误 (Error) → 显示错误信息

加载更多
  ↓
页码递增
  ↓
加载中 (Loading)
  ├─ 成功 → 成功 (Success) → 追加数据
  └─ 失败 → 错误 (Error) → 显示错误信息
```

## 正确性属性

一个属性是一个特征或行为，应该在系统的所有有效执行中保持真实——本质上是关于系统应该做什么的正式陈述。属性充当人类可读的规范和机器可验证的正确性保证之间的桥梁。

### Property 1: 追剧列表加载一致性

*对于任何* 已登录用户，当加载追剧列表时，返回的列表应该包含该用户订阅的所有影视作品，且列表中的每个项目都应该有有效的seasonId和title。

**验证**: 需求 2.3, 3.3

### Property 2: 推荐内容分页一致性

*对于任何* 推荐内容列表，当用户滚动到底部时，系统应该自动加载下一页内容，新加载的内容应该追加到现有列表中，且不应该重复。

**验证**: 需求 4.2

### Property 3: 索引标签切换状态保持

*对于任何* 索引页面，当用户在标签间切换时，每个标签的滚动位置和加载状态应该被独立保持，返回到之前的标签时应该恢复之前的状态。

**验证**: 需求 5.4

### Property 4: 内容卡片信息完整性

*对于任何* 显示的内容卡片，无论是追剧、推荐还是索引内容，卡片应该包含必需的信息字段（标题、封面、评分），且这些字段不应该为空或无效。

**验证**: 需求 6.1, 6.3, 6.4, 6.5

### Property 5: 登录状态与UI可见性一致

*对于任何* 用户状态，已登录用户应该看到追剧区域，未登录用户应该看不到追剧区域，且这个可见性应该与用户的实际登录状态保持一致。

**验证**: 需求 2.1, 2.2, 3.1, 3.2

### Property 6: API 请求参数正确性

*对于任何* API 请求，系统应该传递正确的参数（用户ID、类型、页码等），且参数值应该与当前的业务逻辑状态一致。

**验证**: 需求 7.1, 7.2, 7.3

### Property 7: 数据模型映射完整性

*对于任何* 从API返回的JSON数据，系统应该能够正确解析并映射到对应的数据模型，所有必需字段应该被正确映射，可选字段应该使用合理的默认值。

**验证**: 需求 8.1, 8.2, 8.3, 8.4, 8.5

### Property 8: 影视类型标识正确性

*对于任何* 影视内容，电影类型的seasonType应该为2，电视剧类型的seasonType应该为5，且这个值应该在整个数据流中保持一致。

**验证**: 需求 8.6, 8.7

### Property 9: 导航参数传递完整性

*对于任何* 导航操作，系统应该传递必需的参数（seasonId、episodeId、videoType等），且这些参数应该能够被目标页面正确接收和使用。

**验证**: 需求 9.1, 9.2

### Property 10: 页面状态初始化一致性

*对于任何* 页面初始化，系统应该将所有加载状态设置为加载中，将页码重置为1，将数据列表清空，确保页面处于一致的初始状态。

**验证**: 需求 10.1

### Property 11: 刷新操作数据一致性

*对于任何* 刷新操作，系统应该重置页码为1、清空现有数据、重新加载所有内容区域，确保刷新后显示的数据是最新的。

**验证**: 需求 10.4

### Property 12: 加载更多操作分页一致性

*对于任何* 加载更多操作，系统应该递增页码、保留现有数据、追加新加载的数据，确保分页加载的连续性和完整性。

**验证**: 需求 10.5

### Property 13: 资源释放完整性

*对于任何* 页面销毁操作，系统应该释放所有控制器、监听器和网络请求，防止内存泄漏和资源浪费。

**验证**: 需求 10.6

### Property 14: 错误处理一致性

*对于任何* 错误情况，系统应该显示包含错误原因的提示信息，提供重试按钮，且用户点击重试后应该能够重新发起失败的请求。

**验证**: 需求 13.1, 13.2, 13.3

### Property 15: 影视页面时间表隐藏

*对于任何* 影视页面显示，系统应该隐藏番剧时间表区域，只显示追剧、推荐等影视相关内容。

**验证**: 需求 14.5

## 错误处理

### 网络错误

**处理方式**:
1. 捕获网络异常
2. 更新状态为 `Error`
3. 显示错误提示信息
4. 提供重试按钮

**示例**:
```dart
try {
  var res = await FavHttp.favPgc(...);
  if (res.isSuccess) {
    followState.value = Success(res.data.list);
  } else {
    followState.value = Error(res.message);
  }
} catch (e) {
  followState.value = Error('网络错误: $e');
}
```

### 数据解析错误

**处理方式**:
1. 捕获JSON解析异常
2. 记录错误日志
3. 显示通用错误提示
4. 提供重试选项

### 认证错误

**处理方式**:
1. 检测未登录状态
2. 隐藏需要登录的功能
3. 显示登录提示
4. 提供登录入口

## 测试策略

### 单元测试

**测试范围**:
- 数据模型的JSON解析
- 控制器的状态管理逻辑
- 工具函数的正确性

**示例**:
```dart
test('FavPgcItemModel should parse JSON correctly', () {
  final json = {...};
  final model = FavPgcItemModel.fromJson(json);
  expect(model.seasonId, equals(123));
  expect(model.title, equals('示例标题'));
});
```

### 属性测试

**测试框架**: fast_check (Dart)

**Property 1: 追剧列表加载一致性**
```dart
// 生成随机的追剧列表数据
// 验证列表中的每个项目都有有效的seasonId和title
```

**Property 2: 推荐内容分页一致性**
```dart
// 生成随机的分页数据
// 验证新加载的内容被正确追加且不重复
```

**Property 3: 索引标签切换状态保持**
```dart
// 模拟标签切换操作
// 验证每个标签的状态被独立保持
```

### 集成测试

**测试范围**:
- 页面导航流程
- 数据加载和显示
- 用户交互和反馈

**示例**:
```dart
testWidgets('PgcPage should load and display follow list', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  
  expect(find.text('最近追剧'), findsOneWidget);
  expect(find.byType(PgcCardV), findsWidgets);
});
```

## 性能优化

### 列表优化

- 使用 `ListView.builder` 实现懒加载
- 使用 `SliverGrid` 实现高效网格渲染
- 使用 `AutomaticKeepAliveClientMixin` 保持页面状态

### 图片优化

- 使用图片缓存机制
- 使用占位图处理加载失败
- 使用适当的图片尺寸

### 网络优化

- 使用节流机制控制加载更多的触发频率
- 取消未完成的网络请求
- 使用请求去重机制

### 内存优化

- 及时释放控制器和监听器
- 避免内存泄漏
- 使用弱引用处理循环引用

## 安全性考虑

### 认证和授权

- 检查用户登录状态
- 验证用户权限
- 安全处理用户数据

### 数据验证

- 验证API返回的数据格式
- 检查数据的有效性
- 处理异常数据

### 网络安全

- 使用HTTPS加密通信
- 验证SSL证书
- 防止中间人攻击
