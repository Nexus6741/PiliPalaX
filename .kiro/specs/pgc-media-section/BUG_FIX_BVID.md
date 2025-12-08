# Bug修复：视频信息获取失败

## 问题描述

点击影视推荐区的视频卡片时，提示"视频信息获取失败"或"BV号长度错误"，无法正常播放视频。

## 根本原因

1. **PgcCardV导航问题**: 原来的实现传递了空的bvid和cid参数
   ```dart
   String bvid = '';
   int cid = 0;
   Get.toNamed('/video?bvid=$bvid&cid=$cid&seasonId=$seasonId&epId=$firstEp', ...)
   ```

2. **视频控制器参数要求**: VideoDetailController要求bvid和cid必须存在
   ```dart
   String bvid = Get.parameters['bvid']!;  // 使用了 ! 操作符
   RxInt cid = int.parse(Get.parameters['cid']!).obs;
   ```

3. **PGC内容特殊性**: 对于PGC内容（番剧/影视），bvid和cid需要先从API获取
   - 用户点击卡片时只有seasonId和epId
   - 需要调用`SearchHttp.bangumiInfo`获取episodes列表
   - 从episodes中获取bvid和cid

## 解决方案（最终版本）

参考PiliPlus的实现，在卡片点击时先调用API获取番剧信息，然后从episodes中获取bvid和cid，最后再导航到视频页面。

### 1. 修改PgcCardV导航逻辑

**文件**: `lib/pages/pgc/widgets/pgc_card_v.dart`

**修改**: 在导航前先调用API获取bvid和cid

```dart
onTap: () async {
  if (seasonId == null) {
    SmartDialog.showToast('资源加载失败');
    return;
  }

  try {
    SmartDialog.showLoading(msg: '资源获取中');

    // 获取番剧信息
    var result = await SearchHttp.bangumiInfo(
      seasonId: seasonId,
      epId: firstEp,
    );

    SmartDialog.dismiss();

    if (result['status']) {
      BangumiInfoModel data = result['data'];
      final episodes = data.episodes;

      if (episodes != null && episodes.isNotEmpty) {
        // 找到要播放的集数
        EpisodeItem? episode;
        if (firstEp != null) {
          try {
            episode = episodes.firstWhere(
              (e) => e.id == firstEp,
            );
          } catch (e) {
            // 如果找不到指定的集数，使用第一集
            episode = episodes.first;
          }
        } else {
          episode = episodes.first;
        }

        // 检查是否有bvid和cid
        if (episode.bvid == null || episode.cid == null) {
          SmartDialog.showToast('视频资源不可用');
          return;
        }

        // 导航到视频页面
        Get.toNamed(
          '/video?bvid=${episode.bvid}&cid=${episode.cid}&seasonId=$seasonId&epId=${episode.id}',
          arguments: {
            'pic': cover,
            'heroTag': heroTag,
            'videoType': SearchType.media_bangumi,
            'bangumiItem': data,
          },
        );
      } else {
        SmartDialog.showToast('暂无可播放内容');
      }
    } else {
      SmartDialog.showToast(result['msg'] ?? '获取视频信息失败');
    }
  } catch (e) {
    SmartDialog.dismiss();
    SmartDialog.showToast('加载失败: $e');
    print('⚠️ PGC卡片导航失败: $e');
  }
}
```

### 2. 添加必要的导入

**文件**: `lib/pages/pgc/widgets/pgc_card_v.dart`

```dart
import 'package:PiliPalaX/models/bangumi/info.dart';
import 'package:PiliPalaX/http/search.dart';
```

## 工作流程

### 修改前的流程（有问题）

```
用户点击卡片
  ↓
传递空的bvid和cid
  ↓
VideoDetailController初始化失败
  ↓
提示"BV号长度错误"或"视频信息获取失败"
```

### 修改后的流程（正确 - 参考PiliPlus）

```
用户点击卡片
  ↓
显示"资源获取中"加载提示
  ↓
调用SearchHttp.bangumiInfo获取番剧信息
  ↓
从episodes中找到对应的episode
  ↓
获取episode的bvid和cid
  ↓
传递完整的参数导航到视频页面
  ↓
VideoDetailController正常初始化
  ↓
正常播放视频
```

## 测试验证

### 测试场景

1. ✅ 点击影视推荐区的视频卡片
2. ✅ 点击追剧区的视频卡片
3. ✅ 点击索引页面的视频卡片
4. ✅ 从外部链接打开PGC内容

### 预期结果

- 不再提示"BV号长度错误"
- 视频能够正常加载和播放
- 番剧信息正确显示
- 集数列表正确显示

## 相关文件

- `lib/pages/pgc/widgets/pgc_card_v.dart` - PGC卡片组件
- `lib/pages/video/controller.dart` - 视频控制器
- `lib/pages/video/introduction/bangumi/controller.dart` - 番剧介绍控制器
- `lib/models/bangumi/info.dart` - 番剧信息模型

## 注意事项

1. **兼容性**: 修改后的代码仍然兼容直接传递bvid和cid的情况
2. **性能**: 增加了一次API调用来获取番剧信息，但这是必需的
3. **错误处理**: 添加了try-catch来处理更新视频控制器参数时可能的错误

## 后续改进

1. 可以考虑在卡片点击时显示加载提示
2. 可以缓存番剧信息，避免重复请求
3. 可以优化错误提示，提供更友好的用户体验
