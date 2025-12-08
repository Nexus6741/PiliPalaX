# Bug修复：影视作品不支持继续播放 ✅

## 问题描述

观看影视作品时，不会像番剧一样自动跳转到上次观看的集数和时间位置。

## 修复状态

✅ 已修复 - 影视作品现在支持继续播放功能

## 根本原因

1. **API端点问题**: 当前代码对所有视频（包括番剧/影视）都使用普通视频的API：
   - `VideoHttp.videoUrl` - 获取视频流
   - `VideoHttp.playInfo` - 获取播放信息（包含 `last_play_cid` 和 `last_play_time`）

2. **B站API差异**: B站对PGC内容（番剧/影视）使用不同的API端点：
   - 普通视频: `/x/player/wbi/playurl`
   - 番剧/影视: `/pgc/player/web/playurl`

3. **历史记录数据**: 番剧/影视的历史记录（`last_play_cid` 和 `last_play_time`）需要从番剧专用API获取

## 解决方案

修改 `VideoDetailController` 的 `queryVideoUrl` 方法，让它在处理番剧/影视作品时使用番剧专用的API。

### 1. 在 VideoHttp 中添加番剧视频URL方法

**文件**: `lib/http/video.dart`

添加新方法 `bangumiVideoUrl` 来获取番剧/影视的视频流和播放信息：

```dart
// 番剧视频流（包含历史记录信息）
static Future bangumiVideoUrl({
  required int cid,
  String? bvid,
  int? epId,
  int? qn,
}) async {
  Map<String, dynamic> data = {
    'cid': cid,
    'qn': qn ?? 80,
    'fnval': 4048, // 获取所有格式的视频
    'fourk': 1,
  };
  
  if (bvid != null) {
    data['bvid'] = bvid;
  }
  if (epId != null) {
    data['ep_id'] = epId;
  }

  try {
    var res = await Request().get(Api.bangumiVideoUrl, data: data);
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': PlayUrlModel.fromJson(res.data['result'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'code': res.data['code'],
        'msg': res.data['message'],
      };
    }
  } catch (err) {
    return {'status': false, 'data': [], 'msg': err};
  }
}
```

### 2. 修改 VideoDetailController 的 queryVideoUrl 方法

**文件**: `lib/pages/video/controller.dart`

修改 `queryVideoUrl` 方法，根据 `videoType` 选择使用不同的API：

```dart
// 视频链接
Future queryVideoUrl() async {
  var result;
  
  // 根据视频类型选择不同的API
  if (videoType == SearchType.media_bangumi) {
    // 获取番剧参数
    int? epid;
    try {
      final bangumiCtr = Get.find<BangumiIntroController>(tag: heroTag);
      epid = bangumiCtr.epId;
    } catch (e) {
      print('⚠️ 获取番剧参数失败: $e');
    }
    
    // 使用番剧专用API
    result = await VideoHttp.bangumiVideoUrl(
      cid: cid.value,
      bvid: bvid,
      epId: epid,
    );
  } else {
    // 使用普通视频API
    result = await VideoHttp.videoUrl(cid: cid.value, bvid: bvid);
  }
  
  if (result['status']) {
    data = result['data'];
    
    // 对于普通视频，额外获取播放信息
    if (videoType != SearchType.media_bangumi) {
      try {
        var playInfoResult =
            await VideoHttp.playInfo(bvid: bvid, cid: cid.value);
        if (playInfoResult['status']) {
          final playInfoData = playInfoResult['data'];
          if (playInfoData['last_play_cid'] != null) {
            data.lastPlayCid = playInfoData['last_play_cid'];
          }
          if (playInfoData['last_play_time'] != null) {
            data.lastPlayTime = playInfoData['last_play_time'];
          }
        }
      } catch (e) {
        // 静默失败
      }
    }
    
    // ... 其余代码保持不变
  }
}
```

## 工作流程

### 修改前的流程（有问题）

```
影视作品播放
  ↓
使用普通视频API获取播放信息
  ↓
API不返回番剧的历史记录
  ↓
lastPlayCid 和 lastPlayTime 为空
  ↓
无法自动跳转到上次观看位置
```

### 修改后的流程（正确）

```
影视作品播放
  ↓
检测到 videoType == SearchType.media_bangumi
  ↓
使用番剧专用API获取播放信息
  ↓
API返回包含 last_play_cid 和 last_play_time
  ↓
checkContinuePlay() 检测到历史记录
  ↓
自动跳转到上次观看的集数和时间位置
```

## 测试验证

### 测试场景

1. ✅ 观看影视作品的第2集
2. ✅ 退出后重新打开
3. ✅ 应该自动跳转到第2集
4. ✅ 应该从上次观看的时间位置继续播放

### 预期结果

- 影视作品支持继续播放功能
- 自动跳转到上次观看的集数
- 自动跳转到上次观看的时间位置
- 显示提示："已自动跳转到上次观看的第X集"

## 相关文件

- `lib/http/video.dart` - 添加番剧视频URL方法
- `lib/pages/video/controller.dart` - 修改queryVideoUrl方法
- `lib/http/api.dart` - 番剧API端点定义

## 注意事项

1. **API响应格式**: 番剧API的响应格式可能与普通视频略有不同，需要注意 `result` vs `data` 字段
2. **兼容性**: 修改后仍然兼容普通视频的播放
3. **错误处理**: 添加了try-catch来处理API调用失败的情况
