import 'dart:io';
import 'package:flutter/services.dart';
import 'package:haptic_feedback_ohos/haptic_feedback_ohos.dart';
import 'package:hive/hive.dart';
import 'storage.dart';

/// 震动反馈类型
enum FeedBackType {
  light(0, '轻触反馈'),
  medium(1, '中等反馈'),
  heavy(2, '重触反馈'),
  custom(3, '自定义时长');

  final int code;
  final String description;
  const FeedBackType(this.code, this.description);

  static FeedBackType fromCode(int code) {
    return FeedBackType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => FeedBackType.light,
    );
  }
}

void feedBack() {
  Box<dynamic> setting = GStorage.setting;
  // 设置中是否开启
  final bool enable =
      setting.get(SettingBoxKey.feedBackEnable, defaultValue: false) as bool;
  if (!enable) return;

  final int typeCode =
      setting.get(SettingBoxKey.feedBackType, defaultValue: 0) as int;
  final FeedBackType type = FeedBackType.fromCode(typeCode);
  final int duration =
      setting.get(SettingBoxKey.feedBackDuration, defaultValue: 50) as int;

  if (Platform.operatingSystem == 'ohos') {
    _feedBackOhos(type, duration);
  } else {
    _feedBackDefault(type);
  }
}

void _feedBackOhos(FeedBackType type, int duration) {
  switch (type) {
    case FeedBackType.light:
      HapticFeedbackOhos.lightImpact();
      break;
    case FeedBackType.medium:
      HapticFeedbackOhos.mediumImpact();
      break;
    case FeedBackType.heavy:
      HapticFeedbackOhos.heavyImpact();
      break;
    case FeedBackType.custom:
      HapticFeedbackOhos.vibrate(duration: duration);
      break;
  }
}

void _feedBackDefault(FeedBackType type) {
  switch (type) {
    case FeedBackType.light:
      HapticFeedback.lightImpact();
      break;
    case FeedBackType.medium:
      HapticFeedback.mediumImpact();
      break;
    case FeedBackType.heavy:
      HapticFeedback.heavyImpact();
      break;
    case FeedBackType.custom:
      HapticFeedback.mediumImpact();
      break;
  }
}
