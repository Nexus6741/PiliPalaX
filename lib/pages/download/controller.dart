import 'dart:async';

import 'package:PiliPalaX/models/download/download_page_info.dart';
import 'package:PiliPalaX/services/download_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class DownloadPageController extends GetxController {
  final _downloadService = Get.find<DownloadService>();
  final pages = RxList<DownloadPageInfo>();
  final flag = RxInt(0);

  // 多选相关
  final enableMultiSelect = false.obs;
  final rxCount = 0.obs;

  List<DownloadPageInfo> get allChecked =>
      pages.where((e) => e.checked == true).toList();

  /// 检查是否全选
  bool get isAllSelected =>
      pages.isNotEmpty && pages.every((e) => e.checked == true);

  /// 检查是否部分选择
  bool get isPartialSelected =>
      pages.any((e) => e.checked == true) && !isAllSelected;

  @override
  void onInit() {
    super.onInit();
    _loadList();
    _downloadService.flagNotifier.add(_loadList);
  }

  @override
  void onClose() {
    _downloadService.flagNotifier.remove(_loadList);
    super.onClose();
  }

  Future<void> _loadList() async {
    await _downloadService.waitForInitialization;
    if (isClosed) return;
    if (_downloadService.downloadList.isEmpty) {
      pages.clear();
      return;
    }
    final list = <DownloadPageInfo>[];
    for (final entry in _downloadService.downloadList) {
      final pageId = entry.pageId;
      final page = list.firstWhereOrNull((e) => e.pageId == pageId);
      if (page != null) {
        final aSortKey = entry.sortKey;
        final bSortKey = page.sortKey;
        if (aSortKey < bSortKey) {
          page
            ..cover = entry.cover
            ..sortKey = aSortKey;
        }
        page.entries.add(entry);
      } else {
        list.add(
          DownloadPageInfo(
            pageId: pageId,
            dirPath: entry.pageDirPath,
            title: entry.title,
            cover: entry.cover,
            sortKey: entry.sortKey,
            seasonType: entry.ep?.seasonType,
            entries: [entry],
          ),
        );
      }
    }
    pages.value = list;
    flag.value++;
  }

  void handleSelect() {
    if (enableMultiSelect.value) {
      // 取消多选
      for (var page in pages) {
        page.checked = false;
      }
      rxCount.value = 0;
      enableMultiSelect.value = false;
    } else {
      // 开启多选
      enableMultiSelect.value = true;
    }
    pages.refresh();
  }

  void onSelect(DownloadPageInfo item) {
    item.checked = !(item.checked ?? false);
    rxCount.value = allChecked.length;
    pages.refresh();
  }

  void onRemove() {
    Get.dialog(
      AlertDialog(
        title: const Text('确定删除选中视频？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              '取消',
              style:
                  TextStyle(color: Theme.of(Get.context!).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              SmartDialog.showLoading(msg: '删除中...');
              final allChecked = this.allChecked.toSet();
              for (var page in allChecked) {
                await _downloadService.deletePage(
                  pageDirPath: page.dirPath,
                  refresh: false,
                );
              }
              _downloadService.flagNotifier.refresh();
              if (enableMultiSelect.value) {
                rxCount.value = 0;
                enableMultiSelect.value = false;
              }
              SmartDialog.dismiss();
              SmartDialog.showToast('删除成功');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 切换页面展开状态
  void toggleExpanded(DownloadPageInfo pageInfo) {
    pageInfo.isExpanded = !pageInfo.isExpanded;
    pages.refresh();
  }

  /// 全选/取消全选
  void toggleSelectAll() {
    final shouldSelectAll = !isAllSelected;
    for (var page in pages) {
      page.checked = shouldSelectAll;
    }
    rxCount.value = shouldSelectAll ? pages.length : 0;
    pages.refresh();
  }
}
