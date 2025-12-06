# 历史记录定位修复与自动跳转功能

## 问题描述
观看选集视频时，从历史记录进入或在视频页面内切换选集时，不会正确定位到对应的那集和播放进度。例如：
- 用户上次看到第14集的11分钟
- 再次打开时应该定位到第14集的11分钟位置
- 但实际却总是定位到第1集

另外，从搜索等其他入口进入视频时，没有提示用户上次观看的位置。

## 问题原因
1. 在切换选集时，`changeSeasonOrbangu`方法没有清空当前的播放位置（`defaultST`）
2. `queryVideoUrl`方法在获取新选集的视频流时，直接覆盖了`defaultST`，没有考虑是否需要保留之前的值
3. 这导致切换选集后，播放位置可能使用了错误的值

## 修复方案

### 1. 修改 `lib/pages/video/controller.dart`
**改变defaultST的类型定义：**
```dart
// 修改前
late Duration defaultST;

// 修改后
Duration? defaultST;
```

**在queryVideoUrl方法中添加判断逻辑：**
- FLV/MP4格式处理：只有当`defaultST`为null时才设置播放位置
- DASH格式处理：只有当`defaultST`为null时才使用API返回的`last_play_time`

### 2. 修改 `lib/pages/video/introduction/detail/controller.dart`
在`changeSeasonOrbangu`方法中：
- 添加暂停当前播放的逻辑
- 在切换选集时将`defaultST`设置为null，让系统使用新选集的历史记录

### 3. 修改 `lib/pages/video/introduction/bangumi/controller.dart`
同样的修改应用到番剧控制器

## 修复效果
- ✅ 从历史记录进入时，正确定位到上次观看的选集和播放位置
- ✅ 在视频页面内切换选集时，使用新选集的历史播放位置
- ✅ 如果新选集没有观看记录，从头开始播放
- ✅ 支持多种视频格式（DASH、FLV/MP4）
- ✅ **新增**：从其他入口（搜索、推荐等）进入视频时，显示"上次看到第X集，点击跳转"的提示

## 新增功能：自动跳转到上次观看位置

### 功能说明
- 当用户从非历史记录入口（如搜索、推荐）进入多P视频时
- 如果上次观看的分P与当前分P不同
- **自动跳转**到上次观看的分P
- 显示Toast提示："已自动跳转到上次观看的第X P"

### 实现细节
1. **数据来源**：
   - 先调用`videoUrl` API获取视频流
   - 再调用`playInfo` API（`/x/player/wbi/v2`）获取准确的`last_play_cid`
   - `videoUrl` API返回的`last_play_cid`经常是0，不准确
   - `playInfo` API返回的数据更可靠

2. **自动跳转逻辑**：
   - 延迟500ms等待VideoIntroController初始化
   - 检查是否满足条件（多P视频、有历史记录、cid不同）
   - 自动调用`changeSeasonOrbangu`切换到上次观看的分P
   - 显示Toast提示用户

3. **容错机制**：
   - 如果第一次检查失败（控制器未初始化），会在1秒后重试
   - 确保在各种情况下都能正常工作

### 相关文件
- `lib/http/video.dart`：添加了`playInfo` API方法
- `lib/pages/video/controller.dart`：添加了自动跳转逻辑

## 工作流程
1. **初始进入视频**：`defaultST`为null → 使用API返回的`last_play_time`
2. **获取历史记录**：调用`playInfo` API获取准确的`last_play_cid`
3. **检查并跳转**：如果`last_play_cid`不等于当前cid → 自动跳转到对应分P
4. **切换选集**：设置`defaultST = null` → 调用`queryVideoUrl()` → 使用新选集的`last_play_time`
5. **播放中切换画质**：保留当前`defaultST` → 使用当前播放位置

## 测试建议

### 基础功能测试
1. 观看一个多集视频（如合集或番剧）的第14集，播放到11分钟后退出
2. 从历史记录重新进入该视频
3. 验证是否正确定位到第14集的11分钟位置
4. 在视频页面内切换到其他集，验证是否使用该集的历史播放位置
5. 在视频页面内切换画质，验证播放位置是否保持不变

### 自动跳转测试
1. 观看一个多P视频的第3P，播放一段时间后退出
2. 从搜索页面重新搜索并进入该视频（会默认打开第1P）
3. 验证是否自动跳转到第3P
4. 验证是否显示Toast提示："已自动跳转到上次观看的第3P"
5. 验证跳转后是否从上次的播放位置继续播放
