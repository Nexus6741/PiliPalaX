# 索引功能集成完成

## 概述

已将索引功能分别集成到番剧区和影视区，支持不同类型的内容索引。

## 实现方案

### 1. 通用索引页面

**文件**: `lib/pages/pgc_index/view.dart`

**特性**:
- 支持通过 `indexType` 参数区分不同类型
- 支持从 `widget.indexType` 或 `Get.arguments` 获取参数
- 根据 `indexType` 显示不同的标题

**参数说明**:
- `indexType = null`: 番剧索引（seasonType=1）
- `indexType = 102`: 影视索引（全部影视内容）
- `indexType = 2`: 电影索引
- `indexType = 5`: 电视剧索引
- `indexType = 3`: 纪录片索引
- `indexType = 7`: 综艺索引

### 2. 番剧区集成

**文件**: `lib/pages/bangumi/view.dart`

**改动**:
```dart
// 在"推荐"标题旁添加"索引"按钮
TextButton.icon(
  onPressed: () {
    Get.toNamed('/pgcIndex');  // 不传参数，默认为番剧索引
  },
  icon: const Icon(Icons.grid_view, size: 18),
  label: const Text('索引'),
)
```

**位置**: "推荐"标题的右侧

### 3. 影视区集成

**文件**: `lib/pages/pgc/view.dart`

**改动**:
```dart
// 将"更多"按钮改为"索引"按钮
TextButton.icon(
  onPressed: () {
    Get.toNamed('/pgcIndex', arguments: {'indexType': 102});
  },
  icon: const Icon(Icons.grid_view, size: 18),
  label: const Text('索引'),
)
```

**位置**: "推荐"标题的右侧

## 用户流程

### 番剧索引

```
用户进入番剧区
  ↓
点击"索引"按钮
  ↓
进入番剧索引页面
  ↓
查看/筛选番剧内容
```

### 影视索引

```
用户进入影视区
  ↓
点击"索引"按钮
  ↓
进入影视索引页面（全部影视内容）
  ↓
查看/筛选电影、电视剧、纪录片、综艺等
```

## 筛选功能

两个索引页面都支持：
- 排序（最多播放、最近更新、最新上线）
- 风格筛选（剧情、情感、励志等）
- 地区筛选
- 付费类型筛选
- 其他维度筛选

## API调用

### 番剧索引
```dart
PgcHttp.pgcIndexCondition(
  seasonType: 1,  // 番剧
  type: 1,
  indexType: null,
)
```

### 影视索引
```dart
PgcHttp.pgcIndexCondition(
  seasonType: 1,
  type: 1,
  indexType: 102,  // 全部影视
)
```

## 测试清单

### 番剧索引
- [ ] 从番剧区点击"索引"按钮
- [ ] 页面标题显示"番剧索引"
- [ ] 筛选条件正确加载
- [ ] 内容列表显示番剧
- [ ] 筛选功能正常工作

### 影视索引
- [ ] 从影视区点击"索引"按钮
- [ ] 页面标题显示"影视索引"
- [ ] 筛选条件正确加载
- [ ] 内容列表显示影视内容
- [ ] 筛选功能正常工作

## 后续优化

1. **分类标签**:
   - 在影视索引页面顶部添加分类标签（全部、电影、电视剧、纪录片、综艺）
   - 点击标签切换不同类型的内容

2. **记忆功能**:
   - 记住用户上次选择的筛选条件
   - 下次进入时自动应用

3. **快捷筛选**:
   - 添加常用筛选组合的快捷按钮
   - 如"最新上线"、"高分推荐"等

## 相关文件

- `lib/pages/pgc_index/view.dart` - 索引页面
- `lib/pages/pgc_index/controller.dart` - 索引控制器
- `lib/pages/bangumi/view.dart` - 番剧页面
- `lib/pages/pgc/view.dart` - 影视页面
- `lib/http/pgc.dart` - PGC HTTP请求
