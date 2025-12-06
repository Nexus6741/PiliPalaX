import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension ImageExtension on num {
  int cacheSize(BuildContext context) {
    return (this * MediaQuery.of(context).devicePixelRatio).round();
  }
}

extension ScrollControllerExt on ScrollController {
  void animToTop() {
    if (!hasClients) return;
    if (offset >= MediaQuery.of(Get.context!).size.height * 5) {
      jumpTo(0);
    } else {
      animateTo(0,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  void jumpToTop() {
    if (!hasClients) return;
    jumpTo(0);
  }
}

extension ListCast on List {
  List<T> fromCast<T>() {
    return map((e) => e as T).toList();
  }
}

extension IterableExt<T> on Iterable<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

extension BrightnessExt on Brightness {
  bool get isDark => this == Brightness.dark;
}
