# 快速测试 - Window API 版本

## 更新内容

✅ 已从 `runningLock` API 切换到 `window.setWindowKeepScreenOn()` API  
✅ 移除了 RUNNING_LOCK 权限要求  
✅ 简化了实现，提高了可靠性  

## 测试步骤

### 1. 重新编译应用

```bash
flutter clean
flutter pub get
# 在 DevEco Studio 或命令行重新编译鸿蒙应用
```

### 2. 安装并运行

将应用安装到鸿蒙设备或模拟器

### 3. 播放视频测试

1. 打开应用
2. 播放任意视频
3. 查看日志输出

**预期日志：**
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

4. 等待超过系统设置的息屏时间（例如 30 秒）

**预期结果：** ✅ 屏幕保持常亮，不会自动息屏

### 4. 暂停测试

1. 暂停视频
2. 查看日志输出

**预期日志：**
```
WakelockManager: 开始禁用防休眠...
WakelockManager: 调用 WakelockOhos.disable()
WakelockOhos: 调用原生 disable 方法
WakelockOhosPlugin: Disabling screen keep on...
WakelockOhosPlugin: Got window, setting keep screen on to: false
WakelockOhosPlugin: Window keep screen on set to: false
WakelockOhosPlugin: ✅ Screen keep on disabled successfully
WakelockOhos: 原生 disable 返回结果: true
WakelockManager: ✅ 鸿蒙防休眠已禁用
```

3. 等待系统息屏时间

**预期结果：** ✅ 屏幕正常息屏

### 5. 退出测试

1. 播放视频
2. 退出播放页面
3. 查看日志（应该看到 disable 调用）

**预期结果：** ✅ 锁已释放，屏幕可以正常息屏

## 对比测试结果

### RunningLock API（旧版本）
- ✅ 日志显示成功
- ❌ 实际仍会息屏
- ❌ 需要 RUNNING_LOCK 权限
- ❌ 依赖接近光传感器

### Window API（新版本）
- ✅ 日志显示成功
- ✅ 实际不会息屏（预期）
- ✅ 无需额外权限
- ✅ 直接控制窗口状态

## 故障排查

### 如果仍然息屏

1. **检查日志是否有错误**
   ```
   WakelockOhosPlugin: ❌ Enable screen keep on error: ...
   ```

2. **检查窗口状态**
   - 确认应用在前台
   - 确认没有其他窗口遮挡

3. **检查系统设置**
   - 系统电源管理
   - 开发者选项

4. **尝试手动测试**
   在视频页面添加测试按钮：
   ```dart
   ElevatedButton(
     onPressed: () async {
       await WakelockManager.instance.enable();
       print('手动启用防休眠');
     },
     child: Text('启用防休眠'),
   )
   ```

### 如果编译错误

```bash
# 清理缓存
flutter clean
rm -rf ohos/entry/build

# 重新获取依赖
flutter pub get

# 重新编译
```

## 技术优势

### Window API 的优势

1. **直接控制**
   - 直接控制窗口的屏幕常亮状态
   - 不依赖传感器或其他硬件

2. **系统保证**
   - 系统级别的 API
   - 专门为视频播放等场景设计

3. **简单可靠**
   - 无需权限
   - 实现简单
   - 错误处理清晰

4. **规范使用**
   - 符合鸿蒙官方推荐
   - 适用于视频播放场景

## 预期效果

### 播放视频时
- 屏幕保持常亮
- 不会自动息屏
- 不影响其他功能

### 暂停视频时
- 屏幕可以正常息屏
- 恢复系统默认行为

### 退出播放器时
- 自动释放屏幕常亮
- 不影响其他应用

## 下一步

如果测试成功：
- ✅ 功能正常工作
- ✅ 可以正常使用

如果测试失败：
- 查看详细日志
- 参考 `鸿蒙防休眠调试指南.md`
- 检查系统版本和设置

## 相关文档

- `鸿蒙防休眠-Window-API版本.md` - 详细的技术说明
- `鸿蒙防休眠调试指南.md` - 故障排查指南
- `packages/wakelock_ohos/README.md` - 插件文档

## 版本信息

- **API**: window.setWindowKeepScreenOn()
- **权限**: 无需额外权限
- **更新日期**: 2025-12-17
- **状态**: 待测试
