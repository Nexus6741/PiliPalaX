import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../utils/storage.dart';

Timer? screenTimer;
void stopScreenTimer() {
  screenTimer?.cancel();
  screenTimer = null;
}

//横屏
Future<void> landScape() async {
  dynamic document;
  try {
    if (kIsWeb) {
      await document.documentElement?.requestFullscreen();
    } else if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.operatingSystem == 'ohos') {
      await AutoOrientation.landscapeAutoMode(forceSensor: true);
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      await const MethodChannel('com.alexmercerind/media_kit_video')
          .invokeMethod(
        'Utils.EnterNativeFullscreen',
      );
    }
  } catch (exception, stacktrace) {
    debugPrint(exception.toString());
    debugPrint(stacktrace.toString());
  }
}

//竖屏
Future<void> verticalScreenForTwoSeconds() async {
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.operatingSystem == 'ohos') {
    await AutoOrientation.portraitAutoMode(forceSensor: true);
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  screenTimer = Timer(const Duration(seconds: 2), () {
    autoScreen();
    screenTimer = null;
  });
}

//竖屏
Future<void> verticalScreen() async {
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.operatingSystem == 'ohos') {
    await AutoOrientation.portraitAutoMode(forceSensor: true);
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
}

//全向
Future<void> autoScreen() async {
  if (!GStorage.setting
      .get(SettingBoxKey.allowRotateScreen, defaultValue: true)) {
    return;
  }
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.operatingSystem == 'ohos') {
    await AutoOrientation.fullAutoMode();
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      // DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

Future<void> fullAutoModeForceSensor() async {
  await AutoOrientation.fullAutoMode();
}

Future<void> toggleStatusBar(bool val) async {
  if (val) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } else {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }
}

//退出全屏显示
Future<void> showStatusBar() async {
  if (GStorage.setting
      .get(SettingBoxKey.alwaysImmersiveStatusBar, defaultValue: false)) {
    // print('Always immersive status bar enabled, skipping showStatusBar');
    return;
  }
  // print('showStatusBar start. OS: ${Platform.operatingSystem}');
  dynamic document;
  late SystemUiMode mode = SystemUiMode.edgeToEdge;
  try {
    if (kIsWeb) {
      document.exitFullscreen();
    } else if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.operatingSystem == 'ohos') {
      if (Platform.isAndroid) {
        final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        // print('Android SDK: $sdkInt');
        if (sdkInt < 29) {
          mode = SystemUiMode.manual;
        }
      }
      // print('Setting SystemUiMode: $mode');
      await SystemChrome.setEnabledSystemUIMode(
        mode,
        overlays: SystemUiOverlay.values,
      );
      // print('showStatusBar end');
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      await const MethodChannel('com.alexmercerind/media_kit_video')
          .invokeMethod(
        'Utils.ExitNativeFullscreen',
      );
    }
  } catch (exception, stacktrace) {
    debugPrint(exception.toString());
    debugPrint(stacktrace.toString());
  }
}
