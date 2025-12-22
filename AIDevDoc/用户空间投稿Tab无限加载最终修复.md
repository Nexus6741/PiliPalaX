# 用户空间投稿Tab无限加载最终修复

## 问题描述

投稿Tab的视频会无限加载，当所有视频加载完毕后又会从头开始重复加载。

### 特别情况

1. **没有多个合集的用户**：修复后可以正常停止加载
2. **有多个合集的用户**：仍然会继续加载多次
3. **第一个Tab（视频）**：应该加载所有视频，但实际加载的是第一个合集的视频，且会无限加载
4. **第一个合集Tab**：也会无限加载
5. **其他合集Tab**：没有无限加载问题

## 根本原因

通过对比 PiliPlus 的实现，发现了以下关键问题：

1. **分页逻辑错误**：
   - 原代码使用 `pn` 从 1 开始计数
   - PiliPlus 使用 `page` 从 0 开始计数
   - 这导致分页判断逻辑出现问题

2. **结束条件判断错误**：
   - 原代码使用 `hasMore` 标志，但判断逻辑不完整
   - PiliPlus 使用 `isEnd` 标志，并在特定条件下才更新
   - 关键：只在 `page == 0` 或非 `onLoad` 时才检查是否到达末尾

3. **has_next 字段判断时机错误**：
   - 原代码在每次加载后都检查 `has_next`
   - PiliPlus 只在初始加载或刷新时检查
   - 这是防止无限加载的关键

## 解决方案

### 1. 修改分页变量

```dart
// 原代码
int pn = 1;
bool hasMore = true;

// 修复后
int page = 0; // 从0开始
bool isEnd = false; // 是否已经到达末尾
int? next; // 用于某些类型的分页
```

### 2. 修改结束条件判断逻辑

```dart
// 检查是否还有更多数据 - 完全按照PiliPlus的逻辑
if (page == 0 || loadType != 'onLoad') {
  // 对于video类型，检查has_next字段
  // 对于其他类型，检查next字段
  if ((type == 'video'
          ? data['has_next'] == false
          : data['next'] == 0) ||
      data['item'] == null ||
      (data['item'] as List).isEmpty) {
    isEnd = true;
    print('Reached the end: has_next=${data['has_next']}, next=${data['next']}, item empty=${data['item'] == null || (data['item'] as List).isEmpty}');
  }
}
```

**关键点**：
- 只在 `page == 0`（初始加载）或 `loadType != 'onLoad'`（刷新）时才更新 `isEnd`
- 这样可以避免在分页加载时错误地重置 `isEnd` 标志
- 对于 video 类型，使用 `has_next` 字段判断
- 对于其他类型（season、series），使用 `next` 字段判断

### 3. 修改数据合并逻辑

```dart
// 如果page != 0且已有数据，需要合并
if (page != 0 && archivesList.isNotEmpty) {
  // 向下加载，添加到末尾
  archivesList.addAll(newList);
} else {
  // 初始加载或刷新
  archivesList.value = newList;
}
```

### 4. 修改初始化逻辑

```dart
if (loadType == 'init' || loadType == 'refresh') {
  page = 0;
  firstAid = null;
  lastAid = null;
  next = null;
  isEnd = false;
}
```

### 5. 修改排序切换逻辑

```dart
toggleSort() async {
  // ...
  // 切换排序时重置状态
  isEnd = false;
  firstAid = null;
  lastAid = null;
  next = null;
  getMemberArchive('init');
}
```

## 修改的文件

- `lib/pages/member_archive/controller.dart`

## 测试验证

### 测试场景

1. **没有合集的用户**：
   - 滑到底部，应该停止加载
   - 不应该重复加载已有的视频

2. **有多个合集的用户**：
   - 第一个Tab（视频）：应该加载所有视频，不应该无限加载
   - 第一个合集Tab：应该只加载该合集的视频，不应该无限加载
   - 其他合集Tab：应该正常加载，不应该无限加载

3. **切换排序**：
   - 切换排序后应该重新加载
   - 不应该出现重复数据

4. **下拉刷新**：
   - 刷新后应该清空列表并重新加载
   - 不应该出现重复数据

## 关键学习点

1. **分页逻辑的重要性**：
   - 从 0 还是从 1 开始计数会影响整个分页逻辑
   - 需要与 API 的行为保持一致

2. **结束条件的判断时机**：
   - 不是每次加载后都要检查是否到达末尾
   - 只在特定条件下（初始加载、刷新）才更新结束标志
   - 这样可以避免在分页加载时错误地重置状态

3. **完全参考成熟项目的实现**：
   - PiliPlus 的实现经过充分测试
   - 直接复制其逻辑可以避免很多坑
   - 不要自己"优化"或"改进"，先保证功能正确

## 日期

2024-12-22
