# 表情后输入文本被错误插入的修复

## 问题描述

用户在表情后输入文本时，文本被错误地插入到表情的原始文本中：
- 输入：`[happy]你好` 
- 显示错误：`[你好happy]`

而在表情前输入文本则正常。

## 根本原因分析

问题出现在两个地方：

### 1. `buildTextSpan()` 中的占位符检查不够严格
原始代码直接使用 `_emoteMap[char]` 来检查字符是否是占位符，但这可能在某些情况下失败。

### 2. `value` setter 中的递归处理
当用户输入文本时，`value` setter 被调用，可能在不适当的时机删除或修改占位符映射。

## 修复方案

### 修复 1：添加递归防护标记
```dart
/// 标记是否正在更新值（防止递归）
bool _isUpdatingValue = false;
```

在 `insertEmote()` 中设置标记，防止 `value` setter 在插入表情时进行不必要的处理。

### 修复 2：改进占位符检查
```dart
/// 获取所有占位符集合
Set<String> get _placeholders => _emoteMap.keys.toSet();
```

在 `buildTextSpan()` 中使用更严格的检查：
```dart
// 检查当前字符是否是占位符
if (_placeholders.contains(char)) {
  final emoteInfo = _emoteMap[char];
  // ... 处理表情
}
```

这样可以确保只有真正的占位符才会被识别为表情。

### 修复 3：改进 `value` setter
```dart
@override
set value(TextEditingValue newValue) {
  // 如果正在更新值，直接调用父类方法
  if (_isUpdatingValue) {
    super.value = newValue;
    return;
  }
  
  // 检查是否有表情被删除
  final newText = newValue.text;
  
  // 找出被删除的占位符
  final toRemove = <String>[];
  for (var placeholder in _emoteMap.keys) {
    if (!newText.contains(placeholder)) {
      toRemove.add(placeholder);
    }
  }
  
  // 移除被删除的表情
  for (var placeholder in toRemove) {
    _emoteMap.remove(placeholder);
  }
  
  super.value = newValue;
}
```

## 测试场景

### 场景 1：表情前输入文本
1. 输入：`你好`
2. 插入表情：`[happy]`
3. 预期结果：`你好[happy]`
4. 发送时应该是：`你好[happy]`

### 场景 2：表情后输入文本
1. 插入表情：`[happy]`
2. 输入：`你好`
3. 预期结果：`[happy]你好`
4. 发送时应该是：`[happy]你好`

### 场景 3：多个表情和文本混合
1. 输入：`早上`
2. 插入表情：`[happy]`
3. 输入：`中午`
4. 插入表情：`[sad]`
5. 输入：`晚上`
6. 预期结果：`早上[happy]中午[sad]晚上`
7. 发送时应该是：`早上[happy]中午[sad]晚上`

### 场景 4：删除表情
1. 输入：`[happy]你好`
2. 删除表情
3. 预期结果：`你好`
4. 发送时应该是：`你好`

## 关键改进

1. **递归防护**：使用 `_isUpdatingValue` 标记防止在插入表情时进行不必要的处理
2. **严格的占位符检查**：使用 `_placeholders.contains(char)` 确保只识别真正的占位符
3. **正确的文本顺序**：确保占位符和文本的相对位置不会改变

## 文件修改

- `lib/common/widgets/rich_text/controller.dart`
  - 添加 `_isUpdatingValue` 标记
  - 添加 `_placeholders` getter
  - 改进 `buildTextSpan()` 中的占位符检查
  - 改进 `value` setter 的递归防护

## 验证方法

1. 在输入框中输入表情和文本的各种组合
2. 检查输入框中的显示是否正确
3. 发送评论，检查服务器收到的文本是否正确
4. 验证表情是否正确显示为图片
