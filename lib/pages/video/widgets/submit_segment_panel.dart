import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/sponsor_block.dart';
import 'package:PiliPalaX/models/common/sponsor_block/action_type.dart';
import 'package:PiliPalaX/models/common/sponsor_block/post_segment_model.dart';
import 'package:PiliPalaX/models/common/sponsor_block/segment_type.dart';
import 'package:PiliPalaX/common/widgets/pair.dart';
import 'package:PiliPalaX/pages/video/controller.dart';
import 'package:PiliPalaX/utils/storage.dart';

class SubmitSegmentPanel extends StatefulWidget {
  final VideoDetailController videoDetailCtr;
  final int currentPosition;
  final bool isFirstOpen;

  const SubmitSegmentPanel({
    super.key,
    required this.videoDetailCtr,
    required this.currentPosition,
    this.isFirstOpen = false,
  });

  @override
  State<SubmitSegmentPanel> createState() => _SubmitSegmentPanelState();
}

class _SubmitSegmentPanelState extends State<SubmitSegmentPanel> {
  late int startTime;
  late int endTime;
  SegmentType selectedType = SegmentType.sponsor;
  bool isSubmitting = false;
  bool wasPlaying = false;

  @override
  void initState() {
    super.initState();

    // 记录当前播放状态
    wasPlaying =
        widget.videoDetailCtr.plPlayerController?.playerStatus.playing ?? false;

    // 暂停视频
    if (wasPlaying) {
      widget.videoDetailCtr.plPlayerController?.pause();
      // print('🔍 [SubmitSegmentPanel] 暂停视频');
    }

    // 如果是首次打开，自动获取当前位置作为开始时间
    if (widget.isFirstOpen) {
      startTime = widget.currentPosition;
      endTime = widget.currentPosition + 10000; // 默认+10秒
      // print('🔍 [SubmitSegmentPanel] 首次打开，自动设置开始时间: ${_formatTime(startTime)}');
    } else {
      // 非首次打开，使用保存的时间
      startTime =
          widget.videoDetailCtr.savedStartTime ?? widget.currentPosition;
      endTime = widget.videoDetailCtr.savedEndTime ??
          (widget.currentPosition + 10000);
      // print('🔍 [SubmitSegmentPanel] 非首次打开，使用保存的时间: ${_formatTime(startTime)} - ${_formatTime(endTime)}');
    }
  }

  @override
  void dispose() {
    // 恢复播放状态
    if (wasPlaying) {
      widget.videoDetailCtr.plPlayerController?.play();
      // print('🔍 [SubmitSegmentPanel] 恢复播放');
    }
    super.dispose();
  }

  String _formatTime(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _setStartTime() {
    final currentPos = widget
            .videoDetailCtr.plPlayerController?.position.value.inMilliseconds ??
        0;
    setState(() {
      startTime = currentPos;
      if (endTime <= startTime) {
        endTime = startTime + 5000; // 至少5秒
      }
    });

    // 更新 controller 中保存的时间
    widget.videoDetailCtr.savedStartTime = startTime;
    widget.videoDetailCtr.savedEndTime = endTime;

    SmartDialog.showToast('已设置开始时间: ${_formatTime(startTime)}');
    // print('🔍 [SubmitSegmentPanel] 手动设置开始时间: ${_formatTime(startTime)}');
  }

  void _setEndTime() {
    final currentPos = widget
            .videoDetailCtr.plPlayerController?.position.value.inMilliseconds ??
        0;
    if (currentPos <= startTime) {
      SmartDialog.showToast('结束时间必须大于开始时间');
      return;
    }
    setState(() {
      endTime = currentPos;
    });

    // 更新 controller 中保存的时间
    widget.videoDetailCtr.savedEndTime = endTime;

    SmartDialog.showToast('已设置结束时间: ${_formatTime(endTime)}');
    // print('🔍 [SubmitSegmentPanel] 手动设置结束时间: ${_formatTime(endTime)}');
  }

  Future<void> _submitSegment() async {
    if (endTime <= startTime) {
      SmartDialog.showToast('结束时间必须大于开始时间');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Check and generate user ID
      final setting = GStorage.setting;
      String blockUserID = setting.get('blockUserID', defaultValue: '');
      if (blockUserID.isEmpty) {
        blockUserID = const Uuid().v4().replaceAll('-', '');
        await setting.put('blockUserID', blockUserID);
        // print('🔍 [SubmitSegmentPanel] 生成新的 userID: $blockUserID');
      } else {
        // print('🔍 [SubmitSegmentPanel] 使用已有 userID: $blockUserID');
      }

      final videoDuration = widget.videoDetailCtr.plPlayerController?.duration
              .value.inMilliseconds ??
          0;

      final segment = PostSegmentModel(
        segment: Pair(
          first: startTime / 1000, // 转换为秒
          second: endTime / 1000,
        ),
        category: selectedType,
        actionType: ActionType.skip,
      );

      // print('🔍 [SubmitSegmentPanel] 提交片段: ${startTime / 1000}s - ${endTime / 1000}s, 类型: ${selectedType.name}');

      final result = await SponsorBlock.postSkipSegments(
        bvid: widget.videoDetailCtr.bvid,
        cid: widget.videoDetailCtr.cid.value,
        videoDuration: videoDuration / 1000, // 转换为秒
        segments: [segment],
      );

      if (result is Success) {
        SmartDialog.showToast('提交成功！感谢您的贡献');
        Get.back();
        // 重置首次打开标志，下次可以重新开始
        widget.videoDetailCtr.isFirstOpenSubmitPanel = true;
        widget.videoDetailCtr.savedStartTime = null;
        widget.videoDetailCtr.savedEndTime = null;
        // 重新查询片段列表
        widget.videoDetailCtr.querySponsorBlock();
      } else if (result is Error) {
        SmartDialog.showToast('提交失败: ${result.errMsg}');
        // print('❌ [SubmitSegmentPanel] 提交失败: ${result.errMsg}');
      }
    } catch (e) {
      SmartDialog.showToast('提交失败: $e');
      // print('❌ [SubmitSegmentPanel] 提交异常: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  const Text(
                    '提交片段',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // 关闭面板，dispose 会自动恢复播放
                      Get.back();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 时间设置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '片段时间',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('开始时间',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(startTime),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward, size: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('结束时间',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(endTime),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _setStartTime,
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('设为开始'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _setEndTime,
                              icon: const Icon(Icons.stop, size: 18),
                              label: const Text('设为结束'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '时长: ${_formatTime(endTime - startTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 片段类型选择
              const Text(
                '片段类型',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SegmentType.values.map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    label: Text(type.title),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedType = type;
                        });
                      }
                    },
                    avatar: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: type.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                selectedType.description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isSubmitting ? null : _submitSegment,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('提交片段'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '提示：请确保时间准确，提交后将帮助其他用户跳过此片段',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
