import 'package:PiliPalaX/models/download/download_entry_info.dart';

/// 下载选集信息（用于按cid分组）
class DownloadEpisodeInfo {
  final int cid;
  final String title;
  final String cover;
  final int sortKey;
  final List<DownloadEntryInfo> entries;

  // 展开状态
  bool isExpanded;

  DownloadEpisodeInfo({
    required this.cid,
    required this.title,
    required this.cover,
    required this.sortKey,
    required this.entries,
    this.isExpanded = false,
  });

  /// 获取选集标题（显示集数信息）
  String get episodeTitle {
    final entry = entries.first;

    // 番剧：显示集数
    if (entry.ep != null) {
      final ep = entry.ep!;
      return ep.index.isNotEmpty ? '第${ep.index}集' : ep.indexTitle;
    }

    // 普通视频：显示分P标题
    if (entry.pageData != null) {
      final page = entry.pageData!;
      if (page.part != null && page.part!.isNotEmpty) {
        return 'P${page.page} ${page.part}';
      }
      return 'P${page.page}';
    }

    return title;
  }

  /// 获取画质数量文本
  String get qualityCountText {
    if (entries.length == 1) {
      return entries.first.qualityPithyDescription;
    }
    return '${entries.length}个画质';
  }
}
