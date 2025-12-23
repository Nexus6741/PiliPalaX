# PGC历史记录标签显示修复完成

## 问题描述

观看完番剧、电影、电视剧、综艺后，在历史记录中查看时，右上角的标签都显示为"国创"，而不是对应的正确标签（如电影、电视剧、综艺等）。

## 问题原因

在上报播放历史记录时，所有PGC内容（番剧、电影、电视剧、综艺、纪录片、国创）都使用了固定的 `sub_type: 4`（国创），导致B站服务器将所有PGC内容都记录为"国创"类型。

### B站PGC内容类型定义

- `1` = 番剧
- `2` = 电影
- `3` = 纪录片
- `4` = 国创
- `5` = 电视剧
- `7` = 综艺

## 问题根源分析

通过调试日志发现，`playerInit` 在 `queryBangumiIntro` **之前**执行：

1. `playerInit` 执行时：`bangumiDetail.value.type` 为 `null`（未初始化）
2. `queryBangumiIntro` 执行时：`type` 为 `2`（电影）

这导致无法获取正确的 `seasonType`，所有PGC内容都使用默认值 `1`（番剧）。

## 修复方案

### 最终方案：从 bangumiItem 获取备用值

在 `playerInit` 时，优先从 `bangumiDetail.value.type` 获取，如果为 `null` 则从传入的 `bangumiItem.type` 获取：

**文件：`lib/pages/video/controller.dart`**

```dart
// 🔥 修复：优先从 bangumiDetail 获取，如果为 null 则从 bangumiItem 获取
seasonType = bangumiCtr.bangumiDetail.value.type;
if (seasonType == null && bangumiCtr.bangumiItem != null) {
  seasonType = bangumiCtr.bangumiItem!.type;
  print('⚠️ bangumiDetail.value.type 为 null，从 bangumiItem 获取: $seasonType');
}
```

这样可以确保在 `bangumiDetail` 还未加载完成时，也能从传入的 `bangumiItem` 中获取正确的 `type` 值。

## 修复方案

### 1. 添加 seasonType 字段

在播放器控制器中添加 `_seasonType` 字段，用于保存PGC内容的实际类型：

**文件：`lib/plugin/pl_player/controller.dart`**

```dart
// 记录历史记录
String _bvid = '';
int _cid = 0;
int? _epid;
int? _seasonId;
int? _seasonType; // PGC内容类型：1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺
int _heartDuration = 0;
bool _enableHeart = true;
```

### 2. 修改 setDataSource 方法

在 `setDataSource` 方法中添加 `seasonType` 参数，并保存到 `_seasonType` 字段：

**文件：`lib/plugin/pl_player/controller.dart`**

```dart
Future<bool> setDataSource(
  DataSource dataSource, {
  // ... 其他参数
  int? epid,
  int? seasonId,
  int? seasonType, // 新增：PGC内容类型
  // ...
}) async {
  // ...
  _epid = epid;
  _seasonId = seasonId;
  _seasonType = seasonType; // 保存PGC内容类型
  // ...
}
```

### 3. 修改 makeHeartBeat 方法

在调用 `VideoHttp.heartBeat` 时传递 `seasonType` 参数：

**文件：`lib/plugin/pl_player/controller.dart`**

```dart
Future makeHeartBeat(int progress, {type = 'playing'}) async {
  // ...
  await VideoHttp.heartBeat(
    bvid: _bvid,
    cid: _cid,
    progress: progress,
    epid: _epid,
    seasonId: _seasonId,
    seasonType: _seasonType, // 传递PGC内容类型
  );
  // ...
}
```

### 4. 修改 VideoHttp.heartBeat 方法

使用实际的 `seasonType` 作为 `sub_type` 参数：

**文件：`lib/http/video.dart`**

```dart
static Future heartBeat({
  bvid,
  cid,
  progress,
  realtime,
  int? epid,
  int? seasonId,
  int? seasonType, // 新增：PGC内容类型
}) async {
  bool isBangumi = epid != null && seasonId != null;

  await Request().post(Api.heartBeat, queryParameters: {
    'bvid': bvid,
    'cid': cid,
    if (isBangumi) 'epid': epid,
    if (isBangumi) 'sid': seasonId,
    if (isBangumi) 'type': 4, // 番剧类型（PGC大类）
    if (isBangumi) 'sub_type': seasonType ?? 1, // 使用实际的PGC子类型
    'played_time': progress,
    'csrf': await Request.getCsrf(),
  });
}
```

### 5. 在视频详情控制器中传递 seasonType

从番剧详情控制器获取 `seasonType` 并传递给播放器：

**文件：`lib/pages/video/controller.dart`**

```dart
Future playerInit({...}) async {
  if (!resumePlay) {
    int? epid;
    int? seasonId;
    int? seasonType; // PGC内容类型
    
    if (videoType == SearchType.media_bangumi ||
        videoType == SearchType.media_ft) {
      try {
        final bangumiCtr = Get.find<BangumiIntroController>(tag: heroTag);
        epid = bangumiCtr.epId;
        seasonId = bangumiCtr.seasonId;
        seasonType = bangumiCtr.bangumiDetail.value.type; // 获取PGC内容类型
        print('🔍 PGC内容类型: seasonType=$seasonType');
      } catch (e) {
        print('⚠️ 获取番剧参数失败: $e');
      }
    }

    await plPlayerController!.setDataSource(
      // ...
      epid: epid,
      seasonId: seasonId,
      seasonType: seasonType, // 传递PGC内容类型
      // ...
    );
  }
}
```

## 修改的文件

1. `lib/plugin/pl_player/controller.dart` - 播放器控制器
2. `lib/http/video.dart` - 视频HTTP接口
3. `lib/pages/video/controller.dart` - 视频详情控制器

## 测试验证

### 调试日志

为了帮助诊断问题，已添加详细的调试日志。在播放PGC内容时，控制台会输出以下信息：

#### 1. 番剧详情获取时
```
🔍 [queryBangumiIntro] 番剧详情获取成功:
   - seasonId: 12345
   - title: 某某电影
   - type: 2
   - 类型说明: 1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺
```

#### 2. 播放器初始化时
```
🔍 [playerInit] 获取PGC参数:
   - videoType: SearchType.media_bangumi
   - epid: 123456
   - seasonId: 12345
   - seasonType: 2
   - bangumiDetail.value: Instance of 'BangumiInfoModel'
   - bangumiDetail.value.type: 2
   - 类型说明: 1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺
```

#### 3. setDataSource保存参数时
```
🔍 [setDataSource] 保存PGC参数:
   - _epid: 123456
   - _seasonId: 12345
   - _seasonType: 2
```

#### 4. 历史记录上报时
```
🔍 [heartBeat] PGC内容历史记录上报:
   - bvid: BV1xx411c7mD
   - cid: 123456
   - epid: 123456
   - seasonId: 12345
   - seasonType: 2
   - sub_type将设置为: 2
   - 类型说明: 1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺
```

### 问题诊断

如果所有PGC内容都显示为"番剧"，请检查日志中的以下信息：

1. **`seasonType` 是否为 `null`**：如果显示 `(null)`，说明 `bangumiDetail.value.type` 没有正确获取
2. **`type` 字段的值**：确认 B站 API 返回的 `type` 字段是否正确
3. **`sub_type` 的最终值**：确认上报时使用的 `sub_type` 是否正确

### 测试步骤

1. 观看一部电影（seasonType = 2）
2. 观看一部电视剧（seasonType = 5）
3. 观看一部综艺（seasonType = 7）
4. 观看一部纪录片（seasonType = 3）
5. 观看一部国创（seasonType = 4）
6. 观看一部番剧（seasonType = 1）

### 预期结果

在历史记录页面中，每个PGC内容的右上角标签应该显示其对应的正确类型：
- 电影 → 显示"电影"
- 电视剧 → 显示"电视剧"
- 综艺 → 显示"综艺"
- 纪录片 → 显示"纪录片"
- 国创 → 显示"国创"
- 番剧 → 显示"番剧"

### 调试日志

在播放PGC内容时，控制台会输出：
```
🔍 PGC内容类型: seasonType=2 (1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺)
```

## 技术细节

### B站历史记录API

- **接口**: `/x/web-interface/history/report`
- **关键参数**:
  - `type`: 大类型（4 = PGC内容）
  - `sub_type`: 子类型（1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺）
  - `epid`: 剧集ID
  - `sid`: 系列ID（seasonId）

### 数据流向

```
番剧详情API响应
  ↓ (包含 season_type 字段)
BangumiIntroController.bangumiDetail.value.type
  ↓
VideoDetailController.playerInit() 获取 seasonType
  ↓
PlPlayerController.setDataSource() 保存到 _seasonType
  ↓
PlPlayerController.makeHeartBeat() 传递 seasonType
  ↓
VideoHttp.heartBeat() 使用 seasonType 作为 sub_type
  ↓
B站服务器记录正确的PGC类型
  ↓
历史记录API返回正确的 badge 标签
```

## 注意事项

1. **默认值处理**: 如果无法获取 `seasonType`，默认使用 `1`（番剧）
2. **兼容性**: 对于普通视频（非PGC内容），不会传递 `seasonType`，保持原有逻辑
3. **历史数据**: 修复后只影响新的观看记录，之前的历史记录标签不会改变

## 完成时间

2025-12-23
