import 'package:flutter/material.dart';

class ColorUtils {
  // 解析颜色字符串（支持 #RRGGBB 和 #AARRGGBB 格式）
  static Color? parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return null;

    try {
      String hexColor = colorStr.replaceAll('#', '');

      // 如果是6位，添加FF作为alpha
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }

      // 如果是8位，直接解析
      if (hexColor.length == 8) {
        return Color(int.parse(hexColor, radix: 16));
      }
    } catch (e) {
      return null;
    }

    return null;
  }
}

// ColorScheme 扩展
extension ColorSchemeExtension on ColorScheme {
  // 判断是否为亮色主题
  bool get isLight => brightness == Brightness.light;

  // VIP颜色
  Color get vipColor => const Color(0xFFFB7299);
}
