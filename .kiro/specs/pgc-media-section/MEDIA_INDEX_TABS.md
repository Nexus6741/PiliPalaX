# 影视索引Tab切换功能

## 功能说明

影视索引页面现在支持通过Tab切换不同类型的内容，包括：
- 全部
- 电影
- 电视剧
- 纪录片
- 综艺

## 实现方式

### 1. Tab配置

```dart
final List<Map<String, dynamic>> _mediaTabs = [
  {'label': '全部', 'type': null},
  {'label': '电影', 'type': 2},
  {'label': '电视剧', 'type': 5},
  {'label': '纪录片', 'type': 3},
  {'label': '综艺', 'type': 7},
];
```

### 2. TabController初始化

```dart
// 只在影视索引时初始化TabController
if (indexType != null) {
  _tabController = TabController(length: _mediaTabs.length, vsync: this);
  _tabController!.addListener(() {
    if (!_tabController!.indexIsChanging) {
      // Tab切换时更新indexType并重新加载
      final newType = _mediaTabs[_tabController!.index]['type'];
      _controller.indexType = newType;
      _controller.page = 1;
      _controller.getPgcIndexCondition();
      _controller.queryData();
    }
  });
}
```

### 3. UI集成

```dart
appBar: AppBar(
  title: Text(title),
  elevation: 0,
  bottom: indexType != null && _tabController != null
      ? TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _mediaTabs.map((tab) => Tab(text: tab['label'])).toList(),
          indicatorSize: TabBarIndicatorSize.label,
        )
      : null,
),
```

## 工作流程

### 用户操作流程

```
用户进入影视索引
  ↓
看到Tab栏（全部、电影、电视剧、纪录片、综艺）
  ↓
点击某个Tab（如"电影"）
  ↓
系统更新indexType=2
  ↓
重新获取筛选条件
  ↓
重新加载内容列表
  ↓
显示电影相关的筛选条件和内容
```

### 技术流程

```
Tab切换事件
  ↓
TabController.listener触发
  ↓
获取新的indexType
  ↓
更新Controller.indexType
  ↓
重置页码为1
  ↓
调用getPgcIndexCondition()获取新的筛选条件
  ↓
调用queryData()加载新的内容
  ↓
UI自动更新
```

## 番剧索引 vs 影视索引

### 番剧索引
- **特征**: `indexType = null`
- **Tab栏**: 无（不显示Tab）
- **内容**: 只显示番剧

### 影视索引
- **特征**: `indexType != null`
- **Tab栏**: 有（显示5个Tab）
- **内容**: 根据选中的Tab显示对应类型

## API参数

### 全部影视
```dart
PgcHttp.pgcIndexCondition(
  seasonType: 1,
  type: 1,
  indexType: null,  // 全部
)
```

### 电影
```dart
PgcHttp.pgcIndexCondition(
  seasonType: 1,
  type: 1,
  indexType: 2,  // 电影
)
```

### 电视剧
```dart
PgcHttp.pgcIndexCondition(
  seasonType: 1,
  type: 1,
  indexType: 5,  // 电视剧
)
```

### 纪录片
```dart
PgcHttp.pgcIndexCondition(
  seasonType: 1,
  type: 1,
  indexType: 3,  // 纪录片
)
```

### 综艺
```dart
PgcHttp.pgcIndexCondition(
  seasonType: 1,
  type: 1,
  indexType: 7,  // 综艺
)
```

## 特性

1. **独立筛选条件**: 每个Tab有自己的筛选条件
2. **状态保持**: 切换Tab时会重新加载筛选条件和内容
3. **滚动Tab**: Tab栏支持横向滚动（isScrollable: true）
4. **指示器**: 使用label大小的指示器（indicatorSize: TabBarIndicatorSize.label）

## 测试清单

- [ ] 进入影视索引，Tab栏正确显示
- [ ] 默认选中"全部"Tab
- [ ] 点击"电影"Tab，内容切换为电影
- [ ] 点击"电视剧"Tab，内容切换为电视剧
- [ ] 点击"纪录片"Tab，内容切换为纪录片
- [ ] 点击"综艺"Tab，内容切换为综艺
- [ ] 每个Tab的筛选条件正确加载
- [ ] 筛选功能在每个Tab下都正常工作
- [ ] 番剧索引不显示Tab栏

## 注意事项

1. **性能**: 切换Tab时会重新加载数据，确保加载速度
2. **状态管理**: 每次切换Tab都会重置页码和筛选条件
3. **用户体验**: Tab切换应该流畅，无卡顿

## 后续优化

1. **记忆功能**: 记住用户上次选择的Tab
2. **预加载**: 预加载相邻Tab的数据
3. **动画**: 添加Tab切换动画
4. **徽章**: 在Tab上显示内容数量徽章
