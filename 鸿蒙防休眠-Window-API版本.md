# 鸿蒙防休眠功能 - Window API 版本

## 更新说明

从 `runningLock` API 切换到 `window.setWindowKeepScreenOn()` API。

### 为什么更换？

1. **runningLock 问题：**
   - 日志显示已成功启用，但实际仍会息屏
   - `PROXIMITY_SCREEN_CONTROL` 类型依赖接近光传感器
   - 可能受系统电源管理策略影响

2. **Window API 优势：**
   - 直接控制窗口的屏幕常亮状态
   - 系统级别的控制，更加可靠
   - 专门为视频播放等场景设计
   - 无需额外权限

## 主要变更

### 1. 原生实现 (WakelockOhosPlugin.ets)

**之前：**
```typescript
import { runningLock } from '@kit.BasicServicesKit';

// 创建 RunningLock
this.lock = await runningLock.create(
  LOCK_NAME,
  runningLock.RunningLockType.PROXIMITY_SCREEN_CONTROL
);
this.lock.hold(timeout);
```

**现在：**
```typescript
import { window } from '@kit.ArkUI';

// 获取窗口并设置常亮
const windowClass = await window.getLastWindow(getContext(this));
await windowClass.setWindowKeepScreenOn(true);
```

### 2. 权限配置

**之前：**
```json5
requestPermissions: [
  { name: "ohos.permission.RUNNING_LOCK" }
]
```

**现在：**
```json5
// 无需额外权限
```

### 3. API 简化

- 移除了 `timeout` 参数（Window API 不需要）
- 简化了状态管理
- 减少了错误处理复杂度

## 部署步骤

### 1. 清理环境
```bash
flutter clean
```

### 2. 获取依赖
```bash
flutter pub get
```

### 3. 重新编译
重新编译鸿蒙应用

### 4. 测试

播放视频，查看日志：

```
WakelockManager: 开始启用防休眠...
WakelockManager: 当前平台 - ohos
WakelockManager: 调用 WakelockOhos.enable()
WakelockOhos: 调用原生 enable 方法，timeout=-1
WakelockOhosPlugin: Enabling screen keep on...
WakelockOhosPlugin: Got window, setting keep screen on to: true
WakelockOhosPlugin: Window keep screen on set to: true
WakelockOhosPlugin: ✅ Screen keep on enabled successfully
WakelockOhos: 原生 enable 返回结果: true
WakelockManager: ✅ 鸿蒙防休眠已启用成功
```

**预期结果：** 屏幕保持常亮，不会自动息屏

## 技术细节

### Window API 说明

```typescript
setWindowKeepScreenOn(isKeepScreenOn: boolean): Promise<void>
```

**参数：**
- `isKeepScreenOn`: true 表示常亮，false 表示不常亮

**使用规范：**
1. 仅在必要场景（导航、视频播放、绘画、游戏等）下设置为 true
2. 退出上述场景后，应当重置为 false
3. 其他场景（无屏幕互动、音频播放等）下，不使用该接口
4. 系统检测到非规范使用时，可能会恢复自动灭屏功能

### 获取窗口

```typescript
const windowClass = await window.getLastWindow(getContext(this));
```

- `getLastWindow()`: 获取当前应用最后显示的窗口
- `getContext(this)`: 获取插件的上下文

### 错误处理

```typescript
try {
  await windowClass.setWindowKeepScreenOn(isKeepScreenOn);
} catch (err) {
  const error = err as BusinessError;
  console.error(`Code: ${error.code}, Message: ${error.message}`);
}
```

常见错误码：
- `401`: 参数错误
- `1300002`: 窗口状态异常
- `1300003`: 窗口管理服务异常

## 对比测试

### RunningLock API
- ✅ 日志显示成功
- ❌ 实际仍会息屏
- ❌ 需要权限
- ❌ 依赖传感器

### Window API
- ✅ 直接控制窗口
- ✅ 系统级别保证
- ✅ 无需权限
- ✅ 专为此场景设计

## 故障排查

### 问题：仍然会息屏

**检查步骤：**

1. **查看日志**
   ```
   WakelockOhosPlugin: ✅ Screen keep on enabled successfully
   ```
   如果看到这条日志，说明 API 调用成功

2. **检查窗口状态**
   - 确认应用在前台
   - 确认窗口未被遮挡

3. **检查系统设置**
   - 系统电源管理设置
   - 开发者选项中的相关设置

4. **检查系统版本**
   - API 11+ 支持元服务
   - 确认系统版本兼容

### 问题：编译错误

**解决方案：**
```bash
flutter clean
rm -rf ohos/entry/build
flutter pub get
# 重新编译
```

## 性能影响

- **CPU**: 无额外开销
- **内存**: 无额外开销
- **电量**: 屏幕常亮会增加电量消耗（预期行为）

## 后续优化

1. **智能控制**
   - 检测用户交互
   - 长时间无操作时提示

2. **场景适配**
   - 全屏播放时启用
   - 小窗播放时可选

3. **电量优化**
   - 低电量时自动禁用
   - 提供省电模式

## 相关文档

- [鸿蒙 Window API 文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-window-V5)
- `鸿蒙防休眠-最终版本.md`
- `鸿蒙防休眠调试指南.md`

## 版本信息

- **API 版本**: Window API (setWindowKeepScreenOn)
- **系统能力**: SystemCapability.WindowManager.WindowManager.Core
- **元服务支持**: API 11+
- **更新日期**: 2025-12-17
