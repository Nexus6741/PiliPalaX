# 用户空间投稿Tab合集功能完善

## 实施时间
2024年12月22日

## 本次完善内容

### 1. 添加API端点定义
**文件**: `lib/http/api.dart`

添加了完整的用户空间相关API端点：

```dart
// 用户投稿视频（App API，支持游标分页）
static const String spaceArchive =
    '${HttpString.appBaseUrl}/x/v2/space/archive/cursor';

// 用户充电专属视频
static const String spaceChargingArchive =
    '${HttpString.appBaseUrl}/x/v2/space/archive/charging';

// 用户合集视频
static const String spaceSeason =
    '${HttpString.appBaseUrl}/x/v2/space/season/videos';

// 用户列表视频
static const String spaceSeries =
    '${HttpString.appBaseUrl}/x/v2/space/series';

// 用户追番
static const String spaceBangumi =
    '${HttpString.appBaseUrl}/x/v2/space/bangumi';

// 用户专栏
static const String spaceArticle =
    '${HttpString.appBaseUrl}/x/v2/space/article';

// 用户音频
static const String spaceAudio = '/audio/music-service/web/song/upper';

// 用户漫画
static const String spaceComic = '${HttpString.appBaseUrl}/x/v2/space/comic';

// 合集和列表
static const String seasonSeries = '/x/polymer/web-space/seasons_series_list';
```

### 2. 实现spaceArchive方法
**文件**: `lib/http/member.dart`

创建了统一的`spaceArchive`方法，支持多种视频类型：

**方法签名**：
```dart
static Future spaceArchive({
  required String type,      // 'video', 'charging', 'season', 'series'
  required int mid,          // 用户ID
  String? aid,               // 用于游标分页
  String? order,             // 'pubdate' 或 'click'
  String? sort,              // 'desc' 或 'asc'
  int? pn,                   // 页码（充电专属使用）
  int? next,                 // 下一页标识
  int? seasonId,             // 合集ID
  int? seriesId,             // 列表ID
  bool? includeCursor,       // 是否包含游标信息
})
```

**支持的类型**：
- `video` - 普通投稿视频（使用 `/x/v2/space/archive/cursor`）
- `charging` - 充电专属视频（使用 `/x/v2/space/archive/charging`）
- `season` - 合集视频（使用 `/x/v2/space/season/videos`）
- `series` - 列表视频（使用 `/x/v2/space/series`）

**关键特性**：
1. **统一接口** - 一个方法处理所有类型的视频加载
2. **App API** - 使用与PiliPlus相同的App API
3. **签名支持** - 自动添加access_key和签名
4. **游标分页** - 支持基于aid的游标分页
5. **调试日志** - 输出详细的请求和响应信息

**API参数说明**：
```dart
// 通用参数
build: 8430300
version: '8.43.0'
c_locale: 'zh_CN'
channel: 'master'
mobi_app: 'android'
platform: 'android'
s_locale: 'zh_CN'
ps: 20                    // 每页数量
vmid: mid                 // 用户ID
ts: timestamp             // 时间戳
access_key: xxx           // 登录凭证（如果已登录）
sign: xxx                 // 签名

// 类型特定参数
aid: xxx                  // 游标（video类型）
order: 'pubdate'/'click'  // 排序方式（video类型）
sort: 'desc'/'asc'        // 排序方向（其他类型）
pn: 1                     // 页码（charging类型）
next: xxx                 // 下一页标识
season_id: xxx            // 合集ID（season类型）
series_id: xxx            // 列表ID（series类型）
qn: 80/32                 // 视频质量
```

### 3. 现有功能回顾

#### MemberContribute 组件
**文件**: `lib/pages/member_contribute/view.dart`, `lib/pages/member_contribute/controller.dart`

**已实现功能**：
- ✅ 动态Tab生成
- ✅ 合集/列表自动检测
- ✅ "全部合集/列表"Tab自动添加
- ✅ TabBar样式（完全按照PiliPlus）
- ✅ Tab切换和状态保持

**当前页面映射**：
| param          | 显示名称      | 当前实现          | API支持 |
| -------------- | ------------- | ----------------- | ------- |
| video          | 视频          | MemberArchivePage | ✅       |
| charging_video | 充电专属      | MemberArchivePage | ✅       |
| season_video   | 合集名称      | MemberArchivePage | ✅       |
| series         | 列表名称      | MemberArchivePage | ✅       |
| article        | 专栏          | 占位符            | ✅       |
| opus           | 图文          | 占位符            | ❌       |
| audio          | 音频          | 占位符            | ✅       |
| comic          | 漫画          | 占位符            | ✅       |
| ugcSeason      | 全部合集/列表 | 占位符            | ✅       |

## 下一步计划

### 优先级1：改进MemberArchivePage以支持不同类型
**目标**：让MemberArchivePage能够根据type、seasonId、seriesId加载对应的视频

**需要修改**：
1. `lib/pages/member_archive/controller.dart`
   - 添加type、seasonId、seriesId参数
   - 使用新的`MemberHttp.spaceArchive`方法
   - 根据type调整排序选项

2. `lib/pages/member_archive/view.dart`
   - 接收type、seasonId、seriesId参数
   - 传递给controller

3. `lib/pages/member_contribute/view.dart`
   - 传递正确的参数给MemberArchivePage

**实现示例**：
```dart
// 在 MemberContribute 中
case 'video':
  return MemberArchivePage(
    mid: widget.mid,
    type: 'video',
  );
case 'season_video':
  return MemberArchivePage(
    mid: widget.mid,
    type: 'season',
    seasonId: item.seasonId,
    title: item.title,
  );
case 'series':
  return MemberArchivePage(
    mid: widget.mid,
    type: 'series',
    seriesId: item.seriesId,
    title: item.title,
  );
```

### 优先级2：创建其他类型页面
1. **MemberArticle** - 专栏页面
   - 使用 `Api.spaceArticle`
   - 显示专栏文章列表

2. **MemberAudio** - 音频页面
   - 使用 `Api.spaceAudio`
   - 显示音频列表

3. **MemberComic** - 漫画页面
   - 使用 `Api.spaceComic`
   - 显示漫画列表

4. **SeasonSeriesPage** - 全部合集/列表页面
   - 使用 `Api.seasonSeries`
   - 显示所有合集和列表

### 优先级3：完善数据模型
创建对应的数据模型类：
- `SpaceArchiveData` - 视频列表数据
- `SpaceArticleData` - 专栏数据
- `SpaceAudioData` - 音频数据
- `SpaceComicData` - 漫画数据
- `SeasonSeriesData` - 合集列表数据

## API使用示例

### 1. 获取普通投稿视频
```dart
var res = await MemberHttp.spaceArchive(
  type: 'video',
  mid: 123456,
  order: 'pubdate',  // 最新发布
);
```

### 2. 获取充电专属视频
```dart
var res = await MemberHttp.spaceArchive(
  type: 'charging',
  mid: 123456,
  pn: 1,
);
```

### 3. 获取合集视频
```dart
var res = await MemberHttp.spaceArchive(
  type: 'season',
  mid: 123456,
  seasonId: 789,
  sort: 'desc',
);
```

### 4. 获取列表视频
```dart
var res = await MemberHttp.spaceArchive(
  type: 'series',
  mid: 123456,
  seriesId: 456,
  sort: 'desc',
);
```

## 技术要点

### 1. API端点选择
根据type参数自动选择正确的API端点：
```dart
String apiUrl;
switch (type) {
  case 'video':
    apiUrl = Api.spaceArchive;
    break;
  case 'charging':
    apiUrl = Api.spaceChargingArchive;
    break;
  case 'season':
    apiUrl = Api.spaceSeason;
    break;
  case 'series':
    apiUrl = Api.spaceSeries;
    break;
}
```

### 2. 参数处理
只添加非空参数，避免不必要的参数传递：
```dart
if (aid != null) params['aid'] = aid;
if (order != null) params['order'] = order;
if (seasonId != null) params['season_id'] = seasonId;
```

### 3. 签名机制
使用AppSign进行参数签名：
```dart
AppSign.appSign(params);
```

### 4. 调试支持
输出详细的请求和响应信息：
```dart
print('========== spaceArchive API Request ==========');
print('Type: $type');
print('API URL: $apiUrl');
print('Season ID: $seasonId');
print('==============================================');
```

## 测试建议

### 1. 测试不同类型
- 普通视频（video）
- 充电专属（charging）
- 合集视频（season）
- 列表视频（series）

### 2. 测试排序
- 最新发布（pubdate）
- 最多播放（click）
- 正序（asc）
- 倒序（desc）

### 3. 测试分页
- 第一页加载
- 上拉加载更多
- 下拉刷新

### 4. 测试边界情况
- 无视频内容
- 网络错误
- 未登录状态

## 参考资料

### PiliPlus 参考
- `PiliPlus/lib/http/api.dart` - API端点定义
- `PiliPlus/lib/http/member.dart` - spaceArchive实现
- `PiliPlus/lib/pages/member_video/controller.dart` - 视频加载逻辑

### bilibili-API-collect
- 用户空间API文档
- 视频列表API文档
- 合集和列表API文档

## 总结

本次完善为投稿Tab功能奠定了坚实的基础：

1. ✅ **API端点完整** - 添加了所有需要的API端点定义
2. ✅ **统一接口** - 创建了spaceArchive统一方法
3. ✅ **类型支持** - 支持video、charging、season、series四种类型
4. ✅ **签名机制** - 正确实现了App API的签名
5. ✅ **调试支持** - 添加了详细的日志输出

下一步只需要：
- 改进MemberArchivePage以使用新的API
- 创建其他类型的页面（专栏、音频、漫画等）
- 完善数据模型

整个投稿Tab功能就能完全按照PiliPlus实现了！
