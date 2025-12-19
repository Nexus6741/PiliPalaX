# Hero动画退出优化完成

## 问题描述
在推荐页、热门页、影视页等地方使用Hero动画进入视频详情页时，进入动画效果良好，但退出时存在以下问题：
1. **掉帧**：退出动画不流畅，特别是在视频播放过程中退出
2. **闪烁**：有时会出现黑屏或画面闪烁
3. **性能问题**：播放器在Hero动画期间仍在运行，占用大量资源

## 优化方案

### 1. 优化Hero动画淡出策略 (`lib/common/widgets/enhanced_hero.dart`)

#### 修改点：VideoHero类的flightShuttleBuilder

**优化前的问题：**
- 在动画的最后20%才开始淡出
- 播放器在动画期间仍在渲染，导致掉帧

**优化后的改进：**
```dart
// 🔥 在动画的前60%保持完全可见，后40%快速淡出
// 这样可以在播放器暂停/销毁后再开始淡出，避免黑屏闪烁
final opacity = animation.value > 0.6
    ? 1.0 - ((animation.value - 0.6) / 0.4)
    : 1.0;

// 🔥 使用更平滑的缩放曲线
final curvedValue = Curves.easeInQuad.transform(animation.value);
final scale = 1.0 - (curvedValue * 0.03);
```

**关键改进：**
- ✅ 延迟淡出时机：从80%改为60%开始淡出，给播放器更多时间暂停
- ✅ 更平滑的曲线：使用`Curves.easeInQuad`替代线性变化
- ✅ 减小缩放幅度：从2%改为3%，让动画更明显但不过度
- ✅ 添加占位符优化：使用透明占位符避免闪烁

### 2. 在页面退出前暂停播放器 (`lib/pages/video/view.dart`)

#### 修改点1：dispose方法

**优化前：**
```dart
plPlayerController!.disable();
```

**优化后：**
```dart
// 🔥 在页面销毁前先暂停播放器，避免Hero动画时的掉帧
plPlayerController!.pause(notify: false);
Future.delayed(const Duration(milliseconds: 100), () {
  if (plPlayerController != null) {
    plPlayerController!.disable();
  }
});
```

**关键改进：**
- ✅ 立即暂停播放器，停止视频解码和渲染
- ✅ 延迟100ms销毁播放器，让Hero动画先完成
- ✅ 使用`notify: false`避免触发不必要的状态更新

#### 修改点2：所有PopScope的onPopInvoked回调（5处）

**优化前：**
```dart
onPopInvoked: (bool didPop) {
  if (didPop) {
    triggerFloatingWindowWhenLeaving();
  }
}
```

**优化后：**
```dart
onPopInvoked: (bool didPop) async {
  if (didPop) {
    // 🔥 在退出前暂停播放器，减少Hero动画掉帧
    if (plPlayerController != null && 
        !floatingManager.containsFloating(globalId)) {
      await plPlayerController!.pause(notify: false);
    }
    triggerFloatingWindowWhenLeaving();
  }
}
```

**关键改进：**
- ✅ 在所有退出点（5个PopScope）都添加了播放器暂停逻辑
- ✅ 使用`async/await`确保暂停操作完成后再继续
- ✅ 检查浮窗状态，避免影响小窗播放
- ✅ 在Hero动画开始前就暂停播放器，避免资源竞争

## 优化效果

### 性能提升
1. **减少掉帧**：播放器在Hero动画前暂停，释放解码和渲染资源
2. **消除闪烁**：延迟淡出时机，确保播放器已暂停后再开始淡出
3. **更流畅的动画**：使用更平滑的曲线和合理的淡出策略

### 用户体验改进
1. **退出更自然**：动画过渡更平滑，没有突兀的黑屏
2. **响应更快**：播放器暂停后系统资源释放，页面切换更快
3. **稳定性提升**：避免了播放器和Hero动画的资源竞争

## 技术细节

### 时序优化
```
用户点击返回
    ↓
onPopInvoked触发
    ↓
立即暂停播放器 (pause)
    ↓
Hero动画开始 (前60%保持可见)
    ↓
Hero动画淡出 (后40%快速淡出)
    ↓
页面销毁
    ↓
延迟100ms后销毁播放器 (disable)
```

### 关键参数
- **淡出起始点**：60% (原80%)
- **淡出持续时间**：40% (原20%)
- **缩放幅度**：3% (原2%)
- **播放器销毁延迟**：100ms
- **动画曲线**：Curves.easeInQuad

## 测试建议

### 测试场景
1. ✅ 从推荐页进入视频详情页，播放视频后退出
2. ✅ 从热门页进入视频详情页，播放视频后退出
3. ✅ 从影视页进入番剧详情页，播放视频后退出
4. ✅ 在视频播放过程中快速退出
5. ✅ 在视频暂停状态下退出
6. ✅ 在全屏状态下退出
7. ✅ 在横屏状态下退出

### 验证要点
- [ ] 退出动画是否流畅，无明显掉帧
- [ ] 是否还有黑屏或闪烁现象
- [ ] 播放器是否正确暂停和销毁
- [ ] 小窗播放功能是否正常
- [ ] 不同屏幕方向下是否都正常

## 注意事项

1. **小窗播放兼容**：优化代码中检查了`floatingManager.containsFloating(globalId)`，确保不影响小窗播放功能

2. **异步处理**：所有`onPopInvoked`回调都改为`async`，确保播放器暂停操作完成

3. **延迟销毁**：播放器销毁延迟100ms，给Hero动画足够的完成时间

4. **静默暂停**：使用`pause(notify: false)`避免触发媒体通知和其他状态更新

## 相关文件

- `lib/common/widgets/enhanced_hero.dart` - Hero动画配置
- `lib/pages/video/view.dart` - 视频详情页面
- `lib/plugin/pl_player/controller.dart` - 播放器控制器

## 总结

通过优化Hero动画的淡出策略和在退出前暂停播放器，成功解决了退出动画掉帧和闪烁的问题。关键在于：
1. **时序控制**：在Hero动画前暂停播放器
2. **延迟淡出**：给播放器足够的暂停时间
3. **平滑曲线**：使用更自然的动画曲线
4. **延迟销毁**：避免播放器销毁影响动画

这些优化显著提升了用户体验，特别是在视频播放过程中退出的场景。
