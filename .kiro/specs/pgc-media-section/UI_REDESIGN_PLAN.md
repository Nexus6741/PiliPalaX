# 影视索引UI改造计划

## 目标

将当前的影视索引页面UI改造为类似PiliPlus的样式，包括：
1. 添加多维度筛选功能
2. 改进卡片布局和样式
3. 优化交互体验

## 当前实现 vs PiliPlus实现

### 当前实现（PiliPalaX）
- **API**: `/pgc/season/index/result` - 直接获取结果
- **筛选**: 无筛选功能
- **布局**: 简单的网格布局
- **卡片**: 基础的PgcCardV组件

### PiliPlus实现
- **API**: 
  - `/pgc/season/index/condition` - 获取筛选条件
  - `/pgc/season/index/result` - 获取筛选结果
- **筛选**: 
  - 排序（最多播放、最近更新、最新上线）
  - 全部风格（剧情、情感、励志、家庭、青春、动作等）
  - 付费类型（免费、付费、大会员）
  - 支持展开/收起
- **布局**: SliverGrid with 自定义delegate
- **卡片**: 优化的卡片样式，显示更多信息

## 改造步骤

### 1. 数据模型层

#### 1.1 创建筛选条件模型
**文件**: `lib/models/pgc/pgc_index_condition/`

需要创建以下模型：
- `data.dart` - 筛选条件数据容器
- `sort.dart` - 排序选项和筛选项
- `value.dart` - 筛选值

参考PiliPlus的模型结构：
```dart
class PgcIndexConditionData {
  List<PgcConditionOrder>? order;  // 排序选项
  List<PgcConditionFilter>? filter; // 筛选项
}

class PgcConditionOrder {
  String? name;   // 显示名称
  String? field;  // 字段名
}

class PgcConditionFilter {
  String? name;   // 筛选项名称
  String? field;  // 字段名
  List<PgcConditionValue>? values; // 可选值
}

class PgcConditionValue {
  String? name;    // 显示名称
  String? keyword; // 值
}
```

### 2. HTTP层

#### 2.1 添加获取筛选条件API
**文件**: `lib/http/pgc.dart`

添加方法：
```dart
static Future pgcIndexCondition({
  int? seasonType,
  int? type,
  int? indexType,
}) async {
  var res = await Request().get(
    Api.pgcIndexCondition,
    data: {
      'season_type': seasonType,
      'type': type,
      'index_type': indexType,
    },
  );
  if (res.data['code'] == 0) {
    return {
      'status': true,
      'data': PgcIndexConditionData.fromJson(res.data['data']),
    };
  } else {
    return {
      'status': false,
      'msg': res.data['message'],
    };
  }
}
```

#### 2.2 更新API端点定义
**文件**: `lib/http/api.dart`

添加：
```dart
static const String pgcIndexCondition = '/pgc/season/index/condition';
```

### 3. Controller层

#### 3.1 更新PgcIndexController
**文件**: `lib/pages/pgc_index/controller.dart`

添加功能：
1. 筛选条件状态管理
2. 筛选参数管理
3. 展开/收起状态
4. 筛选条件变更时重新加载

```dart
class PgcIndexController extends GetxController {
  // 筛选条件状态
  final Rx<bool> conditionLoading = true.obs;
  final Rx<PgcIndexConditionData?> conditionData = Rx(null);
  
  // 筛选参数
  final RxMap<String, dynamic> indexParams = <String, dynamic>{}.obs;
  
  // 展开/收起状态
  final RxBool isExpand = false.obs;
  
  // 获取筛选条件
  Future<void> getPgcIndexCondition() async {
    // 调用API
    // 初始化默认筛选参数
    // 加载数据
  }
  
  // 更新筛选参数并重新加载
  void updateFilter(String key, dynamic value) {
    indexParams[key] = value;
    onRefresh(); // 重新加载数据
  }
}
```

### 4. UI层

#### 4.1 创建筛选组件
**文件**: `lib/pages/pgc_index/widgets/filter_chip.dart`

创建类似SearchText的芯片组件：
```dart
class FilterChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  
  // 样式：选中时使用secondaryContainer背景色
}
```

#### 4.2 更新PgcIndexPage
**文件**: `lib/pages/pgc_index/view.dart`

主要改动：
1. 添加筛选条件区域（使用CustomScrollView + SliverToBoxAdapter）
2. 实现展开/收起动画（AnimatedSize）
3. 使用SelfSizedHorizontalList显示筛选项
4. 更新网格布局参数

布局结构：
```
CustomScrollView
├── SliverToBoxAdapter (筛选条件区域)
│   ├── 排序行（最多播放、最近更新等）
│   ├── 风格行（剧情、情感等）
│   ├── 付费类型行（免费、付费等）
│   └── 展开/收起按钮
└── SliverPadding
    └── SliverGrid (卡片列表)
```

#### 4.3 优化卡片样式
**文件**: `lib/pages/pgc/widgets/pgc_card_v.dart`

改进：
1. 调整卡片比例为0.75
2. 优化标签显示位置
3. 添加更多信息展示（如评分、集数）

### 5. 样式优化

#### 5.1 筛选区域样式
- 使用芯片式按钮（圆角、padding）
- 选中状态：secondaryContainer背景 + onSecondaryContainer文字
- 未选中状态：透明背景 + onSurfaceVariant文字
- 行间距：10px
- 芯片间距：12px

#### 5.2 卡片样式
- 宽高比：0.75
- 圆角：中等圆角（mdRadius）
- 标签位置：
  - 右上角：出品标签（出品、独家等）
  - 左下角：状态标签（连载中、已完结）
- 底部信息：标题 + 副标题（评分/集数）

## 实施顺序

1. ✅ 创建数据模型（pgc_index_condition相关）
2. ✅ 添加HTTP API方法
3. ✅ 更新Controller添加筛选功能
4. ✅ 创建筛选UI组件
5. ✅ 更新页面布局
6. ✅ 优化卡片样式
7. ✅ 测试和调试

## 注意事项

1. **兼容性**: 保持与现有代码的兼容性
2. **性能**: 筛选条件变更时避免不必要的重新构建
3. **用户体验**: 
   - 筛选条件加载时显示loading
   - 筛选变更时平滑过渡
   - 展开/收起动画流畅
4. **响应式**: 适配不同屏幕尺寸

## 测试计划

1. 筛选功能测试
   - 单个筛选项切换
   - 多个筛选项组合
   - 展开/收起功能
2. 数据加载测试
   - 初始加载
   - 筛选后加载
   - 分页加载
3. UI测试
   - 不同屏幕尺寸
   - 深色/浅色主题
   - 动画流畅度
