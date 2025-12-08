# 丝滑Tab切换功能

## 功能说明

影视索引页面现在支持通过PageView + TabBar实现丝滑的左右滑动切换，用户可以：
- 点击Tab标签快速切换
- 左右滑动页面丝滑切换
- 两种操作方式完全同步

## 实现方式

### 1. 双控制器架构

```dart
late TabController? _tabController;      // 控制Tab栏
late PageController? _pageController;    // 控制PageView
```

### 2. 同步机制

#### Tab点击同步PageView
```dart
_tabController!.addListener(() {
  if (!_tabController!.indexIsChanging) {
    // Tab点击时同步PageView
    _pageController!.animateToPage(
      _tabController!.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
});
```

#### PageView滑动同步TabBar
```dart
PageView.builder(
  controller: _pageController,
  onPageChanged: (index) {
    _tabController!.animateTo(index);  // 自动更新Tab指示器
  },
  itemCount: _mediaTabs.length,
  itemBuilder: (context, index) {
    return _buildMediaPage(theme, index);
  },
)
```

### 3. 页面切换逻辑

每个PageView页面都会：
1. 检查Controller的indexType是否需要更新
2. 如果需要，更新indexType
3. 重置页码为1
4. 重新获取筛选条件
5. 重新加载内容列表

```dart
Widget _buildMediaPage(ThemeData theme, int index) {
  final mediaType = _mediaTabs[index]['type'];

  // 更新Controller的indexType
  if (_controller.indexType != mediaType) {
    _controller.indexType = mediaType;
    _controller.page = 1;
    _controller.getPgcIndexCondition();
    _controller.queryData();
  }

  return RefreshIndicator(
    onRefresh: _controller.onRefresh,
    child: CustomScrollView(...),
  );
}
```

## 用户体验

### 点击Tab切换
```
用户点击"电影"Tab
  ↓
TabBar指示器移动到"电影"
  ↓
PageView平滑动画到电影页面（300ms）
  ↓
加载电影的筛选条件和内容
```

### 左右滑动切换
```
用户向左滑动页面
  ↓
PageView平滑滑动到下一页
  ↓
TabBar指示器自动更新
  ↓
加载新分类的筛选条件和内容
```

## 动画配置

- **动画时长**: 300ms
- **动画曲线**: Curves.easeInOut（缓入缓出）
- **效果**: 丝滑流畅的过渡

## 分类映射

| Tab标签 | indexType | 说明 |
|--------|----------|------|
| 全部 | null | 全部影视内容 |
| 电影 | 2 | 电影 |
| 电视剧 | 5 | 电视剧 |
| 纪录片 | 3 | 纪录片 |
| 综艺 | 7 | 综艺 |

## 性能优化

1. **延迟加载**: 只在切换到该页面时才加载数据
2. **状态管理**: 每个分类独立管理筛选条件和内容
3. **内存管理**: PageView默认缓存相邻页面

## 测试清单

- [ ] 点击Tab标签能正确切换页面
- [ ] 左右滑动页面能正确切换分类
- [ ] Tab指示器与PageView同步
- [ ] 每个分类的筛选条件正确加载
- [ ] 每个分类的内容正确加载
- [ ] 切换分类时能正确重置页码
- [ ] 动画流畅无卡顿
- [ ] 番剧索引不显示Tab栏和PageView

## 代码结构

```
PgcIndexPage (StatefulWidget)
  ↓
_PgcIndexPageState
  ├── indexType (int?)
  ├── _controller (PgcIndexController)
  ├── _tabController (TabController?)
  ├── _pageController (PageController?)
  ├── _mediaTabs (List<Map>)
  ├── initState()
  ├── dispose()
  ├── build()
  │   ├── 番剧索引: 简单Scaffold
  │   └── 影视索引: Scaffold + TabBar + PageView
  ├── _buildMediaPage()
  ├── _buildFilterWidget()
  ├── _buildSortsWidget()
  ├── _buildSortChip()
  ├── _buildContentList()
  └── _buildListBody()
```

## 注意事项

1. **PageView性能**: 避免在PageView中放置过于复杂的Widget
2. **内存使用**: 多个分类同时加载可能占用较多内存
3. **网络请求**: 切换分类时会发起新的网络请求
4. **用户体验**: 确保动画流畅，避免卡顿

## 后续优化

1. **预加载**: 预加载相邻分类的数据
2. **缓存**: 缓存已加载过的分类数据
3. **指示器**: 自定义Tab指示器样式
4. **动画**: 添加更多动画效果选项
