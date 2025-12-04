import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/http/init.dart';
import 'package:PiliPalaX/models/common/theme_type.dart';
import 'package:PiliPalaX/utils/feed_back.dart';
import 'package:PiliPalaX/utils/login.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/common/dynamic_badge_mode.dart';
import '../../models/common/nav_bar_config.dart';
import '../main/index.dart';
import 'widgets/select_dialog.dart';

class SettingController extends GetxController {
  Box userInfoCache = GStorage.userInfo;
  Box setting = GStorage.setting;
  Box localCache = GStorage.localCache;

  RxBool userLogin = false.obs;
  RxBool hiddenSettingUnlocked = false.obs;
  RxBool feedBackEnable = false.obs;
  RxDouble toastOpacity = (1.0).obs;
  RxInt picQuality = 10.obs;
  Rx<ThemeType> themeType = ThemeType.system.obs;
  var userInfo;
  Rx<DynamicBadgeMode> dynamicBadgeType = DynamicBadgeMode.number.obs;
  RxInt defaultHomePage = 0.obs;

  @override
  void onInit() {
    super.onInit();
    userInfo = userInfoCache.get('userInfoCache');
    userLogin.value = userInfo != null;
    hiddenSettingUnlocked.value =
        setting.get(SettingBoxKey.hiddenSettingUnlocked, defaultValue: false);
    feedBackEnable.value =
        setting.get(SettingBoxKey.feedBackEnable, defaultValue: false);
    toastOpacity.value =
        setting.get(SettingBoxKey.defaultToastOp, defaultValue: 1.0);
    picQuality.value =
        setting.get(SettingBoxKey.defaultPicQa, defaultValue: 10);
    themeType.value = ThemeType.values[setting.get(SettingBoxKey.themeMode,
        defaultValue: ThemeType.system.code)];
    dynamicBadgeType.value = DynamicBadgeMode.values[setting.get(
        SettingBoxKey.dynamicBadgeMode,
        defaultValue: DynamicBadgeMode.number.code)];
    defaultHomePage.value =
        setting.get(SettingBoxKey.defaultHomePage, defaultValue: 0);
  }

  loginOut(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('确认要退出登录吗'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('点错了'),
            ),
            TextButton(
              onPressed: () async {
                // 清空cookie
                await Request.cookieManager.cookieJar.deleteAll();
                Request.dio.options.headers['cookie'] = '';
                // 清空本地存储的用户标识
                userInfoCache.put('userInfoCache', null);
                localCache.put(LocalCacheKey.accessKey,
                    {'mid': -1, 'value': '', 'refresh': ''});
                try {
                  final WebViewController controller = WebViewController();
                  controller.clearCache();
                  controller.clearLocalStorage();
                  WebViewCookieManager().clearCookies();
                } catch (e) {
                  print(e);
                }
                userLogin.value = false;
                if (Get.isRegistered<MainController>()) {
                  MainController mainController = Get.find<MainController>();
                  mainController.userLogin.value = false;
                }
                await LoginUtils.refreshLoginStatus(false);
                Get.back();
              },
              child: const Text('确认'),
            )
          ],
        );
      },
    );
  }

  // 开启关闭震动反馈
  onOpenFeedBack() {
    feedBack();
    feedBackEnable.value = !feedBackEnable.value;
    setting.put(SettingBoxKey.feedBackEnable, feedBackEnable.value);
  }

  // 设置震动反馈类型
  setFeedBackType(BuildContext context) async {
    int currentType = setting.get(SettingBoxKey.feedBackType, defaultValue: 0);
    int? result = await showDialog(
      context: context,
      builder: (context) {
        return SelectDialog<int>(
          title: '震动反馈类型',
          value: currentType,
          values: FeedBackType.values.map((e) {
            return {'title': e.description, 'value': e.code};
          }).toList(),
        );
      },
    );
    if (result != null) {
      setting.put(SettingBoxKey.feedBackType, result);
      feedBack();
      SmartDialog.showToast('设置成功');
    }
  }

  // 设置自定义震动时长
  setFeedBackDuration(BuildContext context) async {
    int currentDuration =
        setting.get(SettingBoxKey.feedBackDuration, defaultValue: 50);
    TextEditingController textController =
        TextEditingController(text: currentDuration.toString());

    int? result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自定义震动时长'),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '时长（毫秒）',
              hintText: '建议 20-200',
              suffixText: 'ms',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                int? duration = int.tryParse(textController.text);
                if (duration != null && duration > 0 && duration <= 1000) {
                  Get.back(result: duration);
                } else {
                  SmartDialog.showToast('请输入 1-1000 之间的数值');
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setting.put(SettingBoxKey.feedBackDuration, result);
      feedBack();
      SmartDialog.showToast('设置成功：${result}ms');
    }
  }

  // 设置动态未读标记
  setDynamicBadgeMode(BuildContext context) async {
    DynamicBadgeMode? result = await showDialog(
      context: context,
      builder: (context) {
        return SelectDialog<DynamicBadgeMode>(
          title: '动态未读标记',
          value: dynamicBadgeType.value,
          values: DynamicBadgeMode.values.map((e) {
            return {'title': e.description, 'value': e};
          }).toList(),
        );
      },
    );
    if (result != null) {
      dynamicBadgeType.value = result;
      setting.put(SettingBoxKey.dynamicBadgeMode, result.code);
      MainController mainController = Get.put(MainController());
      mainController.dynamicBadgeType = DynamicBadgeMode.values[result.code];
      if (mainController.dynamicBadgeType != DynamicBadgeMode.hidden) {
        mainController.getUnreadDynamic();
      }
      SmartDialog.showToast('设置成功');
    }
  }

  // 设置默认启动页
  setDefaultHomePage(BuildContext context) async {
    int? result = await showDialog(
      context: context,
      builder: (context) {
        return SelectDialog<int>(
            title: '首页启动页',
            value: defaultHomePage.value,
            values: defaultNavigationBars.map((e) {
              return {'title': e['label'], 'value': e['id']};
            }).toList());
      },
    );
    if (result != null) {
      defaultHomePage.value = result;
      setting.put(SettingBoxKey.defaultHomePage, result);
      SmartDialog.showToast('设置成功，重启生效');
    }
  }
}
