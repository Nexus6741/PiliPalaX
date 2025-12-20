import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show Directory, File;

import 'package:PiliPalaX/http/danmaku.dart';
import 'package:PiliPalaX/http/init.dart';
import 'package:PiliPalaX/http/video.dart';
import 'package:PiliPalaX/models/download/download_entry_info.dart';
import 'package:PiliPalaX/models/download/download_media_info.dart';
import 'package:PiliPalaX/models/video/play/quality.dart';
import 'package:PiliPalaX/models/video/play/url.dart';
import 'package:PiliPalaX/services/download_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

/// 下载服务
class DownloadService extends GetxService {
  static const _entryFile = 'entry.json';
  static const _indexFile = 'index.json';
  static const _danmakuFile = 'danmaku.pb';
  static const _coverFile = 'cover.jpg';
  static const _videoNameType1 = 'video.flv';
  static const _audioNameType2 = 'audio.m4s';
  static const _videoNameType2 = 'video.m4s';

  final _lock = Lock();

  final flagNotifier = <void Function()>{};
  final waitDownloadQueue = RxList<DownloadEntryInfo>();
  final downloadList = <DownloadEntryInfo>[];

  // 单个下载管理
  DownloadManager? videoManager;
  DownloadManager? audioManager;

  int? _curCid;
  int? get curCid => _curCid;
  final curDownload = Rxn<DownloadEntryInfo>();

  void _updateCurStatus(DownloadStatus status) {
    if (curDownload.value != null) {
      curDownload.value!.status.value = status;
    }
  }

  late Future<void> waitForInitialization;

  @override
  void onInit() {
    super.onInit();
    initDownloadList();
  }

  void initDownloadList() {
    waitForInitialization = _readDownloadList();
  }

  Future<void> _readDownloadList() async {
    downloadList.clear();
    final downloadDir = Directory(await _getDownloadPath());
    if (!downloadDir.existsSync()) {
      return;
    }

    await for (final dir in downloadDir.list()) {
      if (dir is Directory) {
        downloadList.addAll(await _readDownloadDirectory(dir));
      }
    }
    downloadList.sort((a, b) => b.timeUpdateStamp.compareTo(a.timeUpdateStamp));
  }

  Future<List<DownloadEntryInfo>> _readDownloadDirectory(
    Directory pageDir,
  ) async {
    final result = <DownloadEntryInfo>[];

    if (!pageDir.existsSync()) {
      return result;
    }

    await for (final entryDir in pageDir.list()) {
      if (entryDir is Directory) {
        final entryFile = File(path.join(entryDir.path, _entryFile));
        if (entryFile.existsSync()) {
          try {
            final entryJson = await entryFile.readAsString();
            final entry = DownloadEntryInfo.fromJson(jsonDecode(entryJson))
              ..pageDirPath = pageDir.path
              ..entryDirPath = entryDir.path;

            if (kDebugMode) {
              debugPrint(
                  '读取条目 ${entry.cid}: downloaded=${entry.downloadedBytes.value}, total=${entry.totalBytes.value}, completed=${entry.isCompleted}');
            }

            if (entry.isCompleted) {
              result.add(entry);
            } else {
              entry.status.value = DownloadStatus.wait;
              waitDownloadQueue.add(entry);
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('读取条目失败: $e');
            }
          }
        }
      }
    }

    return result;
  }

  /// 下载视频
  void downloadVideo({
    required int cid,
    required int page,
    required String bvid,
    required int aid,
    String? part,
    required String title,
    required String cover,
    required int duration,
    int? danmakuCount,
    int? ownerId,
    String? ownerName,
    required VideoQuality videoQuality,
    // 番剧相关参数
    String? seasonId,
    EpInfo? epInfo,
  }) {
    // 检查是否已经下载了相同画质的视频
    if (downloadList.indexWhere((e) =>
            e.cid == cid && e.preferedVideoQuality == videoQuality.code) !=
        -1) {
      SmartDialog.showToast('该画质视频已在下载列表中');
      return;
    }
    if (waitDownloadQueue.indexWhere((e) =>
            e.cid == cid && e.preferedVideoQuality == videoQuality.code) !=
        -1) {
      SmartDialog.showToast('该画质视频已在等待队列中');
      return;
    }

    final pageData = PageInfo(
      cid: cid,
      page: page,
      from: 'local',
      part: part,
      vid: null,
      hasAlias: false,
      tid: 0,
      width: 0,
      height: 0,
      rotate: 0,
      downloadTitle: '视频已缓存完成',
      downloadSubtitle: title,
    );

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final entry = DownloadEntryInfo(
      mediaType: 2,
      hasDashAudio: true,
      isCompleted: false,
      totalBytes: 0,
      downloadedBytes: 0,
      title: title,
      typeTag: videoQuality.code.toString(),
      cover: cover.startsWith('http') ? cover : 'https:$cover',
      preferedVideoQuality: videoQuality.code,
      qualityPithyDescription: videoQuality.description,
      guessedTotalBytes: 0,
      totalTimeMilli: duration * 1000,
      danmakuCount: danmakuCount ?? 0,
      timeUpdateStamp: currentTime,
      timeCreateStamp: currentTime,
      canPlayInAdvance: true,
      interruptTransformTempFile: false,
      avid: aid,
      spid: 0,
      seasonId: seasonId,
      ep: epInfo,
      source: null,
      bvid: bvid,
      ownerId: ownerId,
      ownerName: ownerName,
      pageData: pageData,
    );
    _createDownload(entry);
  }

  Future<void> _createDownload(DownloadEntryInfo entry) async {
    final entryDir = await _getDownloadEntryDir(entry);
    final entryJsonFile = File(path.join(entryDir.path, _entryFile));
    await entryJsonFile.writeAsString(jsonEncode(entry.toJson()));
    entry
      ..pageDirPath = entryDir.parent.path
      ..entryDirPath = entryDir.path;
    entry.status.value = DownloadStatus.wait;
    waitDownloadQueue.add(entry);
    final currStatus = curDownload.value?.status.value?.index;
    if (currStatus == null || currStatus > 3) {
      startDownload();
    }
  }

  Future<Directory> _getDownloadEntryDir(DownloadEntryInfo entry) async {
    late final String dirName;
    late final String pageDirName;
    if (entry.ep != null) {
      final ep = entry.ep!;
      dirName = 's_${entry.seasonId}';
      pageDirName = '${ep.episodeId}_${entry.preferedVideoQuality}';
    } else if (entry.pageData != null) {
      final page = entry.pageData!;
      dirName = entry.avid.toString();
      pageDirName = 'c_${page.cid}_${entry.preferedVideoQuality}';
    } else {
      throw Exception('Invalid entry: no ep or pageData');
    }

    final pageDir = Directory(
      path.join(await _getDownloadPath(), dirName, pageDirName),
    );
    if (!pageDir.existsSync()) {
      await pageDir.create(recursive: true);
    }
    return pageDir;
  }

  static Future<String> _getDownloadPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(appDir.path, 'downloads'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<void> startDownload() {
    return _lock.synchronized(() async {
      if (waitDownloadQueue.isEmpty) {
        return;
      }
      if (curDownload.value != null) {
        return;
      }

      // 查找第一个未暂停的视频
      final entry = waitDownloadQueue.firstWhereOrNull(
        (e) => e.status.value != DownloadStatus.pause,
      );

      if (entry == null) {
        // 队列中都是暂停的视频
        return;
      }

      _curCid = entry.cid;
      curDownload.value = entry;

      // _startDownload 内部会处理异常和启动下一个下载
      await _startDownload(entry);
    });
  }

  /// 下载弹幕
  Future<bool> downloadDanmaku({
    required DownloadEntryInfo entry,
    bool isUpdate = false,
  }) async {
    final cid = entry.pageData?.cid ?? entry.source?.cid;
    if (cid == null) {
      return false;
    }
    final danmakuFile = File(
      path.join(entry.entryDirPath, _danmakuFile),
    );
    if (isUpdate || !danmakuFile.existsSync()) {
      try {
        if (!isUpdate) {
          _updateCurStatus(DownloadStatus.getDanmaku);
        }

        // 获取弹幕
        final result = await DanmakaHttp.queryDanmaku(
          cid: cid,
          segmentIndex: 1,
        );
        if (result.elems.isNotEmpty) {
          await danmakuFile.writeAsBytes(result.writeToBuffer());
          return true;
        }
        return false;
      } catch (e) {
        if (!isUpdate) {
          _updateCurStatus(DownloadStatus.failDanmaku);
        }
        if (kDebugMode) SmartDialog.showToast(e.toString());
        return false;
      }
    }
    return true;
  }

  /// 下载封面
  Future<bool> _downloadCover({
    required DownloadEntryInfo entry,
  }) async {
    try {
      final filePath = path.join(entry.entryDirPath, _coverFile);
      if (File(filePath).existsSync()) {
        return true;
      }
      final file = (await DefaultCacheManager().getFileFromCache(
        entry.cover,
      ))
          ?.file;
      if (file != null) {
        await file.copy(filePath);
      } else {
        await Request.dio.download(entry.cover, filePath);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startDownload(DownloadEntryInfo entry) async {
    try {
      if (!await downloadDanmaku(entry: entry)) {
        // 弹幕下载失败，但继续下载视频
        if (kDebugMode) {
          debugPrint('Failed to download danmaku, but continue with video');
        }
      }

      _updateCurStatus(DownloadStatus.getPlayUrl);

      final DownloadMediaInfo mediaFileInfo = await _getVideoUrl(entry: entry);

      final videoDir = Directory(path.join(entry.entryDirPath, entry.typeTag!));
      if (!videoDir.existsSync()) {
        await videoDir.create(recursive: true);
      }

      final mediaJsonFile = File(path.join(videoDir.path, _indexFile));
      await Future.wait([
        mediaJsonFile.writeAsString(jsonEncode(mediaFileInfo.toJson())),
        _downloadCover(entry: entry),
      ]);

      if (mediaFileInfo is Type1MediaInfo) {
        final first = mediaFileInfo.segmentList.first;
        videoManager = DownloadManager(
          url: first.url,
          path: path.join(videoDir.path, _videoNameType1),
          onReceiveProgress: _onReceive,
          onDone: _onDone,
        );
      } else if (mediaFileInfo is Type2MediaInfo) {
        videoManager = DownloadManager(
          url: mediaFileInfo.video.first.baseUrl,
          path: path.join(videoDir.path, _videoNameType2),
          onReceiveProgress: _onReceive,
          onDone: _onDone,
        );
        final audio = mediaFileInfo.audio;
        if (audio != null && audio.isNotEmpty) {
          audioManager = DownloadManager(
            url: audio.first.baseUrl,
            path: path.join(videoDir.path, _audioNameType2),
            onReceiveProgress: null,
            onDone: _onAudioDone,
          );
        }
        final first = mediaFileInfo.video.first;
        if (entry.pageData != null) {
          entry.pageData!
            ..width = first.width
            ..height = first.height;
        }
        if (entry.ep != null) {
          entry.ep!
            ..width = first.width
            ..height = first.height;
        }
        _updateBiliDownloadEntryJson(entry);
      }
    } catch (e) {
      _updateCurStatus(DownloadStatus.failPlayUrl);
      if (kDebugMode) {
        debugPrint('get download url error: $e');
      }
      // 失败后从队列移除并启动下一个
      waitDownloadQueue.remove(entry);
      _curCid = null;
      curDownload.value = null;
      videoManager = null;
      audioManager = null;
      // 启动下一个下载
      startDownload();
    }
  }

  Future<void> _updateBiliDownloadEntryJson(DownloadEntryInfo entry) async {
    final entryJsonFile = File(path.join(entry.entryDirPath, _entryFile));
    await entryJsonFile.writeAsString(jsonEncode(entry.toJson()));
  }

  Timer? _progressSaveTimer;
  int _lastSavedProgress = 0;

  void _onReceive(int progress, int total) {
    final entry = curDownload.value;
    if (entry != null) {
      // 更新总大小
      if (total != 0 && entry.totalBytes.value != total) {
        entry.totalBytes.value = total;
        // 异步保存，但不阻塞进度更新
        _updateBiliDownloadEntryJson(entry);
      }

      // 更新已下载大小
      entry.downloadedBytes.value = progress;
      entry.status.value = DownloadStatus.downloading;

      // 每隔5秒或进度变化超过5MB时保存一次进度
      final progressDiff = (progress - _lastSavedProgress).abs();
      if (progressDiff > 5 * 1024 * 1024) {
        _lastSavedProgress = progress;
        // 异步保存，但不阻塞进度更新
        _updateBiliDownloadEntryJson(entry);
      } else {
        // 使用定时器延迟保存，避免频繁写入
        _progressSaveTimer?.cancel();
        _progressSaveTimer = Timer(const Duration(seconds: 5), () {
          _lastSavedProgress = progress;
          _updateBiliDownloadEntryJson(entry);
        });
      }

      // 强制刷新UI
      waitDownloadQueue.refresh();
    }
  }

  void _onDone([Object? error]) {
    final entry = curDownload.value;
    if (entry == null) return;

    // 取消进度保存定时器
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    _lastSavedProgress = 0;

    if (error != null) {
      entry.status.value = videoManager?.status ?? DownloadStatus.pause;
      // 如果是暂停，保留在队列中；如果是失败，从队列中移除
      if (entry.status.value != DownloadStatus.pause) {
        waitDownloadQueue.remove(entry);
        // 清理状态
        _curCid = null;
        curDownload.value = null;
        videoManager = null;
        audioManager = null;
        // 启动下一个下载
        startDownload();
      } else {
        // 暂停时立即保存进度
        _updateBiliDownloadEntryJson(entry);
      }
      return;
    }

    final status = audioManager?.status == DownloadStatus.downloading
        ? DownloadStatus.audioDownloading
        : audioManager?.status == DownloadStatus.failDownload
            ? DownloadStatus.failDownloadAudio
            : videoManager?.status ?? DownloadStatus.pause;
    entry.status.value = status;

    entry.downloadedBytes.value = entry.totalBytes.value;
    if (status == DownloadStatus.completed) {
      _completeDownload();
    } else {
      _updateBiliDownloadEntryJson(entry);
      // 如果失败，从队列中移除
      if (status == DownloadStatus.failDownload ||
          status == DownloadStatus.failDownloadAudio) {
        waitDownloadQueue.remove(entry);
        // 清理状态
        _curCid = null;
        curDownload.value = null;
        videoManager = null;
        audioManager = null;
        // 启动下一个下载
        startDownload();
      }
    }
  }

  void _onAudioDone([Object? error]) {
    if (videoManager?.status == DownloadStatus.completed) {
      if (error == null) {
        _completeDownload();
      } else {
        final status = audioManager?.status ?? DownloadStatus.pause;
        curDownload.value?.status.value = status == DownloadStatus.failDownload
            ? DownloadStatus.failDownloadAudio
            : status;
      }
    }
  }

  Future<void> _completeDownload() async {
    final entry = curDownload.value;
    if (entry == null) return;

    // 取消进度保存定时器
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    _lastSavedProgress = 0;

    entry.downloadedBytes.value = entry.totalBytes.value;
    entry.isCompleted = true;
    await _updateBiliDownloadEntryJson(entry);

    // 从等待队列中移除已完成的项
    waitDownloadQueue.remove(entry);
    // 添加到已完成列表
    downloadList.insert(0, entry);
    flagNotifier.refresh();

    _curCid = null;
    curDownload.value = null;
    videoManager = null;
    audioManager = null;

    // 启动下一个下载
    startDownload();
  }

  void nextDownload() {
    startDownload();
  }

  Future<void> deleteDownload({
    required DownloadEntryInfo entry,
    bool removeList = false,
    bool removeQueue = false,
    bool refresh = true,
    bool downloadNext = true,
  }) async {
    if (removeList) {
      downloadList.remove(entry);
    }
    if (removeQueue) {
      waitDownloadQueue.remove(entry);
    }
    if (curDownload.value?.cid == entry.cid) {
      await cancelDownload(isDelete: true);
    }
    final downloadDir = Directory(entry.pageDirPath);
    if (downloadDir.existsSync()) {
      final list = await downloadDir.list().toList();
      if (list.length < 2) {
        try {
          await downloadDir.delete(recursive: true);
        } catch (_) {}
      } else {
        final entryDir = Directory(entry.entryDirPath);
        if (entryDir.existsSync()) {
          try {
            await entryDir.delete(recursive: true);
          } catch (_) {}
        }
      }
    }
    if (refresh) {
      flagNotifier.refresh();
    }
  }

  Future<void> deletePage({
    required String pageDirPath,
    bool refresh = true,
  }) async {
    try {
      await Directory(pageDirPath).delete(recursive: true);
    } catch (_) {}
    downloadList.removeWhere((e) => e.pageDirPath == pageDirPath);
    if (refresh) {
      flagNotifier.refresh();
    }
  }

  Future<void> cancelDownload({
    required bool isDelete,
    bool downloadNext = true,
  }) async {
    // 取消进度保存定时器
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    _lastSavedProgress = 0;

    if (!isDelete && videoManager?.status == DownloadStatus.downloading) {
      curDownload.value?.status.value = DownloadStatus.pause;
    }
    await videoManager?.cancel(isDelete: isDelete);
    await audioManager?.cancel(isDelete: isDelete);

    final entry = curDownload.value;
    if (entry != null) {
      if (!isDelete) {
        // 暂停时立即保存当前进度
        await _updateBiliDownloadEntryJson(entry);
        entry.status.value = DownloadStatus.pause;

        if (kDebugMode) {
          debugPrint(
              '保存暂停进度 ${entry.cid}: ${entry.downloadedBytes.value}/${entry.totalBytes.value}');
        }

        // 暂停时保持在队列中，不需要重新插入
      } else {
        // 删除操作：从队列中移除并删除本地文件
        waitDownloadQueue.remove(entry);
        await _deleteDownloadFiles(entry);
      }
    }

    _curCid = null;
    curDownload.value = null;
    videoManager = null;
    audioManager = null;

    // 强制刷新队列UI
    waitDownloadQueue.refresh();

    if (downloadNext) {
      startDownload();
    }
  }

  /// 删除下载相关的本地文件
  Future<void> _deleteDownloadFiles(DownloadEntryInfo entry) async {
    try {
      final entryDir = Directory(entry.entryDirPath);
      if (entryDir.existsSync()) {
        await entryDir.delete(recursive: true);
      }

      // 检查父目录是否为空，如果为空也删除
      final pageDir = Directory(entry.pageDirPath);
      if (pageDir.existsSync()) {
        final list = await pageDir.list().toList();
        if (list.isEmpty) {
          await pageDir.delete(recursive: true);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete download files: $e');
      }
    }
  }

  /// 清空等待队列中的所有下载
  Future<void> clearWaitingQueue() async {
    // 先取消当前下载
    if (curDownload.value != null) {
      await cancelDownload(isDelete: true, downloadNext: false);
    }

    final entries = List<DownloadEntryInfo>.from(waitDownloadQueue);
    waitDownloadQueue.clear();

    // 删除所有等待中的下载文件
    for (final entry in entries) {
      await _deleteDownloadFiles(entry);
    }

    flagNotifier.refresh();
  }

  /// 跳过当前下载，继续下一个
  Future<void> skipCurrentDownload() async {
    return _lock.synchronized(() async {
      final entry = curDownload.value;
      if (entry == null) return;

      // 取消进度保存定时器
      _progressSaveTimer?.cancel();
      _progressSaveTimer = null;
      _lastSavedProgress = 0;

      // 取消当前下载
      await videoManager?.cancel(isDelete: false);
      await audioManager?.cancel(isDelete: false);

      // 标记为暂停状态并立即保存进度
      entry.status.value = DownloadStatus.pause;
      await _updateBiliDownloadEntryJson(entry);

      // 清理状态
      _curCid = null;
      curDownload.value = null;
      videoManager = null;
      audioManager = null;

      // 启动下一个下载（跳过暂停的）
      _startNextDownload();
    });
  }

  /// 启动下一个未暂停的下载
  void _startNextDownload() {
    // 查找第一个未暂停的视频
    final nextEntry = waitDownloadQueue.firstWhereOrNull(
      (e) => e.status.value != DownloadStatus.pause,
    );

    if (nextEntry != null) {
      startDownload();
    }
  }

  /// 优先下载指定视频（暂停当前，立即开始该视频）
  Future<void> prioritizeDownload(DownloadEntryInfo entry) async {
    return _lock.synchronized(() async {
      // 如果该视频已经在下载，不做处理
      if (curDownload.value?.cid == entry.cid) {
        return;
      }

      // 如果有正在下载的视频，先暂停它
      if (curDownload.value != null) {
        final currentEntry = curDownload.value!;

        // 取消进度保存定时器
        _progressSaveTimer?.cancel();
        _progressSaveTimer = null;
        _lastSavedProgress = 0;

        // 取消当前下载
        await videoManager?.cancel(isDelete: false);
        await audioManager?.cancel(isDelete: false);

        // 标记为暂停状态并立即保存进度
        currentEntry.status.value = DownloadStatus.pause;
        await _updateBiliDownloadEntryJson(currentEntry);

        if (kDebugMode) {
          debugPrint(
              '暂停视频 ${currentEntry.cid}: ${currentEntry.downloadedBytes.value}/${currentEntry.totalBytes.value}');
        }

        // 清理状态
        _curCid = null;
        curDownload.value = null;
        videoManager = null;
        audioManager = null;

        // 强制刷新队列UI
        waitDownloadQueue.refresh();
      }

      // 将目标视频状态改为等待
      if (entry.status.value == DownloadStatus.pause) {
        entry.status.value = DownloadStatus.wait;
        await _updateBiliDownloadEntryJson(entry);
      }

      // 立即开始下载该视频
      _curCid = entry.cid;
      curDownload.value = entry;
      await _startDownload(entry);
    });
  }

  /// 继续下载（恢复暂停的下载）
  Future<void> resumeDownload(DownloadEntryInfo entry) async {
    if (entry.status.value != DownloadStatus.pause) return;

    // 重置状态为等待
    entry.status.value = DownloadStatus.wait;
    await _updateBiliDownloadEntryJson(entry);

    // 如果当前没有下载，立即开始
    if (curDownload.value == null) {
      startDownload();
    }
  }

  /// 删除等待队列中的单个下载
  Future<void> removeFromWaitingQueue(DownloadEntryInfo entry) async {
    // 如果是当前正在下载的，需要先取消
    if (curDownload.value?.cid == entry.cid) {
      await cancelDownload(isDelete: true, downloadNext: true);
    } else {
      waitDownloadQueue.remove(entry);
      await _deleteDownloadFiles(entry);
      flagNotifier.refresh();
    }
  }

  /// 获取视频播放地址
  Future<DownloadMediaInfo> _getVideoUrl({
    required DownloadEntryInfo entry,
  }) async {
    final res = await VideoHttp.videoUrl(
      bvid: entry.bvid,
      cid: entry.cid,
      qn: entry.preferedVideoQuality,
    );

    if (res['status']) {
      final PlayUrlModel data = res['data'];
      final dash = data.dash;

      if (dash != null) {
        // DASH 格式
        final videoList = dash.video ?? [];
        if (videoList.isEmpty) {
          throw Exception('No video stream available');
        }

        final curHighestVideoQa = videoList.first.id!;
        final preferVideoQa = entry.preferedVideoQuality;
        int targetVideoQa = curHighestVideoQa;

        if (data.acceptQuality != null && data.acceptQuality!.isNotEmpty) {
          for (var qaCode in data.acceptQuality!) {
            if (qaCode <= preferVideoQa) {
              targetVideoQa = qaCode;
              break;
            }
          }
        }

        final videosList =
            videoList.where((e) => e.id == targetVideoQa).toList();
        if (videosList.isEmpty) {
          throw Exception('No matching video quality');
        }

        final videoDash = videosList.first;
        final videoUrl = videoDash.baseUrl ?? videoDash.backupUrl ?? '';

        final videoFile = Type2File(
          id: videoDash.id!,
          baseUrl: videoUrl,
          bandwidth: videoDash.bandWidth ?? 0,
          codecid: videoDash.codecid!,
          size: 0,
          md5: '',
          noRexcode: false,
          frameRate: videoDash.frameRate ?? '',
          width: videoDash.width!,
          height: videoDash.height!,
          dashDrmType: 0,
        );

        List<Type2File>? audioFileList;
        final audioDashList = dash.audio;
        if (audioDashList != null && audioDashList.isNotEmpty) {
          final audioDash = audioDashList.first;
          final audioUrl = audioDash.baseUrl ?? audioDash.backupUrl ?? '';
          audioFileList = [
            Type2File(
              id: audioDash.id!,
              baseUrl: audioUrl,
              bandwidth: audioDash.bandWidth ?? 0,
              codecid: audioDash.codecid!,
              size: 0,
              md5: '',
              noRexcode: false,
              frameRate: audioDash.frameRate ?? '',
              width: audioDash.width ?? 0,
              height: audioDash.height ?? 0,
              dashDrmType: 0,
            ),
          ];
        }

        return Type2MediaInfo(
          duration: dash.duration!,
          video: [videoFile],
          audio: audioFileList,
          referer: 'https://www.bilibili.com/',
          userAgent: 'Bilibili Freedoooooom/MarkII',
        );
      } else if (data.durl != null && data.durl!.isNotEmpty) {
        // FLV 格式
        final first = data.durl!.first;
        final segmentList = [
          Type1Segment(
            backupUrls: first.backupUrl ?? [],
            bytes: first.size ?? 0,
            duration: first.length ?? 0,
            md5: '',
            metaUrl: '',
            order: first.order ?? 0,
            url: first.url ?? '',
          ),
        ];

        final playerCodecConfigList = [
          Type1PlayerCodecConfig(
            player: "IJK_PLAYER",
            useIjkMediaCodec: false,
          ),
          Type1PlayerCodecConfig(
            player: "ANDROID_PLAYER",
            useIjkMediaCodec: false,
          ),
        ];

        return Type1MediaInfo(
          from: entry.pageData?.from ?? entry.ep?.from,
          quality: entry.preferedVideoQuality,
          typeTag: entry.typeTag,
          description: entry.qualityPithyDescription,
          playerCodecConfigList: playerCodecConfigList,
          segmentList: segmentList,
          parseTimestampMilli: 0,
          availablePeriodMilli: 0,
          isDownloaded: false,
          isResolved: true,
          timeLength: 0,
          marlinToken: '',
          videoCodecId: 0,
          videoProject: true,
          format: data.format ?? 'flv',
          playerError: 0,
          needVip: false,
          needLogin: false,
          intact: false,
          referer: 'https://www.bilibili.com/',
          userAgent: 'Bilibili Freedoooooom/MarkII',
        );
      }
    }
    throw Exception('Failed to get video url: ${res['msg']}');
  }
}

extension SetExt on Set<void Function()> {
  void refresh() {
    for (var i in this) {
      i();
    }
  }
}
