import 'package:flutter/material.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/models/video_detail_res_staff.dart';
import 'package:PiliPalaX/utils/feed_back.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 合作视频 UP 主项组件
class StaffItem extends StatelessWidget {
  final Staff staff;
  final int? ownerMid;
  final bool isFollowed;
  final VoidCallback onTap;
  final VoidCallback? onFollow;

  const StaffItem({
    super.key,
    required this.staff,
    this.ownerMid,
    required this.isFollowed,
    required this.onTap,
    this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isVip = (staff.vip?.status ?? 0) > 0 && staff.vip?.type == 2;
    final Color? vipColor = isVip ? const Color(0xFFFF6699) : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        feedBack();
        onTap();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头像和认证标识
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 头像
              NetworkImgLayer(
                type: 'avatar',
                src: staff.face,
                width: 35,
                height: 35,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
              ),
              // 认证标识
              if ((staff.official?.type ?? -1) != -1)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                    ),
                    child: Icon(
                      Icons.offline_bolt,
                      color: staff.official?.type == 0
                          ? const Color(0xFFFFCC00) // 个人认证：黄色
                          : Colors.lightBlueAccent, // 机构认证：蓝色
                      size: 14,
                    ),
                  ),
                ),
              // 关注按钮（仅未关注时显示）
              if (!isFollowed && onFollow != null)
                Positioned(
                  top: 0,
                  right: -6,
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        feedBack();
                        onFollow?.call();
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          MdiIcons.plus,
                          size: 16,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // UP 主信息
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UP 主名称
              Text(
                staff.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: vipColor,
                ),
              ),
              // 职位/角色
              Text(
                staff.title ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
