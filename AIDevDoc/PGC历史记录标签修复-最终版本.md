# PGC历史记录标签修复 - 最终版本

## 问题

所有PGC内容（番剧、电影、电视剧、综艺、纪录片、国创）在历史记录中都显示为"番剧"标签。

## 根本原因

通过调试日志发现：
- `playerInit` 在 `queryBangumiIntro` **之前**执行
- 此时 `bangumiDetail.value.type` 还是 `null`（未初始化）
- 导致 `seasonType` 为 `null`，使用默认值 `1`（番剧）

## 解决方案

在 `playerInit` 时，优先从 `bangumiDetail.value.type` 获取，如果为 `null` 则从传入的 `bangumiItem.type` 获取：

```dart
// lib/pages/video/controller.dart
seasonType = bangumiCtr.bangumiDetail.value.type;
if (seasonType == null && bangumiCtr.bangumiItem != null) {
  seasonType = bangumiCtr.bangumiItem!.type;
}
```

## 修改的文件

1. `lib/plugin/pl_player/controller.dart` - 添加 `_seasonType` 字段
2. `lib/http/video.dart` - 使用 `seasonType` 作为 `sub_type`
3. `lib/pages/video/controller.dart` - 从 `bangumiItem` 获取备用值
4. `lib/pages/video/introduction/bangumi/controller.dart` - 添加调试日志

## 测试

重新编译运行，观看一部电影，查看日志应该显示：

```
🔍 [playerInit] 获取PGC参数:
   - seasonType: 2
   - bangumiItem?.type: 2
```

然后在历史记录中应该显示"电影"标签。

## 完成时间

2025-12-23
