import 'package:flutter/material.dart';
import '../../../models/dynamics_create/image_item.dart';
import '../controllers/image_upload_controller.dart';
import 'media_manager.dart';

/// 图片上传演示页面
/// 展示如何使用MediaManager组件
class ImageUploadDemo extends StatefulWidget {
  const ImageUploadDemo({Key? key}) : super(key: key);

  @override
  State<ImageUploadDemo> createState() => _ImageUploadDemoState();
}

class _ImageUploadDemoState extends State<ImageUploadDemo> {
  late final ImageUploadController _controller;
  List<ImageItem> _images = [];

  @override
  void initState() {
    super.initState();
    _controller = ImageUploadController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {
      _images = _controller.images;
    });
  }

  void _onImagesChanged(List<ImageItem> images) {
    _controller.clearImages();
    _controller.addImages(images);
  }

  void _onUploadProgress(int index, double progress) {
    // 进度更新会通过controller自动处理
    print('图片 $index 上传进度: ${(pr