import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/common/widgets/image_preview_dialog.dart';
import 'package:PiliPalaX/http/dynamics.dart';
import 'package:PiliPalaX/models/space_opus/space_opus_item.dart';

/// 用户空间图文卡片
/// 参考PiliPlus的SpaceOpusItem
class SpaceOpusCard extends StatelessWidget {
  const SpaceOpusCard({
    super.key,
    required this.item,
    required this.maxWidth,
  });

  final SpaceOpusItem item;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPic = item.cover?.url?.isNotEmpty == true;

    return Card(
      clipBehavior: Clip.hardEdge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: InkWell(
        onTap: () => _onTap(context),
        onLongPress: hasPic
            ? () {
                showImagePreviewDialog(
                  imageUrl: item.cover!.url ?? '',
                  title: item.content,
                  imgType: 'opus',
                );
              }
            : null,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图片
            if (hasPic)
              Stack(
                children: [
                  NetworkImgLayer(
                    width: maxWidth,
                    height: maxWidth * item.cover!.ratio,
                    src: item.cover!.url ?? '',
                  ),
                  // 点赞数覆盖层
                  Positioned(
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 45,
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                      child: _StatWidget(
                        icon: Icons.thumb_up_outlined,
                        value: item.stat?.like ?? '0',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            // 文字内容
            if (item.content?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Text(
                  item.content!,
                  maxLines: hasPic ? 4 : 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // 无图片时的点赞数
            if (!hasPic)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8),
                child: _StatWidget(
                  icon: Icons.thumb_up_outlined,
                  value: item.stat?.like ?? '0',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    if (item.opusId == null) return;

    // 显示加载提示
    SmartDialog.showLoading(msg: '加载中...');

    try {
      // 先调用 API 获取完整的动态数据
      var res = await DynamicsHttp.dynamicDetail(id: item.opusId!);

      SmartDialog.dismiss();

      if (res['status']) {
        final data = res['data'];
        // 获取评论类型
        final commentType = data.basic?['comment_type'] ?? 11;

        if (commentType == 12) {
          // 图文类型，跳转到 HTML 渲染页面
          Get.toNamed('/htmlRender', parameters: {
            'url': 'www.bilibili.com/opus/${item.opusId}',
            'title': '',
            'id': item.opusId!,
            'dynamicType': 'opus',
          });
        } else {
          // 其他类型，跳转到动态详情页
          Get.toNamed('/dynamicDetail', arguments: {
            'item': data,
            'floor': 1,
          });
        }
      } else {
        SmartDialog.showToast(res['msg'] ?? '加载失败');
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('加载失败: $e');
    }
  }
}

/// 统计数据组件
class _StatWidget extends StatelessWidget {
  const _StatWidget({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
