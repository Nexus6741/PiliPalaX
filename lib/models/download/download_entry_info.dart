import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 下载条目信息
class DownloadEntryInfo {
  int mediaType;
  final bool hasDashAudio;
  bool isCompleted;
  final RxInt totalBytes;
  final RxInt downloadedBytes;
  final String title;
  String? typeTag;
  final String cover;
  int? videoQuality;
  int preferedVideoQuality;
  String qualityPithyDescription;
  final int guessedTotalBytes;
  int totalTimeMilli;
  final int danmakuCount;
  final int timeUpdateStamp;
  final int timeCreateStamp;
  final bool canPlayInAdvance;
  bool interruptTransformTempFile;
  final int avid;
  final int? spid;
  final String bvid;
  final int? ownerId;
  final String? ownerName;
  PageInfo? pageData;
  final String? seasonId;
  final SourceInfo? source;
  EpInfo? ep;

  late String pageDirPath;
  late String entryDirPath;
  final Rx<DownloadStatus?> status;

  int get cid => source?.cid ?? pageData!.cid;

  String get pageId => seasonId ?? avid.toString();

  int get sortKey => ep?.sortIndex ?? pageData!.cid;

  String get showTitle {
    // 优先显示主标题，只有在主标题为空时才使用part
    if (title.isNotEmpty) {
      return title;
    }

    if (pageData != null) {
      final pd = pageData!;
      return pd.part?.isNotEmpty == true ? pd.part! : 'Unknown Video';
    }
    if (ep != null) {
      final e = ep!;
      return e.showTitle ?? '${e.index} ${e.indexTitle}';
    }
    return 'Unknown Video';
  }

  /// 获取格式化的文件大小
  String get formattedFileSize {
    final bytes = totalBytes.value;
    if (bytes == 0) return '未知大小';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(i == 0 ? 0 : 1)}${suffixes[i]}';
  }

  Widget moreBtn(ThemeData theme) => SizedBox(
        width: 29,
        height: 29,
        child: PopupMenuButton(
          padding: EdgeInsets.zero,
          position: PopupMenuPosition.under,
          icon: Icon(
            Icons.more_vert_outlined,
            color: theme.colorScheme.outline,
            size: 18,
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              height: 35,
              child: const Text(
                '查看详情页',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () {
                if (ep != null) {
                  final e = ep!;
                  Get.toNamed(
                    '/video?bvid=$bvid&cid=$cid',
                    parameters: {
                      'seasonId': seasonId ?? '',
                      'epId': e.episodeId.toString(),
                    },
                  );
                  return;
                }
                Get.toNamed(
                  '/video',
                  parameters: {
                    'bvid': bvid,
                    'cid': cid.toString(),
                  },
                );
              },
            ),
            if (ownerId != null)
              PopupMenuItem(
                height: 35,
                child: Text(
                  '访问${ownerName != null ? '：$ownerName' : '用户主页'}',
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
                onTap: () => Get.toNamed('/member?mid=$ownerId'),
              ),
          ],
        ),
      );

  DownloadEntryInfo({
    this.mediaType = 1,
    this.hasDashAudio = false,
    required this.isCompleted,
    required int totalBytes,
    required int downloadedBytes,
    required this.title,
    this.typeTag,
    required this.cover,
    this.videoQuality,
    required this.preferedVideoQuality,
    this.qualityPithyDescription = '',
    required this.guessedTotalBytes,
    required this.totalTimeMilli,
    required this.danmakuCount,
    this.timeUpdateStamp = 0,
    this.timeCreateStamp = 0,
    this.canPlayInAdvance = false,
    this.interruptTransformTempFile = false,
    required this.avid,
    this.spid,
    required this.bvid,
    this.ownerId,
    this.ownerName,
    this.pageData,
    this.seasonId,
    this.source,
    this.ep,
    DownloadStatus? status,
  })  : totalBytes = RxInt(totalBytes),
        downloadedBytes = RxInt(downloadedBytes),
        status = Rx<DownloadStatus?>(status);

  factory DownloadEntryInfo.fromJson(Map<String, dynamic> json) =>
      DownloadEntryInfo(
        mediaType: json['media_type'] as int,
        hasDashAudio: json['has_dash_audio'] as bool,
        isCompleted: json['is_completed'] as bool,
        totalBytes: json['total_bytes'] as int,
        downloadedBytes: json['downloaded_bytes'] as int,
        title: json['title'] as String,
        typeTag: json['type_tag'] as String?,
        cover: json['cover'] as String,
        videoQuality: json['video_quality'] as int?,
        preferedVideoQuality: json['prefered_video_quality'] as int,
        qualityPithyDescription: json['quality_pithy_description'] as String,
        guessedTotalBytes: json['guessed_total_bytes'] as int,
        totalTimeMilli: json['total_time_milli'] as int,
        danmakuCount: json['danmaku_count'] as int,
        timeUpdateStamp: json['time_update_stamp'] as int,
        timeCreateStamp: json['time_create_stamp'] as int,
        canPlayInAdvance: json['can_play_in_advance'] as bool,
        interruptTransformTempFile:
            json['interrupt_transform_temp_file'] as bool,
        avid: json['avid'] as int,
        spid: json['spid'] as int?,
        bvid: json['bvid'] as String,
        ownerId: json['owner_id'] as int?,
        ownerName: json['owner_name'] as String?,
        pageData: json['page_data'] != null
            ? PageInfo.fromJson(json['page_data'] as Map<String, dynamic>)
            : null,
        seasonId: json['season_id'] as String?,
        source: json['source'] != null
            ? SourceInfo.fromJson(json['source'] as Map<String, dynamic>)
            : null,
        ep: json['ep'] != null
            ? EpInfo.fromJson(json['ep'] as Map<String, dynamic>)
            : null,
        status: null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'media_type': mediaType,
        'has_dash_audio': hasDashAudio,
        'is_completed': isCompleted,
        'total_bytes': totalBytes.value,
        'downloaded_bytes': downloadedBytes.value,
        'title': title,
        'type_tag': typeTag,
        'cover': cover,
        'video_quality': videoQuality,
        'prefered_video_quality': preferedVideoQuality,
        'quality_pithy_description': qualityPithyDescription,
        'guessed_total_bytes': guessedTotalBytes,
        'total_time_milli': totalTimeMilli,
        'danmaku_count': danmakuCount,
        'time_update_stamp': timeUpdateStamp,
        'time_create_stamp': timeCreateStamp,
        'can_play_in_advance': canPlayInAdvance,
        'interrupt_transform_temp_file': interruptTransformTempFile,
        'avid': avid,
        'spid': spid,
        'bvid': bvid,
        'owner_id': ownerId,
        'owner_name': ownerName,
        'page_data': pageData?.toJson(),
        'season_id': seasonId,
        'source': source?.toJson(),
        'ep': ep?.toJson(),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is DownloadEntryInfo) {
      return cid == other.cid &&
          preferedVideoQuality == other.preferedVideoQuality;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(cid, preferedVideoQuality);
}

/// 分P信息
class PageInfo {
  final int cid;
  final int page;
  final String? from;
  final String? part;
  final String? vid;
  final bool hasAlias;
  final int tid;
  int width;
  int height;
  final int rotate;
  final String? downloadTitle;
  final String? downloadSubtitle;

  PageInfo({
    required this.cid,
    required this.page,
    this.from,
    this.part,
    this.vid,
    required this.hasAlias,
    required this.tid,
    this.width = 0,
    this.height = 0,
    this.rotate = 0,
    this.downloadTitle,
    this.downloadSubtitle,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) => PageInfo(
        cid: json['cid'] as int,
        page: json['page'] as int,
        from: json['from'] as String?,
        part: json['part'] as String?,
        vid: json['vid'] as String?,
        hasAlias: json['has_alias'] as bool,
        tid: json['tid'] as int,
        width: json['width'] as int,
        height: json['height'] as int,
        rotate: json['rotate'] as int,
        downloadTitle: json['download_title'] as String?,
        downloadSubtitle: json['download_subtitle'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cid': cid,
        'page': page,
        'from': from,
        'part': part,
        'vid': vid,
        'has_alias': hasAlias,
        'tid': tid,
        'width': width,
        'height': height,
        'rotate': rotate,
        'download_title': downloadTitle,
        'download_subtitle': downloadSubtitle,
      };
}

/// 源信息
class SourceInfo {
  final int avId;
  final int cid;

  SourceInfo({
    required this.avId,
    required this.cid,
  });

  factory SourceInfo.fromJson(Map<String, dynamic> json) => SourceInfo(
        avId: json['av_id'] as int,
        cid: json['cid'] as int,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'av_id': avId,
        'cid': cid,
      };
}

/// 剧集信息
class EpInfo {
  final int avId;
  final int page;
  final int danmaku;
  final String cover;
  final int episodeId;
  final String index;
  final String indexTitle;
  final String? showTitle;
  final String from;
  final int seasonType;
  int width;
  int height;
  final int rotate;
  final String link;
  final String bvid;
  final int sortIndex;

  EpInfo({
    required this.avId,
    required this.page,
    required this.danmaku,
    required this.cover,
    required this.episodeId,
    required this.index,
    required this.indexTitle,
    this.showTitle,
    required this.from,
    required this.seasonType,
    required this.width,
    required this.height,
    required this.rotate,
    this.link = '',
    this.bvid = '',
    this.sortIndex = 0,
  });

  factory EpInfo.fromJson(Map<String, dynamic> json) => EpInfo(
        avId: json['av_id'] as int,
        page: json['page'] as int,
        danmaku: json['danmaku'] as int,
        cover: json['cover'] as String,
        episodeId: json['episode_id'] as int,
        index: json['index'] as String,
        indexTitle: json['index_title'] as String,
        showTitle: json['show_title'] as String?,
        from: json['from'] as String,
        seasonType: json['season_type'] as int,
        width: json['width'] as int,
        height: json['height'] as int,
        rotate: json['rotate'] as int,
        link: json['link'] as String,
        bvid: json['bvid'] as String,
        sortIndex: json['sort_index'] as int,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'av_id': avId,
        'page': page,
        'danmaku': danmaku,
        'cover': cover,
        'episode_id': episodeId,
        'index': index,
        'index_title': indexTitle,
        'show_title': showTitle,
        'from': from,
        'season_type': seasonType,
        'width': width,
        'height': height,
        'rotate': rotate,
        'link': link,
        'bvid': bvid,
        'sort_index': sortIndex,
      };
}

/// 下载状态
enum DownloadStatus {
  downloading('正在下载'),
  audioDownloading('正在下载音频'),
  getDanmaku('获取弹幕'),
  getPlayUrl('获取播放地址'),
  //
  completed('下载完成'),
  failDownload('下载失败'),
  failDownloadAudio('音频下载失败'),
  failDanmaku('获取弹幕失败'),
  failPlayUrl('获取播放地址失败'),
  pause('暂停中'),
  wait('等待中');

  final String message;
  const DownloadStatus(this.message);
}
