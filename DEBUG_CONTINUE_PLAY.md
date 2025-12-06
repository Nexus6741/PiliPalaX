# 继续播放提示功能调试指南

## 调试日志说明

代码中已添加详细的调试日志，帮助定位问题。

### 日志标识
- 🔍 开始检查
- ✅ 成功/满足条件
- ❌ 失败/不满足条件
- ℹ️ 信息提示
- ⚠️ 警告
- ⏰ 定时器触发
- 📝 方法调用
- 🔄 重试

### 关键日志点

#### 1. checkContinuePlay 方法
```
🔍 checkContinuePlay 开始检查
  showContinuePlayTip: true/false
```
- 如果显示 `showContinuePlayTip 为 false，跳过检查`，说明已经检查过了
- 这个标志在每次检查后会设置为false，防止重复检查

#### 2. 获取VideoIntroController
```
  尝试获取 VideoIntroController...
  pages 数量: X
  data.lastPlayCid: XXXX
  当前 cid: XXXX
```
- 如果抛出异常，说明VideoIntroController还未初始化
- 代码会延迟500ms后重试，如果还失败会再延迟1000ms重试

#### 3. 条件检查
```
  ✅ 满足基本条件：多P视频且有历史记录
  或
  ❌ 不满足条件：
    - pages != null: true/false
    - pages.length > 1: true/false
    - lastPlayCid != null: true/false
    - lastPlayCid != 0: true/false
```

#### 4. 查找对应分P
```
  找到的索引: X
  ✅ 找到对应的分P，添加提示
  或
  ❌ 未找到对应的分P
```

#### 5. 添加提示
```
📝 addContinuePlayTip 被调用，pageIndex: X
  ✅ 添加到列表并插入动画
  continuePlayList: [X]
  listKey.currentState: AnimatedListState#xxxxx
  ✅ 提示添加完成
```

## 最新修复

### 问题：lastPlayCid总是0
**原因：** `videoUrl` API返回的`last_play_cid`不准确，经常是0

**解决方案：** 添加了`playInfo` API调用（`/x/player/wbi/v2`），这个API会返回更准确的历史记录信息

**新增日志：**
```
📡 videoUrl API返回数据:
  lastPlayTime: X
  lastPlayCid: 0
  当前请求的cid: XXXX

📡 playInfo API返回数据:
  last_play_cid: XXXX  (正确的值)
  last_play_time: XXXX
```

现在会先调用`videoUrl`获取视频流，然后调用`playInfo`获取准确的历史记录信息。

## 常见问题排查

### 问题1：没有任何日志输出
**可能原因：**
- checkContinuePlay 没有被调用
- queryVideoUrl 没有成功执行

**排查方法：**
1. 检查 queryVideoUrl 是否成功返回
2. 确认是否进入了 DASH 格式的处理分支

### 问题2：显示 "showContinuePlayTip 为 false"
**可能原因：**
- 已经检查过一次了
- 从历史记录进入（不需要提示）

**解决方法：**
- 这是正常行为，每个视频只检查一次
- 如果需要重新测试，需要重新进入视频页面

### 问题3：显示 "不满足条件"
**可能原因：**
- 视频只有1P（单P视频不需要提示）
- lastPlayCid 为 null 或 0（没有历史记录）
- lastPlayCid 等于当前 cid（已经在正确的分P上）

**排查方法：**
查看日志中的详细条件检查结果

### 问题4：显示 "未找到对应的分P"
**可能原因：**
- lastPlayCid 对应的分P不在当前视频的pages列表中
- 可能是API返回的数据有问题

**排查方法：**
1. 检查 data.lastPlayCid 的值
2. 检查 pages 列表中所有分P的cid
3. 确认是否匹配

### 问题5：显示 "异常"
**可能原因：**
- VideoIntroController 还未初始化
- 代码会自动重试

**排查方法：**
- 查看是否有 "第二次尝试成功" 的日志
- 如果两次都失败，可能需要增加延迟时间

### 问题6：提示添加成功但UI上看不到
**可能原因：**
- AnimatedList 的位置不对
- AnimatedList 被其他组件遮挡
- listKey.currentState 为 null

**排查方法：**
1. 检查日志中的 `listKey.currentState` 是否为 null
2. 检查 view.dart 中 AnimatedList 的位置和层级
3. 尝试修改 Positioned 的 left 和 bottom 值

## 测试步骤

1. **准备测试视频**
   - 找一个多P视频（至少2P）
   - 观看第2P或更后面的分P
   - 播放一段时间后退出

2. **从搜索进入**
   - 搜索该视频
   - 点击进入（默认会打开第1P）
   - 查看控制台日志

3. **查看日志输出**
   - 应该看到 `🔍 checkContinuePlay 开始检查`
   - 查看后续的条件检查结果
   - 确认是否添加了提示

4. **查看UI**
   - 在视频左下角（bottom: 75, left: 16）查看是否有提示
   - 提示应该显示 "上次看到第X P，点击跳转"

5. **测试交互**
   - 点击提示，应该跳转到对应的分P
   - 或等待4秒，提示应该自动消失

## 调整建议

如果提示位置不合适，可以修改 `lib/pages/video/view.dart` 中的 Positioned 参数：

```dart
Positioned(
  left: 16,    // 距离左边的距离
  bottom: 75,  // 距离底部的距离
  child: SizedBox(
    width: 200,  // 提示框的宽度
    ...
  ),
),
```

如果延迟时间不够，可以修改 `lib/pages/video/controller.dart` 中的延迟时间：

```dart
Future.delayed(const Duration(milliseconds: 500), () {  // 第一次延迟
  ...
  Future.delayed(const Duration(milliseconds: 1000), () {  // 第二次延迟
    ...
  });
});
```


## 番剧 CID 上报问题修复

### 问题描述
番剧视频播放时，历史记录的 `last_play_cid` 没有正确保存，导致无法跳转到上次观看的集数。

**测试现象：**
- 在 PiliPalaX 中观看番剧后，再次打开不会跳转
- 在 PiliPlus 中观看番剧后，用 PiliPalaX 打开可以跳转
- 说明 PiliPalaX 的 cid 上报有问题

### 根本原因
当前项目的 `heartBeat` 上报只传递了 `bvid` 和 `cid`，缺少番剧特有的参数：
- `epid` - 番剧剧集ID
- `sid` (seasonId) - 番剧季度ID

B站服务器需要这些参数才能正确保存番剧的观看历史。

### 解决方案

#### 1. 修改 PlPlayerController 存储番剧参数
在 `lib/plugin/pl_player/controller.dart` 中：

```dart
// 添加番剧参数存储
int? _epid;
int? _seasonId;

// setDataSource 接收番剧参数
Future<bool> setDataSource(
  DataSource dataSource, {
  // ... 其他参数
  int? epid,
  int? seasonId,
  // ...
}) async {
  _epid = epid;
  _seasonId = seasonId;
  // ...
}
```

#### 2. 修改 makeHeartBeat 传递番剧参数
```dart
Future makeHeartBeat(int progress, {type = 'playing'}) async {
  // ...
  await VideoHttp.heartBeat(
    bvid: _bvid,
    cid: _cid,
    progress: progress,
    epid: _epid,        // 新增
    seasonId: _seasonId, // 新增
  );
}
```

#### 3. 修改 VideoHttp.heartBeat 接收番剧参数
在 `lib/http/video.dart` 中：

```dart
static Future heartBeat({
  bvid, 
  cid, 
  progress, 
  realtime,
  int? epid,      // 新增
  int? seasonId,  // 新增
}) async {
  print('💓 heartBeat上报:');
  print('  bvid: $bvid');
  print('  cid: $cid');
  print('  epid: $epid');
  print('  seasonId: $seasonId');
  print('  played_time: $progress');
  
  await Request().post(Api.heartBeat, queryParameters: {
    'bvid': bvid,
    'cid': cid,
    'epid': epid ?? '',      // 新增
    'sid': seasonId ?? '',   // 新增
    'played_time': progress,
    'csrf': await Request.getCsrf(),
  });
}
```

#### 4. 修改 VideoDetailController 传递番剧参数
在 `lib/pages/video/controller.dart` 中：

```dart
// 在 setDataSource 调用前获取番剧参数
int? epid;
int? seasonId;
if (videoType == SearchType.media_bangumi) {
  try {
    final bangumiCtr = Get.find<BangumiIntroController>(tag: heroTag);
    epid = bangumiCtr.epId;
    seasonId = bangumiCtr.seasonId;
  } catch (e) {
    print('⚠️ 获取番剧参数失败: $e');
  }
}

await plPlayerController!.setDataSource(
  // ...
  epid: epid,
  seasonId: seasonId,
  // ...
);
```

### 参考实现
参考了 PiliPlus 项目的实现：
- `PiliPlus/lib/plugin/pl_player/controller.dart` - makeHeartBeat 方法（第1620-1670行）
- `PiliPlus/lib/http/video.dart` - heartBeat API 调用（第664-690行）

### 调试日志
新增的日志输出：
```
💓 heartBeat上报:
  bvid: BV1xx...
  cid: 123456
  epid: 789012
  seasonId: 345678
  played_time: 30
```

### 测试步骤
1. 打开一个番剧视频
2. 播放一段时间（至少3秒，触发heartbeat）
3. 查看控制台日志，确认 epid 和 seasonId 不为空
4. 退出视频
5. 重新进入该番剧，应该能跳转到上次观看的集数

### 相关文件
- `lib/plugin/pl_player/controller.dart` - 存储和传递番剧参数
- `lib/http/video.dart` - heartBeat API 支持番剧参数
- `lib/pages/video/controller.dart` - 获取并传递番剧参数


### epId 为 null 的问题修复

#### 问题
日志显示 `epid: null` 但 `seasonId` 有值，导致番剧的 heartbeat 上报不完整。

#### 原因
1. `BangumiIntroController` 的 `epId` 初始值从路由参数 `Get.parameters['epId']` 获取
2. 如果路由中没有传递 `epId` 参数，它就会是 null
3. 在 `queryBangumiIntro` 中会设置为第一集的 id：`epId = bangumiDetail.value.episodes!.first.id`
4. 但在切换集数时（`changeSeasonOrbangu`），没有更新 `epId`

#### 解决方案
修改 `changeSeasonOrbangu` 方法，在切换集数时更新 `epId`：

```dart
// lib/pages/video/introduction/bangumi/controller.dart

Future changeSeasonOrbangu(bvid, cid, aid, {int? epid}) async {
  // ... 其他代码
  
  // 更新 epId（如果提供了）
  if (epid != null) {
    epId = epid;
    print('🔄 更新 epId: $epId');
  }
  
  // ... 其他代码
}
```

在 `prevPlay` 和 `nextPlay` 中传递 epid：

```dart
// prevPlay
int? epid = episodes[prevIndex].id;
changeSeasonOrbangu(bvid, cid, aid, epid: epid);

// nextPlay
int? epid = episodes[nextIndex].id;
changeSeasonOrbangu(bvid, cid, aid, epid: epid);
```

#### 测试
1. 打开番剧视频
2. 切换到其他集数
3. 查看日志，确认 `epid` 不再是 null
4. 播放一段时间后退出
5. 重新进入应该能跳转到正确的集数


### 完整修复清单

为了确保番剧的 `epId` 在所有场景下都能正确传递和更新，需要修改以下文件：

#### 1. lib/pages/video/introduction/bangumi/controller.dart
- 修改 `changeSeasonOrbangu` 方法签名，添加可选的 `epid` 参数
- 在 `prevPlay` 和 `nextPlay` 中传递 `epid`

#### 2. lib/pages/bangumi/widgets/bangumi_panel.dart
- 在番剧分集列表的点击事件中传递 `epid: widget.pages[i].id`

#### 3. lib/common/widgets/list_sheet.dart
- 在 `_onTap` 方法中，当 episode 是 `EpisodeItem` 时传递 `epid: episode.id`

#### 4. lib/plugin/pl_player/controller.dart
- 添加 `_epid` 和 `_seasonId` 变量
- `setDataSource` 方法接收这些参数
- `makeHeartBeat` 方法传递这些参数

#### 5. lib/http/video.dart
- `heartBeat` 方法接收 `epid` 和 `seasonId` 参数
- 在上报时包含这些参数

#### 6. lib/pages/video/controller.dart
- 在调用 `setDataSource` 前，从 `BangumiIntroController` 获取番剧参数
- 传递给 `setDataSource`

### 测试验证
完成所有修改后，测试以下场景：

1. **从历史记录进入番剧** ✅
   - 应该能定位到上次观看的集数和时间点

2. **从搜索/推荐进入番剧** ✅
   - 应该能自动跳转到上次观看的集数

3. **在番剧页面切换集数**（重点测试）
   - 点击横向滚动列表中的集数
   - 点击"全X话"弹出的列表中的集数
   - 使用自动播放下一集
   - 使用播放上一集
   - 所有场景下 heartbeat 都应该包含正确的 `epid`

4. **退出后重新进入**
   - 用 PiliPalaX 观看番剧后退出
   - 重新进入应该能跳转到上次观看的集数
   - 不应该只能通过历史记录页面才能定位


### 番剧自动跳转支持

#### 问题
虽然 heartbeat 上报已经包含了正确的 `epid`，但从搜索/推荐进入番剧时仍然不能自动跳转到上次观看的集数。

#### 原因
`checkContinuePlay` 方法只支持普通视频（使用 `VideoIntroController` 和 `pages`），没有支持番剧（应该使用 `BangumiIntroController` 和 `episodes`）。

#### 解决方案
修改 `lib/pages/video/controller.dart` 中的 `checkContinuePlay` 方法：

1. 判断 `videoType` 是否为 `SearchType.media_bangumi`
2. 如果是番剧：
   - 使用 `BangumiIntroController` 获取 `episodes`
   - 查找 `lastPlayCid` 对应的集数
   - 调用 `bangumiIntroController.changeSeasonOrbangu` 并传递 `epid`
3. 如果是普通视频：
   - 保持原有逻辑不变

#### 关键代码
```dart
if (videoType == SearchType.media_bangumi) {
  final bangumiIntroController = Get.find<BangumiIntroController>(tag: heroTag);
  final episodes = bangumiIntroController.bangumiDetail.value.episodes;
  
  if (episodes != null && episodes.length > 1 && 
      data.lastPlayCid != null && data.lastPlayCid != 0 && 
      data.lastPlayCid != cid.value) {
    final index = episodes.indexWhere((ep) => ep.cid == data.lastPlayCid);
    if (index != -1) {
      final episode = episodes[index];
      bangumiIntroController.changeSeasonOrbangu(
        episode.bvid,
        episode.cid,
        episode.aid,
        epid: episode.id,  // 重要：传递 epid
      );
      SmartDialog.showToast('已自动跳转到上次观看的第${episode.title}');
    }
  }
}
```

#### 测试
1. 用 PiliPalaX 观看番剧的某一集（比如第5集）
2. 播放一段时间后退出
3. 从搜索或推荐重新进入该番剧
4. 应该能看到自动跳转的 Toast 提示
5. 应该能定位到第5集并从上次的时间点继续播放


### 番剧 heartbeat 上报参数修复

#### 问题
虽然 `epid` 和 `seasonId` 都有值了，但番剧历史记录仍然无法正确保存。

#### 根本原因
通过抓取网页版 B站的番剧 heartbeat 请求，发现番剧需要额外的参数：
- `type: 4` - 表示番剧类型
- `sub_type: 4` - 表示番剧子类型

这两个参数是 B站服务器识别番剧历史记录的关键。

#### 网页版请求示例
```
aid: 114718308044786
cid: 30610296478
type: 4           // 番剧类型
sub_type: 4       // 番剧子类型
sid: 28747        // seasonId
epid: 1231556     // episodeId
played_time: 138
```

#### 解决方案
修改 `lib/http/video.dart` 中的 `heartBeat` 方法：

```dart
// 判断是否为番剧（有 epid 和 seasonId）
bool isBangumi = epid != null && seasonId != null;

await Request().post(Api.heartBeat, queryParameters: {
  'bvid': bvid,
  'cid': cid,
  if (isBangumi) 'epid': epid,
  if (isBangumi) 'sid': seasonId,
  if (isBangumi) 'type': 4,        // 番剧类型
  if (isBangumi) 'sub_type': 4,    // 番剧子类型
  'played_time': progress,
  'csrf': await Request.getCsrf(),
});
```

#### 关键点
1. 只有当 `epid` 和 `seasonId` 都不为 null 时，才添加番剧相关参数
2. `type: 4` 和 `sub_type: 4` 是固定值，表示番剧类型
3. 普通视频不需要这些参数

#### 测试
1. 重新编译运行
2. 打开番剧视频并播放
3. 查看日志确认 heartbeat 包含所有参数
4. 退出后重新进入
5. 应该能正确跳转到上次观看的集数
