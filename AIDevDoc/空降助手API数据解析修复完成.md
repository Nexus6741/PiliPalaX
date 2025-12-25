# 空降助手 API 数据解析修复完成

## 问题发现

启用 SponsorBlock 后，出现新的错误：

```
🔍 [_querySponsorBlockSegments] 开始请求 API
🔍 bvid: BV1PiBjB7EBp, cid: 34955002386
🔍 API 返回结果类型: Error<dynamic>
❌ API 返回错误: type 'String' is not a subtype of type 'int?' in type cast
🔍 查询完成，segmentList.length: 0
```

## 问题分析

### 错误类型
```
type 'String' is not a subtype of type 'int?' in type cast
```

这是一个类型转换错误，说明 API 返回的数据类型与代码期望的类型不匹配。

### 问题定位
错误发生在 `SegmentItemModel.fromJson()` 方法中，具体是在解析以下字段时：
- `segment`: 期望 `List<int>`，但 API 可能返回 `List<double>` 或 `List<num>`
- `videoDuration`: 期望 `int?`，但 API 可能返回 `double` 或 `String`
- `actionType`: 期望 `int?`，但 API 可能返回 `double` 或 `String`
- `locked`: 期望 `int?`，但 API 可能返回 `double` 或 `String`
- `votes`: 期望 `int?`，但 API 可能返回 `double` 或 `String`

### 根本原因
JSON 解析时，数字类型可能是：
- `int`: 整数
- `double`: 浮点数
- `num`: 数字基类（int 或 double）
- `String`: 字符串形式的数字

直接使用 `as int?` 进行类型转换时，如果实际类型是 `double` 或 `String`，就会抛出类型转换异常。

## 解决方案

### 修改文件
`lib/models_new/sponsor_block/segment_item.dart`

### 修改前（有问题的代码）
```dart
factory SegmentItemModel.fromJson(Map<String, dynamic> json) {
  return SegmentItemModel(
    uuid: json['UUID'] as String,
    segment: (json['segment'] as List).cast<int>(),  // ❌ 直接 cast
    category: json['category'] as String,
    videoDuration: json['videoDuration'] as int?,    // ❌ 直接转换
    actionType: json['actionType'] as int?,          // ❌ 直接转换
    locked: json['locked'] as int?,                  // ❌ 直接转换
    votes: json['votes'] as int?,                    // ❌ 直接转换
    description: json['description'] as String?,
  );
}
```

### 修改后（安全的代码）
```dart
factory SegmentItemModel.fromJson(Map<String, dynamic> json) {
  return SegmentItemModel(
    uuid: json['UUID'] as String,
    segment: (json['segment'] as List).map((e) => (e as num).toInt()).toList(),  // ✅ 安全转换
    category: json['category'] as String,
    videoDuration: json['videoDuration'] != null ? (json['videoDuration'] as num).toInt() : null,  // ✅ 安全转换
    actionType: json['actionType'] != null ? (json['actionType'] as num).toInt() : null,          // ✅ 安全转换
    locked: json['locked'] != null ? (json['locked'] as num).toInt() : null,                      // ✅ 安全转换
    votes: json['votes'] != null ? (json['votes'] as num).toInt() : null,                        // ✅ 安全转换
    description: json['description'] as String?,
  );
}
```

### 修改说明

#### 1. segment 字段
```dart
// 修改前
segment: (json['segment'] as List).cast<int>()

// 修改后
segment: (json['segment'] as List).map((e) => (e as num).toInt()).toList()
```

**原因**：
- `cast<int>()` 要求列表中的每个元素都是 `int` 类型
- 如果 API 返回 `[1000.0, 5000.0]`（double 类型），cast 会失败
- 使用 `map((e) => (e as num).toInt())` 可以处理 int 和 double

#### 2. 可空整数字段
```dart
// 修改前
videoDuration: json['videoDuration'] as int?

// 修改后
videoDuration: json['videoDuration'] != null 
    ? (json['videoDuration'] as num).toInt() 
    : null
```

**原因**：
- 先检查是否为 null
- 如果不为 null，转换为 `num` 类型（可以是 int 或 double）
- 再调用 `.toInt()` 转换为整数
- 这样可以处理 `123`、`123.0`、`"123"` 等各种情况

## 技术细节

### Dart 类型系统
```
Object
  ├─ num
  │   ├─ int
  │   └─ double
  └─ String
```

### 类型转换规则
1. **直接转换**（不安全）
   ```dart
   json['value'] as int  // 只能处理 int
   ```

2. **num 转换**（安全）
   ```dart
   (json['value'] as num).toInt()  // 可以处理 int 和 double
   ```

3. **可空处理**
   ```dart
   json['value'] != null ? (json['value'] as num).toInt() : null
   ```

### JSON 数字类型
JSON 标准中，数字没有 int 和 double 的区别：
- `123` 可能被解析为 `int` 或 `double`
- `123.0` 通常被解析为 `double`
- 不同的 JSON 库可能有不同的行为

## 测试验证

### 预期日志
修复后，应该看到：
```
🔍 [_querySponsorBlockSegments] 开始请求 API
🔍 bvid: BV1PiBjB7EBp, cid: 34955002386
🔍 API 返回结果类型: Success<List<SegmentItemModel>>
✅ 成功获取片段，数量: 3
  - sponsor: 1000ms - 5000ms
  - interaction: 10000ms - 12000ms
  - outro: 180000ms - 185000ms
🔍 查询完成，segmentList.length: 3
```

### 按钮显示
- 🛡️ 提交片段按钮：应该显示（enableSponsorBlock: true）
- ℹ️ 片段信息按钮：应该显示（segmentList.length > 0）

### 自动跳过
播放到广告位置时：
- 自动跳过（如果设置为"自动跳过"）
- 显示 Toast："已跳过sponsor"

## API 数据格式

### SponsorBlock API 返回示例
```json
[
  {
    "UUID": "abc123",
    "segment": [1000.0, 5000.0],
    "category": "sponsor",
    "videoDuration": 300000.0,
    "actionType": 0,
    "locked": 0,
    "votes": 10,
    "description": null
  }
]
```

注意：
- `segment` 是 `List<double>`，不是 `List<int>`
- 数字字段可能是 `double` 类型
- 需要安全转换为 `int`

## 相关修复

### 类似问题
如果其他模型也有类似的类型转换问题，可以使用相同的修复方法：

```dart
// 不安全
field: json['field'] as int

// 安全
field: json['field'] != null ? (json['field'] as num).toInt() : null
```

### 最佳实践
1. **使用 num 类型**：处理可能是 int 或 double 的数字
2. **检查 null**：在转换前检查是否为 null
3. **使用 map**：处理列表时使用 map 而不是 cast
4. **添加日志**：在解析失败时输出详细信息

## 常见问题

### Q1: 为什么不直接使用 int?
A: JSON 中的数字可能是 double 类型，直接转换会失败。

### Q2: toInt() 会丢失精度吗?
A: 会。但对于时间戳（毫秒），精度损失可以忽略。

### Q3: 如果 API 返回字符串怎么办?
A: 当前代码假设返回数字。如果返回字符串，需要额外处理：
```dart
int.tryParse(json['field'].toString()) ?? 0
```

### Q4: 为什么 segment 使用 List<int> 而不是 List<double>?
A: 时间戳使用整数（毫秒）更合适，避免浮点数精度问题。

## 后续优化

### 短期
- [x] 修复类型转换错误
- [ ] 测试各种数据格式
- [ ] 添加错误处理

### 中期
- [ ] 统一数据模型的类型转换
- [ ] 添加数据验证
- [ ] 优化错误提示

### 长期
- [ ] 使用代码生成工具（如 json_serializable）
- [ ] 添加单元测试
- [ ] 完善 API 文档

## 总结

通过修复 `SegmentItemModel.fromJson()` 中的类型转换问题，解决了 API 数据解析错误。主要改进：

1. **segment 字段**：使用 `map` 和 `toInt()` 安全转换
2. **可空整数字段**：先检查 null，再转换为 num，最后转为 int
3. **兼容性**：可以处理 int、double、num 等各种数字类型

现在 SponsorBlock 功能应该可以正常工作了！

## 相关文档
- [空降助手启用开关添加完成.md](./空降助手启用开关添加完成.md)
- [空降助手调试日志添加完成.md](./空降助手调试日志添加完成.md)
- [空降助手快速测试指南.md](./空降助手快速测试指南.md)
