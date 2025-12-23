import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/utils/download.dart';

/// 通用图片预览对话框
/// 支持双击缩放、手势操作、长按保存
class ImagePreviewDialog extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? imgType;

  const ImagePreviewDialog({
    super.key,
    required this.imageUrl,
    this.title,
    this.imgType,
  });

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _doubleClickAnimationController;
  Animation<double>? _doubleClickAnimation;
  late Function() _doubleClickAnimationListener;
  final List<double> doubleTapScales = <double>[1.0, 2.0];

  @override
  void initState() {
    super.initState();
    _doubleClickAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _doubleClickAnimationController.dispose();
    super.dispose();
  }

  void _onSaveImage() {
    DownloadUtils.downloadImg(
      context,
      widget.imageUrl,
      imgType: widget.imgType ?? 'cover',
    );
  }

  void _onCopyLink() {
    Clipboard.setData(ClipboardData(text: widget.imageUrl)).then((value) {
      SmartDialog.showToast('已复制到粘贴板');
    }).catchError((err) {
      SmartDialog.showNotify(
        msg: err.toString(),
        notifyType: NotifyType.error,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      primary: false,
      extendBody: true,
      appBar: AppBar(
        primary: false,
        toolbarHeight: 0,
        backgroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          // 图片预览区域
          Center(
            child: ExtendedImage.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              mode: ExtendedImageMode.gesture,
              onDoubleTap: (ExtendedImageGestureState state) {
                final Offset? pointerDownPosition = state.pointerDownPosition;
                final double? begin = state.gestureDetails!.totalScale;
                double end;

                _doubleClickAnimation
                    ?.removeListener(_doubleClickAnimationListener);
                _doubleClickAnimationController.stop();
                _doubleClickAnimationController.reset();

                if (begin == doubleTapScales[0]) {
                  end = doubleTapScales[1];
                } else {
                  end = doubleTapScales[0];
                }

                _doubleClickAnimationListener = () {
                  state.handleDoubleTap(
                    scale: _doubleClickAnimation!.value,
                    doubleTapPosition: pointerDownPosition,
                  );
                };

                _doubleClickAnimation = _doubleClickAnimationController
                    .drive(Tween<double>(begin: begin, end: end));

                _doubleClickAnimation!
                    .addListener(_doubleClickAnimationListener);

                _doubleClickAnimationController.forward();
              },
              loadStateChanged: (ExtendedImageState state) {
                if (state.extendedImageLoadState == LoadState.loading) {
                  final ImageChunkEvent? loadingProgress =
                      state.loadingProgress;
                  final double? progress =
                      loadingProgress?.expectedTotalBytes != null
                          ? loadingProgress!.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 150.0,
                          child: LinearProgressIndicator(
                            value: progress,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return null;
              },
              initGestureConfigHandler: (ExtendedImageState state) {
                return GestureConfig(
                  inPageView: false,
                  initialScale: 1.0,
                  maxScale: 5.0,
                  animationMaxScale: 6.0,
                  initialAlignment: InitialAlignment.center,
                );
              },
            ),
          ),
          // 底部操作栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black87,
                  ],
                  tileMode: TileMode.mirror,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 标题
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  // 操作按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 复制链接按钮
                      IconButton(
                        onPressed: _onCopyLink,
                        icon: const Icon(Icons.link, color: Colors.white),
                        tooltip: '复制链接',
                      ),
                      // 保存按钮
                      IconButton(
                        onPressed: _onSaveImage,
                        icon: const Icon(Icons.download, color: Colors.white),
                        tooltip: '保存图片',
                      ),
                      // 关闭按钮
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: '关闭',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 显示图片预览对话框的便捷方法
void showImagePreviewDialog({
  required String imageUrl,
  String? title,
  String? imgType,
}) {
  Get.to(
    () => ImagePreviewDialog(
      imageUrl: imageUrl,
      title: title,
      imgType: imgType,
    ),
    preventDuplicates: false,
    transition: Transition.fadeIn,
    duration: const Duration(milliseconds: 200),
  );
}
