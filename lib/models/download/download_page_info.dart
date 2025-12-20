import 'package:PiliPalaX/models/download/download_entry_info.dart';

/// 下载页面信息（用于分组显示）
class DownloadPageInfo {
  final String pageId;
  final String dirPath;
  final String title;
  String cover;
  int sortKey;
  final int? seasonType;
  final List<DownloadEntryInfo> entries;

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
    this.checked,
    this.isExpanded = false,
  });
}
