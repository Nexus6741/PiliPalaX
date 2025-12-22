import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/badge.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/models/space_fav/space_fav_data.dart';
import 'package:PiliPalaX/models/user/fav_folder.dart';
import 'package:PiliPalaX/models/user/sub_folder.dart' as sub;
import 'package:PiliPalaX/utils/utils.dart';

/// 用户空间收藏夹卡片
/// 参考媒体库的FavFolderItem实现
class MemberFavItem extends StatelessWidget {
  const MemberFavItem({
    super.key,
    required this.item,
    this.callback,
  });

  final SpaceFavItemModel item;
  final ValueChanged<bool?>? callback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 与媒体库一致：使用 fid 作为 heroTag，使用 id 作为 mediaId
    // 如果没有 fid，则使用 id
    final String heroTag = Utils.makeHeroTag(item.fid ?? item.id);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () async {
          // 根据类型跳转到不同页面
          // type: 11=播单, 21=合集, 其他=收藏夹
          if (item.type == 21) {
            // 合集 - 需要传递 SubFolderItemData 对象
            final subFolderItem = sub.SubFolderItemData(
              id: item.id,
              title: item.title,
              cover: item.cover,
              mediaCount: item.mediaCount ?? item.count,
              type: item.type,
              upper: item.upper != null
                  ? sub.Upper(
                      mid: item.upper!.mid,
                      name: item.upper!.name,
                      face: item.upper!.face,
                    )
                  : null,
              viewCount: item.viewCount,
            );
            var res = await Get.toNamed(
              '/subDetail',
              arguments: subFolderItem,
              parameters: {
                'heroTag': heroTag,
                'id': item.id.toString(),
              },
            );
            callback?.call(res);
          } else if (item.type == 11) {
            // 播单 - 也需要传递 SubFolderItemData 对象
            final subFolderItem = sub.SubFolderItemData(
              id: item.id,
              title: item.title,
              cover: item.cover,
              mediaCount: item.mediaCount ?? item.count,
              type: item.type,
              upper: item.upper != null
                  ? sub.Upper(
                      mid: item.upper!.mid,
                      name: item.upper!.name,
                      face: item.upper!.face,
                    )
                  : null,
              viewCount: item.viewCount,
            );
            var res = await Get.toNamed(
              '/subDetail',
              arguments: subFolderItem,
              parameters: {
                'heroTag': heroTag,
                'id': item.id.toString(),
              },
            );
            callback?.call(res);
          } else {
            // 收藏夹 - 构造 FavFolderItemData 对象，与媒体库跳转方式一致
            final favItem = FavFolderItemData(
              id: item.id,
              fid: item.fid,
              title: item.title,
              cover: item.cover,
              mediaCount: item.mediaCount ?? item.count,
            );
            var res = await Get.toNamed(
              '/favDetail',
              arguments: favItem,
              parameters: {
                'mediaId': item.id.toString(),
                'heroTag': heroTag,
              },
            );
            callback?.call(res);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StyleString.safeSpace,
            vertical: 5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AspectRatio(
                    aspectRatio: StyleString.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) => Hero(
                        tag: heroTag,
                        child: NetworkImgLayer(
                          src: item.cover ?? '',
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                        ),
                      ),
                    ),
                  ),
                  // 类型标签
                  if (item.type == 21)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: PBadge(text: '合集'),
                    )
                  else if (item.type == 11)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: PBadge(text: '播单'),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      _buildSubtitle(),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final count = item.mediaCount ?? item.count ?? 0;
    // 如果有 upper 信息，显示创建者
    if (item.upper != null && item.upper!.name != null) {
      return '$count个内容 · ${item.upper!.name}';
    }
    // 否则显示公开/私密状态
    final isPublic = item.attr == 0 || item.isPublic == 1;
    return '$count个内容 · ${isPublic ? '公开' : '私密'}';
  }
}
