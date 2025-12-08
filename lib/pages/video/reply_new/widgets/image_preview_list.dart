import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 图片预览列表组件
class ImagePreviewList extends StatelessWidget {
  final RxList<String> pathList;
  final Function(int) onDelete;
  final Function(int) onCrop;
  final Function(int) onPreview;
  final double height;

  const ImagePreviewList({
    Key? key,
    required this.pathList,
    required this.onDelete,
    required this.onCrop,
    required this.onPreview,
    this.height = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => pathList.isEmpty
          ? const SizedBox.shrink()
          : Container(
              height: height + 16,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pathList.length,
                itemBuilder: (context, index) {
                  return _buildImageItem(context, index);
                },
              ),
            ),
    );
  }

  Widget _buildImageItem(BuildContext context, int index) {
    final color =
        Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => onPreview(index),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: Image(
                height: height,
                width: height,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                image: FileImage(File(pathList[index])),
              ),
            ),
          ),
          // 编辑按钮（仅移动端）
          if (Platform.isAndroid || Platform.isIOS)
            Positioned(
              top: 34,
              right: 5,
              child: _buildIconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => onCrop(index),
                size: 24,
                iconSize: 14,
                bgColor: color,
              ),
            ),
          // 删除按钮
          Positioned(
            top: 5,
            right: 5,
            child: _buildIconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => onDelete(index),
              size: 24,
              iconSize: 14,
              bgColor: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required Icon icon,
    required VoidCallback onPressed,
    required double size,
    required double iconSize,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: IconButton(
            icon: icon,
            iconSize: iconSize,
            onPressed: onPressed,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
