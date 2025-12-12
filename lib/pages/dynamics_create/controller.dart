import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../http/dynamics.dart';
import '../../models/dynamics/topic_item.dart';
import '../../utils/storage.dart';

class CreateDynamicController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  // 状态变量
  final RxBool canPublish = false.obs;
  final RxBool isPublishing = false.obs;
  final RxBool showPanelState = false.obs;
  final RxInt currentPanelIndex = 0.obs;

  // 内容相关
  final RxList<File> selectedImages = <File>[].obs;
  final Rx<TopicItem?> selectedTopic = Rx<TopicItem?>(null);

  // 设置选项
  final RxBool isPrivate = false.obs;
  final RxBool allowReply = true.obs;
  final Rx<DateTime?> scheduledTime = Rx<DateTime?>(null);

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
    canPublish.value = enabled;
  }

  void showKeyboard() {
    showPanelState.value = false;
  }

  void showPanel(int index) {
    currentPanelIndex.value = index;
    showPanelState.value = !showPanelState.value;
  }

  void hidePanel() {
    showPanelState.value = false;
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
          SmartDialog.showToast('已选择${remainingSlots}张图片，超出部分已忽略');
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

      // 如果没有图片且没有文本，禁用发布按钮
      if (selectedImages.isEmpty) {
        updatePublishEnabled(false);
      }
    }
  }

  void clearImages() {
    selectedImages.clear();
    updatePublishEnabled(false);
  }

  // 话题相关
  void setTopic(TopicItem topic) {
    print('=== setTopic 被调用 ===');
    print('topic: $topic');
    print('topic.id: ${topic.id}');
    print('topic.name: ${topic.name}');
    print('topic类型: ${topic.runtimeType}');
    selectedTopic.value = topic;
    print('selectedTopic.value 已设置: ${selectedTopic.value}');
  }

  void clearTopic() {
    print('=== clearTopic 被调用 ===');
    selectedTopic.value = null;
  }

  // 设置选项
  void togglePrivate(bool value) {
    isPrivate.value = value;
    if (value) {
      // 私密动态不能定时发布
      clearSchedule();
    }
    _saveSettings();
  }

  void toggleReply(bool value) {
    allowReply.value = value;
    _saveSettings();
  }

  void setScheduledTime(DateTime time) {
    scheduledTime.value = time;
  }

  void clearSchedule() {
    scheduledTime.value = null;
  }

  // 发布动态
  Future<void> publishDynamic({
    required String content,
    String? title,
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

      // 日志：检查话题数据
      print('=== 发布动态 - 话题检查 ===');
      print('selectedTopic.value: ${selectedTopic.value}');
      if (selectedTopic.value != null) {
        print('话题ID: ${selectedTopic.value!.id}');
        print('话题名称: ${selectedTopic.value!.name}');
        print('话题类型: ${selectedTopic.value.runtimeType}');
      } else {
        print('未选择话题');
      }

      // 发布动态
      final result = await DynamicsHttp.createDynamic(
        content: content,
        title: title,
        images: imageUrls,
        topic: selectedTopic.value,
        isPrivate: isPrivate.value,
        allowReply: allowReply.value,
        scheduledTime: scheduledTime.value,
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

        final result = await _uploadSingleImage(file);
        if (result != null) {
          urls.add(result);
        } else {
          return null;
        }
      }

      return urls;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _uploadSingleImage(File file) async {
    try {
      // TODO: 实现图片上传到B站服务器
      // 这里需要调用B站的图片上传API
      // 暂时返回本地路径作为占位符
      return file.path;
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
