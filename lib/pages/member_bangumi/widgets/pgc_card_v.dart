import 'package:flutter/material.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/common/widgets/image_preview_dialog.dart';
import 'package:PiliPalaX/models/bangumi/list.dart';
import 'package:PiliPalaX/utils/app_scheme.dart';
import 'package:PiliPalaX/utils/utils.dart';

/// 用户空间追番卡片 - 垂直布局
/// 参考PiliPlus的PgcCardVMemberPgc
class PgcCardVMemberBangumi extends StatelessWidget {
  const PgcCardVMemberBangumi({
    super.key,
    required this.item,
  });

  final BangumiListItemModel item;

  @override
  Widget build(BuildContext context) {
    final String heroTag = Utils.makeHeroTag(item.seasonId);

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: StyleString.mdRadius),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
      child: InkWell(
        borderRadius: StyleString.mdRadius,
        onTap: () {
          // 跳转到番剧详情页
          if (item.seasonId != null) {
            PiliScheme.bangumiPush(item.seasonId, null);
          }
        },
        onLongPress: () {
          showImagePreviewDialog(
            imageUrl: item.cover ?? '',
            title: item.title,
            imgType: 'cover',
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: Hero(
                      tag: heroTag,
                      child: NetworkImgLayer(
                        src: item.cover ?? '',
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
              child: Text(
                item.title ?? '',
                textAlign: TextAlign.start,
                style: const TextStyle(letterSpacing: 0.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
