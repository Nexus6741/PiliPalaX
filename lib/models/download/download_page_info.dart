import 'package:PiliPalaX/models/download/download_entry_info.dart';
import 'package:PiliPalaX/models/download/download_episode_info.dart';

/// 下载页面信息（用于分组显示）
class DownloadPageInfo {
  final String pageId;
  final String dirPath;
  final String title;
  String cover;
  int sortKey;
  final int? seasonType;
  final List<DownloadEntryInfo> entries;

  // 选集分组（按cid分组）
  List<DownloadEpisodeInfo>? episodes;

  // 多选状态
  bool? checked;

  // 展开状态
  bool isExpanded;

  DownloadPageInfo({
    required this.pageId,
    required this.dirPath,
    required this.title,
    required this.cover,
    required this.sortKey,
    this.seasonType,
    required this.entries,
    this.episodes,
    this.checked,
    this.isExpanded = false,
  });

  /// 是否有多个选集
  bool get hasMultipleEpisodes => (episodes?.length ?? 0) > 1;

  /// 获取选集数量文本
  String get episodeCountText {
    final count = episodes?.length ?? entries.length;
    if (count == 1) {
      // 单集：显示画质信息
      final qualityCount = episodes?.first.entries.length ?? entries.length;
      if (qualityCount == 1) {
        return entries.first.qualityPithyDescription;
      }
      return '$qualityCount个画质';
    }
    return '$count集';
  }
}
