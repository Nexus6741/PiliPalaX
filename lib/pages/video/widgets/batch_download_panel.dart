import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/models/download/download_entry_info.dart';
import 'package:PiliPalaX/models/video/play/quality.dart';
import 'package:PiliPalaX/services/download_service.dart';

/// 批量下载面板 - 用于选集视频和番剧
class BatchDownloadPanel extends StatefulWidget {
  final List<BatchDownloadItem> episodes;
  final String title;
  final String cover;
  final int? ownerId;
  final String? ownerName;
  final String? seasonId;
  final int? seasonType;

  const BatchDownloadPanel({
    super.key,
    required this.episodes,
    required this.title,
    required this.cover,
    this.ownerId,
    this.ownerName,
    this.seasonId,
    this.seasonType,
  });

  @override
  State<BatchDownloadPanel> createState() => _BatchDownloadPanelState();
}

class _BatchDownloadPanelState extends State<BatchDownloadPanel> {
  final Map<int, bool> _selectedEpisodes = {};
  VideoQuality? _selectedQuality;
  bool _isAllSelected = false;
  bool _isQualitySectionExpanded = true; // 画质区域是否展开
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 默认不选中任何集
    for (var episode in widget.episodes) {
      _selectedEpisodes[episode.index] = false;
    }

    // 监听滚动事件
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 当用户向下滚动时，收起画质选择区域
    if (_scrollController.offset > 10 && _isQualitySectionExpanded) {
      setState(() {
        _isQualitySectionExpanded = false;
      });
    }
    // 当滚动到顶部时，展开画质选择区域
    else if (_scrollController.offset <= 0 && !_isQualitySectionExpanded) {
      setState(() {
        _isQualitySectionExpanded = true;
      });
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _isAllSelected = !_isAllSelected;
      for (var episode in widget.episodes) {
        _selectedEpisodes[episode.index] = _isAllSelected;
      }
    });
  }

  void _toggleEpisode(int index) {
    setState(() {
      _selectedEpisodes[index] = !(_selectedEpisodes[index] ?? false);
      // 检查是否全选
      _isAllSelected = _selectedEpisodes.values.every((selected) => selected);
    });
  }

  int get _selectedCount =>
      _selectedEpisodes.values.where((selected) => selected).length;

  Future<void> _startBatchDownload() async {
    if (_selectedQuality == null) {
      SmartDialog.showToast('请先选择画质');
      return;
    }

    final selectedEpisodes = widget.episodes
        .where((episode) => _selectedEpisodes[episode.index] == true)
        .toList();

    if (selectedEpisodes.isEmpty) {
      SmartDialog.showToast('请至少选择一集');
      return;
    }

    Get.back();
    SmartDialog.showLoading(msg: '添加到下载队列...');

    final downloadService = Get.find<DownloadService>();

    for (var episode in selectedEpisodes) {
      await episode.download(
        downloadService,
        _selectedQuality!,
        widget.title,
        widget.cover,
        widget.ownerId,
        widget.ownerName,
        widget.seasonId,
        widget.seasonType,
      );
    }

    SmartDialog.dismiss();
    SmartDialog.showToast('已添加 ${selectedEpisodes.length} 集到下载队列');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '批量下载',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 画质选择 - 可折叠
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isQualitySectionExpanded
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '选择画质',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: VideoQuality.values.map((quality) {
                            final isSelected = _selectedQuality == quality;
                            return ChoiceChip(
                              label: Text(quality.description),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedQuality = selected ? quality : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // 画质选择收起时的提示栏
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !_isQualitySectionExpanded
                ? InkWell(
                    onTap: () {
                      setState(() {
                        _isQualitySectionExpanded = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Row(
                        children: [
                          Icon(
                            Icons.high_quality,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedQuality != null
                                  ? '已选择: ${_selectedQuality!.description}'
                                  : '点击选择画质',
                              style: TextStyle(
                                color: _selectedQuality != null
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.error,
                                fontWeight: _selectedQuality != null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.expand_more,
                            size: 20,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          // 全选按钮
          ListTile(
            leading: Checkbox(
              value: _isAllSelected,
              onChanged: (_) => _toggleSelectAll(),
            ),
            title: Text('全选 (共 ${widget.episodes.length} 集)'),
            trailing: Text(
              '已选 $_selectedCount 集',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: _toggleSelectAll,
          ),
          const Divider(height: 1),
          // 选集列表
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: widget.episodes.length,
              itemBuilder: (context, index) {
                final episode = widget.episodes[index];
                final isSelected = _selectedEpisodes[episode.index] ?? false;

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => _toggleEpisode(episode.index),
                  title: Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: episode.subtitle != null
                      ? Text(
                          episode.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        )
                      : null,
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${episode.index}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 底部按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _startBatchDownload,
                    child: Text('开始下载 ($_selectedCount)'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 批量下载项
class BatchDownloadItem {
  final int index; // 集数序号
  final String title; // 标题
  final String? subtitle; // 副标题
  final int cid;
  final String bvid;
  final int aid;
  final int duration;
  final String? cover;
  final int? danmakuCount;
  final int page;
  final String? part;

  // 番剧特有字段
  final int? episodeId;
  final String? longTitle;

  BatchDownloadItem({
    required this.index,
    required this.title,
    this.subtitle,
    required this.cid,
    required this.bvid,
    required this.aid,
    required this.duration,
    this.cover,
    this.danmakuCount,
    required this.page,
    this.part,
    this.episodeId,
    this.longTitle,
  });

  /// 执行下载
  Future<void> download(
    DownloadService downloadService,
    VideoQuality quality,
    String videoTitle,
    String videoCover,
    int? ownerId,
    String? ownerName,
    String? seasonId,
    int? seasonType,
  ) async {
    // 如果是番剧，构建EpInfo
    EpInfo? epInfo;
    if (seasonId != null && episodeId != null) {
      epInfo = EpInfo(
        avId: aid,
        page: page,
        danmaku: danmakuCount ?? 0,
        cover: cover ?? '',
        episodeId: episodeId!,
        index: title,
        indexTitle: longTitle ?? subtitle ?? '',
        showTitle: longTitle,
        from: 'bangumi',
        seasonType: seasonType ?? 1,
        width: 0,
        height: 0,
        rotate: 0,
        link: '',
        bvid: bvid,
        sortIndex: episodeId!,
      );
    }

    downloadService.downloadVideo(
      cid: cid,
      page: page,
      bvid: bvid,
      aid: aid,
      part: part ?? longTitle ?? subtitle,
      title: videoTitle,
      cover: cover ?? videoCover,
      duration: duration,
      danmakuCount: danmakuCount,
      ownerId: ownerId,
      ownerName: ownerName,
      videoQuality: quality,
      seasonId: seasonId,
      epInfo: epInfo,
    );
  }
}
