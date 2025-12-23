# 历史记录Tab分类功能实现完成

## 功能概述
参考PiliPlus实现，为历史记录页面添加Tab分类功能，包含：
- 全部
- 视频
- 直播
- 专栏

## 实现内容

### 1. 修改API接口 (lib/http/user.dart)
- 为`historyList`方法添加`type`参数，支持按类型筛选历史记录
- 默认值为'all'，可选值：'all', 'archive', 'live', 'article'

### 2. 更新Controller (lib/pages/history/controller.dart)
- 添加`type`参数支持不同Tab的controller实例
- 添加`TabController`和`tabs`列表管理Tab状态
- 添加`GetSingleTickerProviderStateMixin`支持TabController
- 修改`queryHistoryList`方法：
  - 支持按type参数请求不同类型的历史记录
  - 首次加载时解析并初始化tabs数据
  - 创建TabController管理Tab切换
- 添加`onClose`方法释放TabController资源

### 3. 重构View (lib/pages/history/view.dart)
- 添加`type`参数区分主页面和子Tab页面
- 添加`AutomaticKeepAliveClientMixin`保持子Tab状态
- 实现`currCtr()`方法获取当前Tab的controller
- 主页面结构：
  - 使用`PopScope`处理多选模式的返回逻辑
  - 根据tabs是否为空决定显示Tab布局或单页面布局
  - TabBar显示"全部"和动态Tab列表
  - TabBarView包含主页面和各个子Tab页面
- 拆分AppBar为两个方法：
  - `_buildNormalAppBar()`: 正常模式的AppBar
  - `_buildMultiSelectAppBar()`: 多选模式的AppBar
- 提取内容区域为`_buildContent()`方法，供主页面和子Tab复用
- Tab切换逻辑：
  - 切换时滚动到顶部
  - 切换时取消前一个Tab的多选模式
  - 多选模式下禁用Tab滑动切换

### 4. 功能特性
- **Tab分类**: 根据API返回的tab数据动态创建Tab
- **独立状态**: 每个Tab有独立的controller和数据列表
- **状态保持**: 使用KeepAlive保持子Tab的滚动位置和数据
- **多选支持**: 每个Tab独立的多选状态，切换Tab时自动取消多选
- **统一操作**: 暂停/恢复、清空、删除等操作对当前Tab生效
- **性能优化**: 使用tag区分不同controller实例，避免冲突

## 技术要点

### Controller管理
```dart
// 主controller (tag: 'all')
Get.put(HistoryController(type: null), tag: 'all');

// 子Tab controller (tag: 'archive', 'live', 'article')
Get.put(HistoryController(type: 'archive'), tag: 'archive');
```

### Tab数据结构
```dart
class HisTabItem {
  String? type;  // 'archive', 'live', 'article'
  String? name;  // '视频', '直播', '专栏'
}
```

### 状态同步
- 使用`currCtr()`方法获取当前激活Tab的controller
- 所有操作（暂停、清空、删除、多选）都通过`currCtr()`执行
- Tab切换时自动处理多选状态的清理

## UI布局
- TabBar固定在顶部，不可滚动
- Tab标签：全部 | 视频 | 直播 | 专栏
- 每个Tab独立的下拉刷新和上拉加载
- 多选模式下禁用Tab切换手势

## 测试要点
1. ✅ Tab显示是否正确（全部、视频、直播、专栏）
2. ✅ 切换Tab时数据是否正确加载
3. ✅ 每个Tab的滚动位置是否保持
4. ✅ 多选模式在Tab间切换时是否正确处理
5. ✅ 删除、清空等操作是否只影响当前Tab
6. ✅ 下拉刷新和上拉加载是否正常
7. ✅ 返回键在多选模式下是否正确处理

## 参考实现
- PiliPlus/lib/pages/history/view.dart
- PiliPlus/lib/pages/history/controller.dart
- PiliPlus/lib/pages/history/base_controller.dart

## 注意事项
1. 使用tag区分不同的controller实例，避免GetX冲突
2. 子Tab页面需要实现`AutomaticKeepAliveClientMixin`保持状态
3. 主页面的controller tag为'all'，子Tab使用type作为tag
4. dispose时需要清理所有Tab的controller
5. TabController需要在onClose时dispose
