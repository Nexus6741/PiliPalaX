import 'dart:async';

import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/models/download/download_entry_info.dart';
import 'package:PiliPalaX/models/download/download_episode_info.dart';
import 'package:PiliPalaX/models/download/download_page_info.dart';
import 'package:PiliPalaX/pages/download/controller.dart';
import 'package:PiliPalaX/services/download_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _downloadService = Get.find<DownloadService>();
  late final _controller = Get.put(DownloadPageController());
  final _progress = ValueNotifier<Map<int, double>>({});

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);

    return Obx(() {
      final enableMultiSelect = _controller.enableMultiSelect.value;
      return PopScope(
        canPop: !enableMultiSelect,
        onPopInvokedWithResult: (didPop, result) {
          if (enableMultiSelect && !didPop) {
            _controller.handleSelect();
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: enableMultiSelect
                ? Text('已选择 ${_controller.rxCount.value} 项')
                : const Text('离线缓存'),
            leading: enableMultiSelect
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _controller.handleSelect,
                  )
                : null,
            actions: enableMultiSelect
                ? [
                    // 全选按钮
                    IconButton(
                      icon: Icon(
                        _controller.isAllSelected
                            ? Icons.check_box
                            : _controller.isPartialSelected
                                ? Icons.indeterminate_check_box
                                : Icons.check_box_outline_blank,
                      ),
                      onPressed: _controller.toggleSelectAll,
                      tooltip: _controller.isAllSelected ? '取消全选' : '全选',
                    ),
                    TextButton(
                      onPressed: () async {
                        final allChecked = _controller.allChecked.toSet();
                        _controller.handleSelect();
                        final list = <DownloadEntryInfo>[];
                        for (var page in allChecked) {
                          list.addAll(page.entries);
                        }
                        SmartDialog.showLoading(msg: '更新中...');
                        final res = await Future.wait(
                          list.map(
                            (e) => _downloadService.downloadDanmaku(
                              entry: e,
                              isUpdate: true,
                            ),
                          ),
                        );
                        SmartDialog.dismiss();
                        if (res.every((e) => e)) {
                          SmartDialog.showToast('更新成功');
                        } else {
                          SmartDialog.showToast('更新失败');
                        }
                      },
                      child: Text(
                        '更新弹幕',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _controller.onRemove,
                    ),
                  ]
                : [
                    IconButton(
                      tooltip: '多选',
                      onPressed: _controller.handleSelect,
                      icon: const Icon(Icons.checklist),
                    ),
                    const SizedBox(width: 6),
                  ],
          ),
          body: Padding(
            padding: EdgeInsets.only(left: padding.left, right: padding.right),
            child: CustomScrollView(
              slivers: [
                // 正在下载的项
                Obx(() {
                  if (_downloadService.waitDownloadQueue.isNotEmpty) {
                    return SliverMainAxisGroup(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            top: 12,
                            bottom: 7,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '缓存队列 (${_downloadService.waitDownloadQueue.length})',
                                  style: theme.textTheme.titleSmall,
                                ),
                                if (_downloadService.waitDownloadQueue.length >
                                    1)
                                  TextButton(
                                    onPressed: () {
                                      Get.dialog(
                                        AlertDialog(
                                          title: const Text('清空缓存队列'),
                                          content:
                                              const Text('确定要清空所有等待中的缓存任务吗？'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: Text(
                                                '取消',
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.outline,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Get.back();
                                                await _downloadService
                                                    .clearWaitingQueue();
                                                SmartDialog.showToast(
                                                    '已清空缓存队列');
                                              },
                                              child: const Text('确定'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '清空队列',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry =
                                    _downloadService.waitDownloadQueue[index];
                                final isCurrentDownloading =
                                    entry.cid == _downloadService.curCid;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildDownloadingItem(entry, theme,
                                      isCurrentDownloading, index),
                                );
                              },
                              childCount:
                                  _downloadService.waitDownloadQueue.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SliverToBoxAdapter();
                }),
                // 已下载的视频
                Obx(() {
                  if (_controller.pages.isNotEmpty) {
                    return SliverMainAxisGroup(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left: 12,
                            bottom: 7,
                            top: _downloadService.waitDownloadQueue.isEmpty
                                ? 12
                                : 7,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              '已缓存视频',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _controller.pages[index];
                                if (item.entries.length == 1) {
                                  final entry = item.entries.first;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: SizedBox(
                                      height: 100,
                                      child: _buildSingleEntryItem(
                                        entry,
                                        item,
                                        theme,
                                        enableMultiSelect,
                                      ),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildMultiEntryItem(
                                    theme,
                                    item,
                                    enableMultiSelect,
                                  ),
                                );
                              },
                              childCount: _controller.pages.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  if (_downloadService.waitDownloadQueue.isNotEmpty) {
                    return const SliverToBoxAdapter();
                  }
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  );
                }),
                SliverToBoxAdapter(
                  child: SizedBox(height: padding.bottom + 100),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 构建正在下载的项
  Widget _buildDownloadingItem(
    DownloadEntryInfo entry,
    ThemeData theme,
    bool isCurrentDownloading,
    int queueIndex,
  ) {
    return Obx(() {
      final status = entry.status.value;
      final totalBytes = entry.totalBytes.value;
      final downloadedBytes = entry.downloadedBytes.value;
      final progress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: InkWell(
          onTap: () {
            // 可以跳转到详情页
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 队列序号指示器
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCurrentDownloading
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCurrentDownloading
                        ? Icon(
                            Icons.download,
                            size: 14,
                            color: theme.colorScheme.onPrimary,
                          )
                        : Text(
                            '${queueIndex + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // 封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: NetworkImgLayer(
                    width: 100,
                    height: 60,
                    src: entry.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.showTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              entry.qualityPithyDescription,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isCurrentDownloading
                                  ? (status?.message ?? '等待中')
                                  : '等待中',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // 进度条和进度信息
                      if (isCurrentDownloading) ...[
                        // 正在下载：显示动态进度条
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          minHeight: 3,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            if (totalBytes > 0)
                              Text(
                                '${_formatBytes(downloadedBytes)}/${_formatBytes(totalBytes)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                          ],
                        ),
                      ] else ...[
                        // 等待中：如果有进度则显示，否则显示空进度条
                        if (totalBytes > 0 && downloadedBytes > 0) ...[
                          // 有进度：显示静态进度条
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            minHeight: 3,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '已暂停 ${(progress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              Text(
                                '${_formatBytes(downloadedBytes)}/${_formatBytes(totalBytes)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // 无进度：显示空进度条
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '队列中第${queueIndex + 1}位',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                // 操作按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCurrentDownloading) ...[
                      // 正在下载的视频：暂停/继续按钮
                      if (status == DownloadStatus.pause)
                        // 继续按钮
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () {
                            _downloadService.resumeDownload(entry);
                            SmartDialog.showToast('继续下载');
                          },
                          tooltip: '继续下载',
                        )
                      else
                        // 暂停按钮
                        IconButton(
                          icon: const Icon(Icons.pause),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () {
                            // 暂停时不启动下一个下载
                            _downloadService.cancelDownload(
                              isDelete: false,
                              downloadNext: false,
                            );
                            SmartDialog.showToast('已暂停下载');
                          },
                          tooltip: '暂停下载',
                        ),
                      // 取消按钮（统一使用X图标）
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          Get.dialog(
                            AlertDialog(
                              title: const Text('取消缓存'),
                              content: Text('确定要取消缓存"${entry.showTitle}"吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text(
                                    '取消',
                                    style: TextStyle(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Get.back();
                                    await _downloadService
                                        .removeFromWaitingQueue(entry);
                                    SmartDialog.showToast('已取消缓存');
                                  },
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: '取消缓存',
                      ),
                    ] else ...[
                      // 等待中的视频：开始下载按钮
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          _downloadService.prioritizeDownload(entry);
                          SmartDialog.showToast('开始下载');
                        },
                        tooltip: '立即下载',
                      ),
                      // 取消按钮（统一使用X图标）
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          Get.dialog(
                            AlertDialog(
                              title: const Text('取消缓存'),
                              content: Text('确定要取消缓存"${entry.showTitle}"吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text(
                                    '取消',
                                    style: TextStyle(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Get.back();
                                    await _downloadService
                                        .removeFromWaitingQueue(entry);
                                    SmartDialog.showToast('已取消缓存');
                                  },
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: '取消缓存',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 构建单个视频项
  Widget _buildSingleEntryItem(
    DownloadEntryInfo entry,
    DownloadPageInfo pageInfo,
    ThemeData theme,
    bool enableMultiSelect,
  ) {
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (enableMultiSelect) {
            _controller.onSelect(pageInfo);
            return;
          }
          // 跳转到视频播放页 - 离线播放
          final heroTag =
              '${entry.bvid}_${entry.cid}_${DateTime.now().millisecondsSinceEpoch}';

          Get.toNamed(
            '/video',
            parameters: {
              'bvid': entry.bvid,
              'cid': entry.cid.toString(),
            },
            arguments: {
              'sourceType': 'file',
              'entry': entry,
              'dirPath': entry.entryDirPath,
              'heroTag': heroTag,
              'pic': entry.cover, // 直接传递 pic，不传递 videoItem Map
            },
          );
        },
        onLongPress: () {
          if (!enableMultiSelect) {
            _showEntryOptions(entry, pageInfo);
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // 封面
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: NetworkImgLayer(
                      width: 120,
                      height: 75,
                      src: entry.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.showTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          entry.qualityPithyDescription,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme
                                                .colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (entry.ownerName != null)
                                        Flexible(
                                          child: Text(
                                            entry.ownerName!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.outline,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.formattedFileSize,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            entry.moreBtn(theme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (enableMultiSelect)
              Positioned(
                top: 4,
                right: 4,
                child: Checkbox(
                  value: pageInfo.checked ?? false,
                  onChanged: (_) => _controller.onSelect(pageInfo),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建多个视频项（合集）
  Widget _buildMultiEntryItem(
    ThemeData theme,
    DownloadPageInfo pageInfo,
    bool enableMultiSelect,
  ) {
    final first = pageInfo.entries.first;
    final hasMultipleEpisodes = pageInfo.hasMultipleEpisodes;
    // 检查是否应该使用三级结构：多集 或 单集多画质
    final useThreeLevelStructure = pageInfo.episodes != null &&
        (pageInfo.episodes!.length > 1 ||
            (pageInfo.episodes!.length == 1 &&
                pageInfo.episodes!.first.entries.length > 1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 主卡片
        Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (enableMultiSelect) {
                _controller.onSelect(pageInfo);
                return;
              }
              // 切换展开状态
              _controller.toggleExpanded(pageInfo);
            },
            onLongPress: () {
              if (!enableMultiSelect) {
                _showPageOptions(pageInfo);
              }
            },
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      // 封面
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: NetworkImgLayer(
                              width: 120,
                              height: 75,
                              src: pageInfo.cover,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                pageInfo.episodeCountText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          if (pageInfo.seasonType != null)
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getSeasonTypeText(pageInfo.seasonType!),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // 信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              pageInfo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      if (first.ownerName != null)
                                        Text(
                                          first.ownerName!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                      // 显示包含的画质信息（仅当不使用三级结构时）
                                      if (!useThreeLevelStructure)
                                        ...pageInfo.entries
                                            .map((e) =>
                                                e.qualityPithyDescription)
                                            .toSet()
                                            .take(3)
                                            .map((quality) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 4,
                                                    vertical: 1,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme
                                                        .primaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                  child: Text(
                                                    quality,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: theme.colorScheme
                                                          .onPrimaryContainer,
                                                    ),
                                                  ),
                                                )),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 展开/收起图标
                                    Icon(
                                      pageInfo.isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      size: 20,
                                      color: theme.colorScheme.outline,
                                    ),
                                    first.moreBtn(theme),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (enableMultiSelect)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Checkbox(
                      value: pageInfo.checked ?? false,
                      onChanged: (_) => _controller.onSelect(pageInfo),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 展开的子项列表
        if (pageInfo.isExpanded && !enableMultiSelect)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Column(
              children: useThreeLevelStructure
                  ? pageInfo.episodes!
                      .map((episode) =>
                          _buildEpisodeItem(episode, theme, pageInfo))
                      .toList()
                  : pageInfo.entries
                      .map((entry) => _buildExpandedEntryItem(entry, theme))
                      .toList(),
            ),
          ),
      ],
    );
  }

  /// 构建选集项（二级）
  Widget _buildEpisodeItem(
    DownloadEpisodeInfo episode,
    ThemeData theme,
    DownloadPageInfo pageInfo,
  ) {
    final hasMultipleQualities = episode.entries.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (hasMultipleQualities) {
                // 有多个画质，切换展开状态
                _controller.toggleEpisodeExpanded(episode);
              } else {
                // 只有一个画质，直接播放
                _playVideo(episode.entries.first);
              }
            },
            onLongPress: () {
              if (hasMultipleQualities) {
                _showEpisodeOptions(episode, pageInfo);
              } else {
                _showExpandedEntryOptions(episode.entries.first);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // 选集标题
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode.episodeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          episode.qualityCountText,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 图标
                  if (hasMultipleQualities)
                    Icon(
                      episode.isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                      color: theme.colorScheme.outline,
                    )
                  else
                    Icon(
                      Icons.play_circle_outline,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
        // 展开的画质列表（三级）
        if (episode.isExpanded && hasMultipleQualities)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 0, bottom: 4),
            child: Column(
              children: episode.entries
                  .map((entry) => _buildQualityItem(entry, theme))
                  .toList(),
            ),
          ),
      ],
    );
  }

  /// 构建画质项（三级）
  Widget _buildQualityItem(
    DownloadEntryInfo entry,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _playVideo(entry),
        onLongPress: () => _showExpandedEntryOptions(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 画质标签
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.qualityPithyDescription,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 文件大小
              Expanded(
                child: Text(
                  entry.formattedFileSize,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              // 播放图标
              Icon(
                Icons.play_circle_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 播放视频
  void _playVideo(DownloadEntryInfo entry) {
    final heroTag =
        '${entry.bvid}_${entry.cid}_${DateTime.now().millisecondsSinceEpoch}';

    Get.toNamed(
      '/video',
      parameters: {
        'bvid': entry.bvid,
        'cid': entry.cid.toString(),
      },
      arguments: {
        'sourceType': 'file',
        'entry': entry,
        'dirPath': entry.entryDirPath,
        'heroTag': heroTag,
        'pic': entry.cover,
      },
    );
  }

  /// 显示选集操作选项
  void _showEpisodeOptions(
      DownloadEpisodeInfo episode, DownloadPageInfo pageInfo) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text('删除 ${episode.episodeTitle} 的所有画质'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(() async {
                    SmartDialog.showLoading(msg: '删除中...');
                    for (final entry in episode.entries) {
                      await _downloadService.deleteDownload(
                        entry: entry,
                        removeList: true,
                        refresh: false,
                      );
                    }
                    _downloadService.flagNotifier.refresh();
                    SmartDialog.dismiss();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建展开后的子项
  Widget _buildExpandedEntryItem(
    DownloadEntryInfo entry,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // 跳转到视频播放页 - 离线播放
          final heroTag =
              '${entry.bvid}_${entry.cid}_${DateTime.now().millisecondsSinceEpoch}';

          Get.toNamed(
            '/video',
            parameters: {
              'bvid': entry.bvid,
              'cid': entry.cid.toString(),
            },
            arguments: {
              'sourceType': 'file',
              'entry': entry,
              'dirPath': entry.entryDirPath,
              'heroTag': heroTag,
              'pic': entry.cover,
            },
          );
        },
        onLongPress: () {
          _showExpandedEntryOptions(entry);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // 画质标签
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.qualityPithyDescription,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.showTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        if (entry.ownerName != null) ...[
                          Flexible(
                            child: Text(
                              entry.ownerName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          entry.formattedFileSize,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 播放图标
              Icon(
                Icons.play_circle_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示展开项的操作选项
  void _showExpandedEntryOptions(DownloadEntryInfo entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text('删除 ${entry.qualityPithyDescription} 画质'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(() async {
                    await _downloadService.deleteDownload(
                      entry: entry,
                      removeList: true,
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('更新弹幕'),
                onTap: () async {
                  Navigator.pop(context);
                  SmartDialog.showLoading(msg: '更新中...');
                  final res = await _downloadService.downloadDanmaku(
                    entry: entry,
                    isUpdate: true,
                  );
                  SmartDialog.dismiss();
                  if (res) {
                    SmartDialog.showToast('更新成功');
                  } else {
                    SmartDialog.showToast('更新失败');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSeasonTypeText(int seasonType) {
    switch (seasonType) {
      case -1:
        return '课程';
      case 1:
        return '番剧';
      case 2:
        return '电影';
      case 3:
        return '纪录片';
      case 4:
        return '国创';
      case 5:
        return '电视剧';
      case 7:
        return '综艺';
      default:
        return '';
    }
  }

  void _showEntryOptions(DownloadEntryInfo entry, DownloadPageInfo pageInfo) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('删除'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(() async {
                    _downloadService.deleteDownload(
                      entry: entry,
                      removeList: true,
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('更新弹幕'),
                onTap: () async {
                  Navigator.pop(context);
                  SmartDialog.showLoading(msg: '更新中...');
                  final res = await _downloadService.downloadDanmaku(
                    entry: entry,
                    isUpdate: true,
                  );
                  SmartDialog.dismiss();
                  if (res) {
                    SmartDialog.showToast('更新成功');
                  } else {
                    SmartDialog.showToast('更新失败');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPageOptions(DownloadPageInfo pageInfo) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('删除'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(() async {
                    _downloadService.deletePage(
                      pageDirPath: pageInfo.dirPath,
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('更新弹幕'),
                onTap: () async {
                  Navigator.pop(context);
                  SmartDialog.showLoading(msg: '更新中...');
                  final res = await Future.wait(
                    pageInfo.entries.map(
                      (e) => _downloadService.downloadDanmaku(
                        entry: e,
                        isUpdate: true,
                      ),
                    ),
                  );
                  SmartDialog.dismiss();
                  if (res.every((e) => e)) {
                    SmartDialog.showToast('更新成功');
                  } else {
                    SmartDialog.showToast('更新失败');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(VoidCallback onConfirm) {
    Get.dialog(
      AlertDialog(
        title: const Text('确定删除？'),
        content: const Text('删除后将无法恢复'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              '取消',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 格式化字节大小
  String _formatBytes(int bytes) {
    if (bytes == 0) return '0B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)}${suffixes[i]}';
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无缓存内容',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在视频播放页面点击下载按钮开始缓存',
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
