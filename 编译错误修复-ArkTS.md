# ArkTS 编译错误修复

## 错误信息

```
hvigor ERROR: ArkTS Compiler Error
Error Message: "throw" statements cannot accept values of arbitrary types (arkts-limited-throw)
At File: C:/PiliPalaX/packages/wakelock_ohos/ohos/src/main/ets/components/plugin/WakelockOhosPlugin.ets:96:7
```

## 问题原因

ArkTS（鸿蒙的 TypeScript 变体）有更严格的类型限制，不允许直接 throw 任意类型的对象。

### 错误代码

```typescript
catch (err) {
  const error = err as BusinessError;
  console.error(TAG, `Failed: ${error.message}`);
  throw error;  // ❌ 不允许 throw BusinessError 类型
}
```

### 正确代码

```typescript
catch (err) {
  const error = err as BusinessError;
  console.error(TAG, `Failed: ${error.message}`);
  throw new Error(`Failed: ${error.message}`);  // ✅ 只能 throw Error 类型
}
```

## 修复内容

修改了 `WakelockOhosPlugin.ets` 中的 `setKeepScreenOn` 方法：

```typescript
private async setKeepScreenOn(isKeepScreenOn: boolean): Promise<void> {
  try {
    const windowClass = await window.getLastWindow(getContext(this));
    await windowClass.setWindowKeepScreenOn(isKeepScreenOn);
  } catch (err) {
    const error = err as BusinessError;
    console.error(TAG, `Failed to set window keep screen on. Code: ${error.code}, Message: ${error.message}`);
    // 改为抛出标准 Error 对象
    throw new Error(`Failed to set window keep screen on: ${error.message}`);
  }
}
```

## ArkTS 限制说明

ArkTS 相比标准 TypeScript 有以下限制：

1. **throw 语句限制**
   - 只能 throw `Error` 类型或其子类
   - 不能 throw 任意对象

2. **类型转换限制**
   - 需要显式类型转换
   - 不支持某些隐式转换

3. **语法限制**
   - 不支持某些 ES6+ 特性
   - 有特定的编码规范

## 重新编译

修复后重新编译：

```bash
flutter clean
flutter pub get
# 重新编译鸿蒙应用
```

## 验证

编译成功后，应该看到：

```
COMPILE RESULT: SUCCESS
```

## 相关文档

- [ArkTS 语法规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-get-started-V5)
- [ArkTS 与 TypeScript 的差异](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-more-cases-V5)

## 更新日期

2025-12-17
