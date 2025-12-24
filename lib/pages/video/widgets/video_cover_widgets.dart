import 'package:flutter/material.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';

/// Performance optimization: Reusable cover image widget
/// Uses RepaintBoundary to isolate repaints and reduce unnecessary rendering
class VideoCoverImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const VideoCoverImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: NetworkImgLayer(
        key: ValueKey(imageUrl),
        src: imageUrl,
        width: width,
        height: height,
      ),
    );
  }
}

/// Performance optimization: Loading indicator widget
/// Extracted as independent component to avoid repeated creation
class VideoLoadingIndicator extends StatelessWidget {
  const VideoLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.black26, Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/loading.gif',
              height: 25,
              semanticLabel: "加载中",
            ),
            const Text(
              '加载中...',
              style: TextStyle(color: Colors.white, fontSize: 12),
              semanticsLabel: '',
            ),
          ],
        ),
      ),
    );
  }
}
