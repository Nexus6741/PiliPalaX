# 用户空间投稿Tab排序功能修复完成（最终版本）

## 问题描述

在用户空间的投稿Tab中，当用户的投稿包含合集时：
1. **选择除"视频"外的合集后，点击排序功能失效**，排序没有变化
2. **视频卡片封面右下角的视频时长移动到了封面的左上角**
3. **"最多收藏"排序结果和"最新发布"一样**

## 问题分析

### 1. 排序功能失效的根本原因
- 当选择特定合集后，`currentSection` 保持选中状态
- 切换排序时重新加载数据，但 `currentSection` 没有被正确处理
- 新数据加载后，`_filterArchivesBySection()` 仍然按旧的section筛选
- 导致看起来排序没有变化

### 2. 视频时长位置错误
- 在 `VideoCardHMember` 组件中，Stack 的 `clipBehavior` 设置不正确
- 导致 Positioned 组件的定位出现问题

### 3. "最多收藏"排序问题
- 参考 PiliPlus 的实现，发现**只有两种排序方式**：
  - `pubdate`：最新发布
  - `click`：最多播放
- **没有 `stow`（最多收藏）这个排序选项**
- B站API可能不支持或返回相同结果

## 修复方案

### 1. 移除"最多收藏"排序选项
**文件**: `lib/pages/member_archive/controller.dart`

参考 PiliPlus，只保留两种排序：

```dart
List<Map<String, String>> orderList = [
  {'type': 'pubdate', 'label': '最新发布'},
  {'type': 'click', 'label': '最多播放'},
];
```

### 2. 修复排序后的section筛选
**文件**: `lib/pages/member_archive/controller.dart`

关键修复：在切换排序后，保存之前选择的section，重新加载数据后重新应用筛选：

```dart
toggleSort() async {
  List<String> typeList = orderList.map((e) => e['type']!).toList();
  int index = typeList.indexOf(currentOrder['type']!);
  if (index == orderList.length - 1) {
    currentOrder.value = orderList.first;
  } else {
    currentOrder.value = orderList[index + 1];
  }

  print('========== toggleSort ==========');
  print('New order: ${currentOrder['type']}');
  print('Current section before reset: ${currentSection.value?.title}');
  print('================================');

  // 切换排序时重置状态
  isEnd = false;
  firstAid = null;
  lastAid = null;
  next = null;
  page = 0;
  // 清空列表
  archivesList.clear();
  allArchivesList.clear();
  // 重置section选择（重要！）
  // 注意：不清空sections列表，因为合集信息不会因排序而改变
  // 但需要在重新加载后重新筛选
  final previousSection = currentSection.value;
  
  // 重新加载数据
  await getMemberArchive('init');
  
  // 如果之前选择了特定的section，重新应用筛选
  if (previousSection != null && previousSection.id != null) {
    // 在新数据中找到对应的section
    final matchingSection = sections.firstWhereOrNull(
      (s) => s.id == previousSection.id,
    );
    if (matchingSection != null) {
      currentSection.value = matchingSection;
      _filterArchivesBySection();
      print('Re-applied section filter: ${matchingSection.title}');
    }
  }
}
```

### 3. 修复视频时长位置
**文件**: `lib/pages/member_archive/widgets/video_card_h_member.dart`

修改 Stack 组件：
- 添加 `clipBehavior: Clip.none` 确保不裁剪子组件
- 简化标识逻辑，直接使用条件判断而不是 Builder

```dart
AspectRatio(
  aspectRatio: StyleString.aspectRatio,
  child: LayoutBuilder(
    builder: (context, constraints) {
      return Stack(
        clipBehavior: Clip.none,  // 关键修复
        children: [
          Hero(
            tag: heroTag,
            child: NetworkImgLayer(
              src: videoItem.cover ?? '',
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          ),
          // 充电视频或合作视频标识（右上角）
          if (videoItem.ugcPay != null && videoItem.ugcPay! > 0)
            Positioned(
              top: 6,
              right: 6,
              child: PBadge(
                text: '充电专属',
                type: 'error',
              ),
            )
          else if (videoItem.isCooperation == true)
            Positioned(
              top: 6,
              right: 6,
              child: PBadge(
                text: '合作',
                type: 'primary',
              ),
            ),
          // 时长（右下角）
          if (videoItem.duration > 0)
            Positioned(
              right: 6,
              bottom: 6,
              child: PBadge(
                text: _formatDuration(videoItem.duration),
                type: 'gray',
              ),
            ),
        ],
      );
    },
  ),
),
```

## 参考实现

参考了 PiliPlus 的实现：
- `PiliPlus/lib/pages/member_video/controller.dart` - 排序逻辑和排序选项
- `PiliPlus/lib/pages/member_video/widgets/video_card_h_member_video.dart` - 视频卡片布局
- `PiliPlus/lib/http/member.dart` - API调用参数

## 核心逻辑说明

### 排序与筛选的关系
1. **排序（order）**：影响API返回的数据顺序
   - `pubdate`：按发布时间排序
   - `click`：按播放量排序

2. **Section筛选**：在客户端对数据进行二次筛选
   - 先从API获取所有数据（存储在 `allArchivesList`）
   - 然后根据选中的section筛选（存储在 `archivesList`）

3. **切换排序时的处理**：
   - 保存当前选中的section
   - 清空数据并重新加载
   - 加载完成后，重新应用section筛选

## 测试验证

### 测试步骤
1. 进入有合集的用户空间投稿Tab
2. 选择一个合集（非"全部"）
3. 点击排序按钮切换排序方式（最新发布 ↔ 最多播放）
4. 验证：
   - 视频列表按新的排序方式重新排列
   - 仍然只显示选中合集的视频
   - 视频时长显示在封面右下角
   - 充电/合作标识显示在封面右上角
5. 切换回"全部"，再次测试排序功能

### 预期结果
- ✅ 排序功能正常工作（只有两种：最新发布、最多播放）
- ✅ 切换合集后排序仍然有效
- ✅ 排序后保持合集筛选状态
- ✅ 视频时长位置正确（右下角）
- ✅ 标识位置正确（右上角）

## 修复日期
2024-12-23
