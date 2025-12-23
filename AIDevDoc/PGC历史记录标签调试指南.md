# PGC历史记录标签调试指南

## 问题现象

所有PGC内容（番剧、电影、电视剧、综艺、纪录片、国创）在历史记录中都显示为"番剧"标签。

## 调试步骤

### 1. 清理旧的历史记录

为了测试修复效果，建议先清理旧的历史记录，或者观看新的PGC内容。

### 2. 观看一部电影

选择一部电影（如《浪客剑心 最终章 人诛篇》），播放几秒钟。

### 3. 查看控制台日志

在播放过程中，控制台应该输出以下日志：

#### 日志1：番剧详情获取
```
🔍 [queryBangumiIntro] 番剧详情获取成功:
   - seasonId: xxxxx
   - title: 浪客剑心 最终章 人诛篇
   - type: 2
   - 类型说明: 1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺
```

**检查点**：
- `type` 字段应该是 `2`（电影）
- 如果是 `null`，说明 B站 API 没有返回 `type` 字段

#### 日志2：播放器初始化
```
🔍 [playerInit] 获取PGC参数:
   - videoType: SearchType.media_bangumi
   - epid: xxxxx
   - seasonId: xxxxx
   - seasonType: 2
   - bangumiDetail.value: Instance of 'BangumiInfoModel'
   - bangumiDetail.value.type: 2
   - 类型说明: 1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺
```

**检查点**：
- `seasonType` 应该是 `2`
- 如果显示 `(null)`，说明从 `bangumiDetail.value.type` 获取失败

#### 日志3：保存PGC参数
```
🔍 [setDataSource] 保存PGC参数:
   - _epid: xxxxx
   - _seasonId: xxxxx
   - _seasonType: 2
```

**检查点**：
- `_seasonType` 应该是 `2`
- 如果显示 `(null)`，说明参数传递失败

#### 日志4：历史记录上报
```
🔍 [heartBeat] PGC内容历史记录上报:
   - bvid: BVxxxxxxxxx
   - cid: xxxxx
   - epid: xxxxx
   - seasonId: xxxxx
   - seasonType: 2
   - sub_type将设置为: 2
   - 类型说明: 1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺
```

**检查点**：
- `seasonType` 应该是 `2`
- `sub_type将设置为` 应该是 `2`
- 如果显示 `(null，将使用默认值1)`，说明 `seasonType` 为 `null`

### 4. 检查历史记录

退出播放页面，进入历史记录页面，查看刚才观看的电影：
- 右上角标签应该显示"电影"
- 如果显示"番剧"，说明上报的 `sub_type` 不正确

## 常见问题诊断

### 问题1：`type` 字段为 `null`

**原因**：B站 API 没有返回 `type` 字段，或者字段名不对。

**解决方案**：
1. 检查 B站 API 响应，确认字段名是否为 `type`
2. 可能需要使用其他字段，如 `season_type` 或 `show_season_type`

### 问题2：`seasonType` 获取失败

**原因**：`bangumiDetail.value.type` 为 `null`。

**解决方案**：
1. 确认 `queryBangumiIntro` 方法已经执行完成
2. 确认 `bangumiDetail.value` 不为空
3. 检查 `BangumiInfoModel.fromJson` 是否正确解析了 `type` 字段

### 问题3：参数传递失败

**原因**：在调用链中某个环节参数丢失。

**解决方案**：
1. 检查 `playerInit` 方法中是否正确获取了 `seasonType`
2. 检查 `setDataSource` 方法是否正确接收了 `seasonType` 参数
3. 检查 `makeHeartBeat` 方法是否正确传递了 `_seasonType`

## 测试不同类型的PGC内容

### 电影（type = 2）
- 示例：《浪客剑心 最终章 人诛篇》
- 预期标签：电影

### 电视剧（type = 5）
- 示例：《庆余年》
- 预期标签：电视剧

### 综艺（type = 7）
- 示例：《极限挑战》
- 预期标签：综艺

### 纪录片（type = 3）
- 示例：《人生一串》
- 预期标签：纪录片

### 国创（type = 4）
- 示例：《凡人修仙传》
- 预期标签：国创

### 番剧（type = 1）
- 示例：《进击的巨人》
- 预期标签：番剧

## 日志过滤

如果日志太多，可以使用以下关键词过滤：
- `🔍 [queryBangumiIntro]` - 番剧详情获取
- `🔍 [playerInit]` - 播放器初始化
- `🔍 [setDataSource]` - 保存PGC参数
- `🔍 [heartBeat]` - 历史记录上报

## 下一步

如果通过日志发现了问题，请根据具体情况进行修复：

1. **如果 `type` 字段为 `null`**：检查 B站 API 响应和模型解析
2. **如果 `seasonType` 获取失败**：检查 `bangumiDetail.value.type` 的访问时机
3. **如果参数传递失败**：检查方法调用链中的参数传递

## 完成时间

2025-12-23
