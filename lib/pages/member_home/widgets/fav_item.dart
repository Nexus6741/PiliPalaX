import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/models/member/space_data.dart';
import 'package:PiliPalaX/models/user/fav_folder.dart';
import 'package:PiliPalaX/utils/utils.dart';

/// 用户空间主页收藏夹卡片
/// 参考媒体库的FavFolderItem实现
class MemberHomeFavItem extends StatelessWidget {
  const MemberHomeFavItem({super.key, required this.item});

  final SpaceFavouriteItem item;

  @override
  Widget build(BuildContext context) {
    // 与媒体库一致：使用 fid 作为 heroTag
    // 如果没有 fid，则使用 mediaId 或 id
    final String heroTag =
        Utils.makeHeroTag(item.fid ?? item.mediaId ?? item.id);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          print('=== MemberHomeFavItem onTap ===');
          print('item.id: ${item.id}');
          print('item.fid: ${item.fid}');
          print('item.mediaId: ${item.mediaId}');
          print('item.title: ${item.title}');
          print('item.mediaCount: ${item.mediaCount}');
          print('item.count: ${item.count}');

          // 使用 mediaId 字段，如果没有则使用 id
          final int? actualMediaId = item.mediaId ?? item.id;

          if (actualMediaId == null) {
            print('actualMediaId is null, returning');
            return;
          }

          print('actualMediaId: $actualMediaId');
          print('heroTag: $heroTag');

          // 构造 FavFolderItemData 对象，与媒体库跳转方式一致
          final favItem = FavFolderItemData(
            id: actualMediaId,
            fid: item.fid,
            title: item.title,
            cover: item.cover,
            mediaCount: item.mediaCount ?? item.count,
          );
          print(
              'FavFolderItemData: id=${favItem.id}, fid=${favItem.fid}, title=${favItem.title}');

          Get.toNamed(
            '/favDetail',
            arguments: favItem,
            parameters: {
              'mediaId': actualMediaId.toString(),
              'heroTag': heroTag,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StyleString.safeSpace,
            vertical: 5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: StyleString.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Hero(
                      tag: heroTag,
                      child: NetworkImgLayer(
                        src: item.cover ?? '',
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                    );
                  },
                ),
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
                      '${item.mediaCount ?? item.count ?? 0}个内容',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
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
}
