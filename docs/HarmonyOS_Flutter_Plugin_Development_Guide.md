# Flutter 插件 HarmonyOS 适配开发指南

本文档总结了在 PiliPalaX 项目中为 Flutter 插件适配 HarmonyOS (OpenHarmony/OHOS) 平台的实践经验与要点。

## 目录

1. [项目结构](#项目结构)
2. [关键配置文件](#关键配置文件)
3. [Dart 端开发](#dart-端开发)
4. [ArkTS 原生端开发](#arkts-原生端开发)
5. [平台检测](#平台检测)
6. [权限配置](#权限配置)
7. [常见问题与解决方案](#常见问题与解决方案)
8. [实战案例](#实战案例)

---

## 项目结构

一个支持 HarmonyOS 的 Flutter 插件典型目录结构：

```
my_plugin/
├── lib/
│   └── my_plugin.dart              # Dart API
├── ohos/
│   ├── build-profile.json5         # 构建配置
│   ├── hvigorfile.ts               # Hvigor 构建脚本
│   ├── index.ets                   # 模块导出入口
│   ├── oh-package.json5            # 包配置（类似 package.json）
│   └── src/
│       └── main/
│           ├── module.json5        # 模块配置（权限等）
│           └── ets/
│               └── components/
│                   └── plugin/
│                       └── MyPlugin.ets  # 原生实现
├── pubspec.yaml
└── .gitignore
```

## 关键配置文件

### 1. `ohos/oh-package.json5`

定义包名、版本、依赖等：

```json5
{
  "name": "my_plugin",
  "version": "1.0.0",
  "description": "My Flutter plugin for HarmonyOS",
  "main": "index.ets",
  "author": "",
  "license": "MIT",
  "dependencies": {
    "@aspect/aspectplugin": "file:../../aspect_flutter/aspect"
  },
  "devDependencies": {
    "@aspect/aspectplugin": "file:../../aspect_flutter/aspect"
  }
}
```

### 2. `ohos/build-profile.json5`

构建配置，指定 API 版本和产物类型：

```json5
{
  "apiType": "stageMode",
  "targets": [
    {
      "name": "default",
      "runtimeOS": "HarmonyOS"
    }
  ]
}
```

### 3. `ohos/hvigorfile.ts`

**重要**：必须正确导出 `harTasks`，否则构建会失败：

```typescript
import { harTasks } from '@aspect/aspectplugin';

export default {
    system: harTasks,
    plugins: []
}
```

### 4. `ohos/index.ets`

模块导出入口，**必须使用 default export**：

```typescript
import MyPlugin from './src/main/ets/components/plugin/MyPlugin';

export default MyPlugin;
```

### 5. `ohos/src/main/module.json5`

模块配置，包括权限声明：

```json5
{
  "module": {
    "name": "my_plugin",
    "type": "har",
    "deviceTypes": [
      "default",
      "tablet"
    ]
  }
}
```

## Dart 端开发

### MethodChannel 定义

```dart
import 'dart:async';
import 'package:flutter/services.dart';

class MyPlugin {
  static const MethodChannel _channel = MethodChannel('my_plugin');

  /// 调用原生方法
  static Future<void> doSomething() async {
    await _channel.invokeMethod('doSomething');
  }

  /// 带参数调用
  static Future<void> doSomethingWithArgs({required int value}) async {
    await _channel.invokeMethod('doSomethingWithArgs', {'value': value});
  }

  /// 获取返回值
  static Future<String?> getSomething() async {
    return await _channel.invokeMethod('getSomething');
  }
}
```

## ArkTS 原生端开发

### 插件实现模板

```typescript
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@aspect/aspectplugin';

export default class MyPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  // 插件附加到 Flutter 引擎时调用
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'my_plugin');
    this.channel.setMethodCallHandler(this);
  }

  // 插件从 Flutter 引擎分离时调用
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
  }

  // 处理方法调用
  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'doSomething':
        this.doSomething(result);
        break;
      case 'doSomethingWithArgs':
        const value = call.argument('value') as number;
        this.doSomethingWithArgs(value, result);
        break;
      case 'getSomething':
        result.success('Hello from HarmonyOS');
        break;
      default:
        result.notImplemented();
    }
  }

  private doSomething(result: MethodResult): void {
    try {
      // 执行操作
      result.success(null);
    } catch (error) {
      result.error('ERROR', `Operation failed: ${error}`, null);
    }
  }

  private doSomethingWithArgs(value: number, result: MethodResult): void {
    try {
      // 使用参数执行操作
      result.success(null);
    } catch (error) {
      result.error('ERROR', `Operation failed: ${error}`, null);
    }
  }
}
```

### 使用系统 Kit API

HarmonyOS 提供了丰富的系统 Kit，例如：

```typescript
// 音频 Kit
import { audio } from '@kit.AudioKit';

// 传感器/振动 Kit
import { vibrator } from '@kit.SensorServiceKit';

// 基础服务 Kit
import { emitter } from '@kit.BasicServicesKit';
```

## 平台检测

在 Dart 中检测 HarmonyOS 平台：

```dart
import 'dart:io';

if (Platform.operatingSystem == 'ohos') {
  // HarmonyOS 特定代码
} else {
  // 其他平台代码
}
```

**注意**：不要使用 `UniversalPlatform.isOhos`，应使用 `Platform.operatingSystem == 'ohos'`。

## 权限配置

### 在主应用中配置权限

权限需要在主应用的 `ohos/entry/src/main/module.json5` 中声明：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.VIBRATE"
      }
    ]
  }
}
```

### 常用权限列表

| 权限 | 说明 |
|------|------|
| `ohos.permission.INTERNET` | 网络访问 |
| `ohos.permission.VIBRATE` | 振动控制 |
| `ohos.permission.WRITE_MEDIA` | 媒体写入 |
| `ohos.permission.READ_MEDIA` | 媒体读取 |

## 常见问题与解决方案

### 1. 构建错误：找不到模块

**问题**：`Cannot find module 'xxx'`

**解决**：检查 `oh-package.json5` 中的依赖路径是否正确，确保 `@aspect/aspectplugin` 依赖配置正确。

### 2. 导出错误

**问题**：`Module has no default export`

**解决**：确保 `index.ets` 使用 `export default`：

```typescript
// ✅ 正确
export default MyPlugin;

// ❌ 错误
export { MyPlugin };
```

### 3. hvigorfile.ts 错误

**问题**：构建时 hvigorfile.ts 报错

**解决**：确保正确导入和导出 `harTasks`：

```typescript
import { harTasks } from '@aspect/aspectplugin';

export default {
    system: harTasks,
    plugins: []
}
```

### 4. 方法未实现

**问题**：调用时返回 `MissingPluginException`

**解决**：
- 检查 MethodChannel 名称是否一致
- 确保插件类使用 `export default` 导出
- 确认 `onMethodCall` 中处理了对应的方法名

### 5. 权限不生效

**问题**：功能不工作，无错误提示

**解决**：
- 检查权限是否在主应用的 `module.json5` 中声明
- 某些权限需要用户授权，需要使用权限请求 API

## 实战案例

### 案例 1：flutter_volume_controller（音量控制）

**核心实现**：使用 `@kit.AudioKit` 的 `AudioVolumeManager`

```typescript
import { audio } from '@kit.AudioKit';

private audioVolumeManager: audio.AudioVolumeManager | null = null;

onAttachedToEngine(binding: FlutterPluginBinding): void {
  this.audioVolumeManager = audio.getAudioManager().getVolumeManager();
  // ...
}

private async getVolume(result: MethodResult): Promise<void> {
  try {
    const groupManager = this.audioVolumeManager!.getVolumeGroupManager(audio.DEFAULT_VOLUME_GROUP_ID);
    const volume = await groupManager.getVolume(audio.AudioVolumeType.MEDIA);
    const maxVolume = await groupManager.getMaxVolume(audio.AudioVolumeType.MEDIA);
    result.success(volume / maxVolume);
  } catch (error) {
    result.error('GET_VOLUME_ERROR', `${error}`, null);
  }
}
```

### 案例 2：haptic_feedback_ohos（震动反馈）

**核心实现**：使用 `@kit.SensorServiceKit` 的 `vibrator`

```typescript
import { vibrator } from '@kit.SensorServiceKit';

private vibrate(duration: number, result: MethodResult): void {
  try {
    vibrator.startVibration({
      type: 'time',
      duration: duration
    }, {
      id: 0,
      usage: 'touch'
    }).then(() => {
      result.success(null);
    }).catch((error: Error) => {
      result.error('VIBRATE_ERROR', `${error.message}`, null);
    });
  } catch (error) {
    result.error('VIBRATE_ERROR', `Vibration failed: ${error}`, null);
  }
}
```

**权限配置**：需要在主应用添加 `ohos.permission.VIBRATE`

### 案例 3：device_info_ohos（电量和时间获取）

**核心实现**：使用 `@kit.BasicServicesKit` 的 `batteryInfo` 和 `systemDateTime`

```typescript
import { batteryInfo, systemDateTime } from '@kit.BasicServicesKit';

// 获取电池电量
private getBatteryLevel(result: MethodResult): void {
  try {
    const level = batteryInfo.batterySOC;
    result.success(level);
  } catch (e) {
    result.error('BATTERY_ERROR', `Failed to get battery level: ${e}`, null);
  }
}

// 获取电池详细信息
private getBatteryInfo(result: MethodResult): void {
  try {
    const level = batteryInfo.batterySOC;
    const chargingStatus = batteryInfo.chargingStatus;
    const isCharging = chargingStatus === batteryInfo.BatteryChargeState.ENABLE ||
                       chargingStatus === batteryInfo.BatteryChargeState.FULL;
    
    const info: Map<string, Object> = new Map();
    info.set('level', level);
    info.set('isCharging', isCharging);
    
    result.success(Object.fromEntries(info));
  } catch (e) {
    result.error('BATTERY_ERROR', `Failed to get battery info: ${e}`, null);
  }
}

// 获取当前时间戳
private getCurrentTimeMillis(result: MethodResult): void {
  try {
    const time = systemDateTime.getTime();
    result.success(time);
  } catch (e) {
    result.success(Date.now()); // 降级方案
  }
}
```

**Dart 端使用示例**：

```dart
import 'package:device_info_ohos/device_info_ohos.dart';

// 获取电量百分比
final int level = await DeviceInfoOhos.getBatteryLevel();

// 获取电池详细信息
final BatteryInfo? info = await DeviceInfoOhos.getBatteryInfo();
if (info != null) {
  print('电量: ${info.level}%');
  print('正在充电: ${info.isCharging}');
}

// 获取格式化时间
final String time = await DeviceInfoOhos.getFormattedTime(format: 'HH:mm');
```

**在播放器中显示电量和时间**：

```dart
// 在全屏播放器顶部显示电量和时间
if (Platform.operatingSystem == 'ohos')
  Row(
    children: [
      Icon(
        isCharging ? Icons.battery_charging_full : Icons.battery_full,
        color: level <= 15 ? Colors.red : Colors.white,
        size: 16,
      ),
      Text('$level%'),
      SizedBox(width: 8),
      Text(currentTime),
    ],
  ),
```

## Git 忽略配置

推荐的 `.gitignore` 配置：

```gitignore
# HarmonyOS 构建产物
build/
oh_modules/
.cxx/

# 自动生成的文件
BuildProfile.ets
oh-package-lock.json5

# IDE 配置
.idea/
```

## 依赖引用方式

### 本地路径引用

```yaml
dependencies:
  my_plugin:
    path: ./packages/my_plugin
```

### Git 仓库引用

```yaml
dependencies:
  my_plugin:
    git:
      url: https://github.com/user/my_plugin.git
      ref: main
```

---

## 总结

1. **目录结构**：遵循标准结构，`ohos/` 目录存放原生代码
2. **导出方式**：使用 `export default` 导出插件类
3. **平台检测**：使用 `Platform.operatingSystem == 'ohos'`
4. **权限配置**：在主应用的 `module.json5` 中声明
5. **调试技巧**：使用 `console.log` 在原生端打印日志
6. **版本管理**：使用 Git 管理，忽略构建产物

通过遵循以上指南，可以高效地为 Flutter 插件添加 HarmonyOS 平台支持。
