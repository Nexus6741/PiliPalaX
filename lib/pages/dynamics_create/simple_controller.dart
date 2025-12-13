import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../http/dynamics.dart';
import '../../http/msg.dart';
import '../../models/dynamics/topic_item.dart';
import '../../models/dynamics/vote_model.dart';
import '../../utils/storage.dart';

class SimpleDynamicCreateController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  // 状态变量
  final RxBool canPublish = false.obs;
  final RxBool isPublishing = false.obs;
  final RxBool showPanelState = false.obs;
  final RxInt currentPanelIndex = 0.obs;

  // 内容相关
  final RxList<File> selectedImages = <File>[].obs;
  final Rx<TopicItem?> selectedTopic = Rx<TopicItem?>(null);
  final Rx<VoteInfo?> selectedVote = Rx<VoteInfo?>(null);
  final Rx<DateTime?> scheduledTime = Rx<DateTime?>(null);

  // 设置选项
  final RxBool isPrivate = false.obs;
  final RxBool allowReply = true.obs;

  // 计算属性
  bool get canAddImage => selectedImages.length < 18;
  bool get isScheduled => scheduledTime.value != null;

  @override
  void onInit() {
    super.onInit();
    // 从存储中恢复设置
    _loadSettings();
  }

  void _loadSettings() {
    final box = GStorage.setting;
    isPrivate.value = box.get('dynamics_private', defaultValue: false);
    allowReply.value = box.get('dynamics_allow_reply', defaultValue: true);
  }

  void _saveSettings() {
    final box = GStorage.setting;
    box.put('dynamics_private', isPrivate.value);
    box.put('dynamics_allow_reply', allowReply.value);
  }

  void updatePublishEnabled(bool enabled) {
    canPublish.value = enabled || selectedImages.isNotEmpty;
  }

  void showPanel(int index) {
    currentPanelIndex.value = index;
    if (showPanelState.value && currentPanelIndex.value == index) {
      // 如果面板已经显示且是同一个索引，则隐藏面板
      showPanelState.value = false;
    } else {
      // 显示面板并切换到指定索引
      showPanelState.value = true;
    }
  }

  void hidePanel() {
    showPanelState.value = false;
  }

  // 设置选项
  void togglePrivate(bool value) {
    isPrivate.value = value;
    _saveSettings();
  }

  void toggleReply(bool value) {
    allowReply.value = value;
    _saveSettings();
  }

  // 图片相关
  Future<void> pickImages() async {
    if (!canAddImage) {
      SmartDialog.showToast('最多只能选择18张图片');
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final remainingSlots = 18 - selectedImages.length;
        final imagesToAdd = images.take(remainingSlots);

        for (final image in imagesToAdd) {
          selectedImages.add(File(image.path));
        }

        if (images.length > remainingSlots) {
          SmartDialog.showToast('已选择$remainingSlots张图片，超出部分已忽略');
        }

        updatePublishEnabled(true);
      }
    } catch (e) {
      SmartDialog.showToast('选择图片失败: $e');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);

      // 重新检查发布按钮状态
      updatePublishEnabled(selectedImages.isNotEmpty);
    }
  }

  void clearImages() {
    selectedImages.clear();
    updatePublishEnabled(false);
  }

  // 话题相关
  void setTopic(TopicItem topic) {
    selectedTopic.value = topic;
  }

  void clearTopic() {
    selectedTopic.value = null;
  }

  // 投票相关
  void setVote(VoteInfo vote) {
    selectedVote.value = vote;
    updatePublishEnabled(true);
  }

  void clearVote() {
    selectedVote.value = null;
  }

  // 定时发布相关
  void setScheduledTime(DateTime time) {
    scheduledTime.value = time;
  }

  void clearSchedule() {
    scheduledTime.value = null;
  }

  // 发布动态
  Future<void> publishDynamic({
    String? content,
    String? title,
    List<Map<String, dynamic>>? richContent,
  }) async {
    if (isPublishing.value) return;

    isPublishing.value = true;
    SmartDialog.showLoading(msg: '发布中...');

    try {
      // 上传图片
      List<String>? imageUrls;
      if (selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
        if (imageUrls == null) {
          SmartDialog.showToast('图片上传失败');
          return;
        }
      }

      // 创建投票（如果有）
      int? voteId;
      if (selectedVote.value != null) {
        print('=== 开始创建投票 ===');
        final voteResult = await DynamicsHttp.createVote(selectedVote.value!);
        if (voteResult['status'] != true) {
          SmartDialog.showToast('投票创建失败: ${voteResult['msg']}');
          return;
        }
        voteId = voteResult['data']?['vote_id'];
        print('投票创建成功，vote_id: $voteId');

        if (voteId == null) {
          SmartDialog.showToast('投票创建失败：未返回投票ID');
          return;
        }
      }

      // 发布动态
      print('=== 准备发布动态 ===');
      print('voteId: $voteId');
      final result = await DynamicsHttp.createDynamic(
        content: content,
        title: title,
        images: imageUrls,
        topic: selectedTopic.value,
        voteId: voteId,
        isPrivate: isPrivate.value,
        allowReply: allowReply.value,
        scheduledTime: scheduledTime.value,
        richContent: richContent,
      );

      if (result['status'] == true) {
        SmartDialog.showToast('发布成功');
        Get.back(result: true);
      } else {
        SmartDialog.showToast(result['msg'] ?? '发布失败');
      }
    } catch (e) {
      SmartDialog.showToast('发布失败: $e');
    } finally {
      isPublishing.value = false;
      SmartDialog.dismiss();
    }
  }

  Future<List<String>?> _uploadImages() async {
    try {
      final List<String> urls = [];

      for (int i = 0; i < selectedImages.length; i++) {
        final file = selectedImages[i];
        SmartDialog.showLoading(msg: '上传图片 ${i + 1}/${selectedImages.length}');

        final result = await MsgHttp.uploadBfs(
          path: file.path,
          category: 'daily',
          biz: 'new_dyn',
        );

        if (result['status'] == true) {
          urls.add(result['data']['image_url']);
        } else {
          return null;
        }
      }

      return urls;
    } catch (e) {
      return null;
    }
  }

  @override
  void onClose() {
    _saveSettings();
    super.onClose();
  }
}
