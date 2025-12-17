import 'dart:io';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_ohos/wakelock_ohos.dart';

/// 防休眠管理器
/// 统一管理鸿蒙和其他平台的防休眠功能
class WakelockManager {
  WakelockManager._();

  static final WakelockManager _instance = WakelockManager._();
  static WakelockManager get instance => _instance;

  bool _isEnabled = false;

  /// 判断是否为鸿蒙平台
  bool get _isOhos => Platform.operatingSystem == 'ohos';

  /// 启用防休眠
  Future<void> enable() async {
    if (_isEnabled) {
      // ignore: avoid_print
      // print('WakelockManager: 防休眠已经启用，跳过');
      return;
    }

    try {
      // ignore: avoid_print
      // print('WakelockManager: 开始启用防休眠...');
      // ignore: avoid_print
      // print('WakelockManager: 当前平台 - ${Platform.operatingSystem}');

      if (_isOhos) {
        // 鸿蒙平台使用专用插件，永久持锁直到主动释放
        // ignore: avoid_print
        // print('WakelockManager: 调用 WakelockOhos.enable()');
        final success = await WakelockOhos.enable(timeout: -1);
        if (success) {
          _isEnabled = true;
          // ignore: avoid_print
          // print('WakelockManager: ✅ 鸿蒙防休眠已启用成功');
        } else {
          // ignore: avoid_print
          // print('WakelockManager: ❌ 鸿蒙防休眠启用失败');
        }
      } else {
        // 其他平台使用 wakelock_plus
        // ignore: avoid_print
        // print('WakelockManager: 调用 WakelockPlus.enable()');
        await WakelockPlus.enable();
        _isEnabled = true;
        // ignore: avoid_print
        // print('WakelockManager: ✅ 防休眠已启用');
      }
    } catch (e) {
      // ignore: avoid_print
      // print('WakelockManager: ❌ 启用防休眠异常 - $e');
      // ignore: avoid_print
      // print('WakelockManager: 异常堆栈 - ${StackTrace.current}');
    }
  }

  /// 禁用防休眠
  Future<void> disable() async {
    if (!_isEnabled) {
      // ignore: avoid_print
      // print('WakelockManager: 防休眠未启用，跳过禁用');
      return;
    }

    try {
      // ignore: avoid_print
      // print('WakelockManager: 开始禁用防休眠...');

      if (_isOhos) {
        // ignore: avoid_print
        // print('WakelockManager: 调用 WakelockOhos.disable()');
        final success = await WakelockOhos.disable();
        if (success) {
          _isEnabled = false;
          // ignore: avoid_print
          // print('WakelockManager: ✅ 鸿蒙防休眠已禁用');
        } else {
          // ignore: avoid_print
          // print('WakelockManager: ❌ 鸿蒙防休眠禁用失败');
        }
      } else {
        // ignore: avoid_print
        // print('WakelockManager: 调用 WakelockPlus.disable()');
        await WakelockPlus.disable();
        _isEnabled = false;
        // ignore: avoid_print
        // print('WakelockManager: ✅ 防休眠已禁用');
      }
    } catch (e) {
      // ignore: avoid_print
      // print('WakelockManager: ❌ 禁用防休眠异常 - $e');
    }
  }

  /// 检查是否已启用
  Future<bool> isEnabled() async {
    try {
      if (_isOhos) {
        return await WakelockOhos.isHolding();
      } else {
        return await WakelockPlus.enabled;
      }
    } catch (e) {
      // ignore: avoid_print
      // print('WakelockManager: 检查状态失败 - $e');
      return false;
    }
  }

  /// 检查系统是否支持
  Future<bool> isSupported() async {
    try {
      if (_isOhos) {
        return await WakelockOhos.isSupported();
      } else {
        // wakelock_plus 在支持的平台上都可用
        return true;
      }
    } catch (e) {
      // ignore: avoid_print
      // print('WakelockManager: 检查支持状态失败 - $e');
      return false;
    }
  }
}
