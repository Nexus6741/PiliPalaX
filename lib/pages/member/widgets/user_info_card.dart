import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/models/common/member/user_info_type.dart';
import 'package:PiliPalaX/models/member/space_data.dart';
import 'package:PiliPalaX/utils/color_utils.dart';
import 'package:PiliPalaX/utils/num_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({
    super.key,
    required this.isOwner,
    required this.card,
    required this.images,
    required this.relation,
    required this.onFollow,
    this.live,
    this.silence,
  });

  final bool isOwner;
  final int relation;
  final SpaceCard card;
  final SpaceImages images;
  final VoidCallback onFollow;
  final SpaceLive? live;
  final int? silence;

  // 获取关注状态文本
  String _getRelationText(int relation) {
    switch (relation) {
      case 0:
        return '关注';
      case 1:
        return '悄悄关注';
      case 2:
        return '已关注';
      case 4:
      case 6:
        return '已互关';
      case 128:
        return '移除黑名单';
      case -10:
        return '特别关注';
      default:
        return relation.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = colorScheme.isLight;
    final isPortrait = context.width < 600;

    return isPortrait
        ? _buildV(context, colorScheme, isLight)
        : _buildH(context, colorScheme, isLight);
  }

  // 统计数据组件
  Widget _countWidget({
    required ColorScheme colorScheme,
    required UserInfoType type,
  }) {
    int? count;
    VoidCallback? onTap;

    switch (type) {
      case UserInfoType.fan:
        count = card.fans;
        onTap = () => Get.toNamed('/fan?mid=${card.mid}&name=${card.name}');
        break;
      case UserInfoType.follow:
        count = card.attention;
        onTap = () => Get.toNamed('/follow?mid=${card.mid}&name=${card.name}');
        break;
      case UserInfoType.like:
        count = card.likes?.likeNum;
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: type.alignment,
        widthFactor: 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              NumUtils.numFormat(count),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              type.title,
              style: TextStyle(
                height: 1.2,
                fontSize: 12,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 顶部背景图
  Widget _buildHeader(ColorScheme colorScheme, bool isLight) {
    String imgUrl = (isLight
            ? images.imgUrl
            : (images.nightImgurl?.isNotEmpty == true
                ? images.nightImgurl
                : images.imgUrl)) ??
        '';

    if (imgUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: 135,
        color: colorScheme.primaryContainer,
      );
    }

    return Hero(
      tag: imgUrl,
      child: CachedNetworkImage(
        imageUrl: imgUrl,
        width: double.infinity,
        height: 135,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) => DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                isLight ? const Color(0x5DFFFFFF) : const Color(0x8D000000),
                isLight ? BlendMode.lighten : BlendMode.darken,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: colorScheme.primaryContainer,
        ),
      ),
    );
  }

  // 左侧用户信息
  List<Widget> _buildLeft(ColorScheme colorScheme, bool isLight) => [
        // 用户名和标识
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: card.name ?? ''));
                  SmartDialog.showToast('已复制用户名');
                },
                child: Text(
                  card.name ?? '',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: (card.vip?.status ?? -1) > 0 && card.vip?.type == 2
                        ? colorScheme.vipColor
                        : null,
                  ),
                ),
              ),
              // 等级
              if (card.levelInfo?.currentLevel != null)
                Image.asset(
                  'assets/images/lv/lv${card.levelInfo!.identity == 2 ? '6_s' : card.levelInfo!.currentLevel}.png',
                  height: 11,
                  semanticLabel: '等级${card.levelInfo!.currentLevel}',
                ),
              // VIP标签
              if (card.vip?.status == 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: colorScheme.vipColor,
                  ),
                  child: Text(
                    card.vip?.label?['text'] ?? '大会员',
                    style: const TextStyle(
                      height: 1,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              // 勋章
              if (card.nameplate?.imageSmall?.isNotEmpty == true)
                CachedNetworkImage(
                  imageUrl: card.nameplate!.imageSmall!,
                  height: 20,
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
        // 认证信息
        if (card.officialVerify?.desc?.isNotEmpty == true)
          Container(
            margin: const EdgeInsets.only(left: 20, top: 8, right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              color: colorScheme.onInverseSurface,
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.offline_bolt,
                      color: card.officialVerify?.type == 0
                          ? const Color(0xFFFFCC00)
                          : Colors.lightBlueAccent,
                      size: 18,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: card.officialVerify!.desc!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // 个性签名
        if (card.sign?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 6, right: 20),
            child: SelectableText(
              card.sign!.trim().replaceAll(RegExp(r'\n{2,}'), '\n'),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        // UID和空间标签
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 6, right: 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: card.mid ?? ''));
                  SmartDialog.showToast('已复制UID');
                },
                child: Text(
                  'UID: ${card.mid}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.outline,
                  ),
                ),
              ),
              ...?card.spaceTag?.map(
                (item) => Text(
                  item.title ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 封禁状态
        if (silence == 1)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              color: isLight ? colorScheme.errorContainer : colorScheme.error,
            ),
            margin: const EdgeInsets.only(left: 20, top: 8, right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.info,
                      size: 17,
                      color: isLight
                          ? colorScheme.onErrorContainer
                          : colorScheme.onError,
                    ),
                  ),
                  TextSpan(
                    text: ' 该账号封禁中',
                    style: TextStyle(
                      color: isLight
                          ? colorScheme.onErrorContainer
                          : colorScheme.onError,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ];

  // 右侧统计和按钮
  Column _buildRight(ColorScheme colorScheme) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 统计数据
          Row(
            children: UserInfoType.values
                .map(
                  (e) => Expanded(
                    child: _countWidget(
                      colorScheme: colorScheme,
                      type: e,
                    ),
                  ),
                )
                .expand((child) sync* {
                  yield const SizedBox(
                    height: 15,
                    width: 1,
                    child: VerticalDivider(),
                  );
                  yield child;
                })
                .skip(1)
                .toList(),
          ),
          const SizedBox(height: 5),
          // 按钮
          Row(
            spacing: 10,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 私信按钮
              if (!isOwner)
                IconButton.outlined(
                  onPressed: () {
                    Get.toNamed(
                      '/whisperDetail',
                      parameters: {
                        'talkerId': card.mid!,
                        'name': card.name!,
                        'face': card.face!,
                        'mid': card.mid!,
                      },
                    );
                  },
                  icon: const Icon(Icons.mail_outline, size: 21),
                  style: IconButton.styleFrom(
                    side: BorderSide(
                      width: 1.0,
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              // 关注/编辑资料按钮
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onFollow,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        relation != 0 ? colorScheme.onInverseSurface : null,
                    visualDensity: const VisualDensity(vertical: -1.8),
                  ),
                  child: Text.rich(
                    style: TextStyle(
                      color: relation != 0 ? colorScheme.outline : null,
                    ),
                    TextSpan(
                      children: [
                        if (relation != 0 && relation != 128) ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.sort,
                              size: 16,
                              color: colorScheme.outline,
                            ),
                          ),
                          const TextSpan(text: ' '),
                        ],
                        TextSpan(
                          text: isOwner ? '编辑资料' : _getRelationText(relation),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  // 头像
  Widget get _buildAvatar => Hero(
        tag: card.face ?? '',
        child: GestureDetector(
          onTap: () {
            // TODO: 图片预览
          },
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // 头像边框
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: Colors.white,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: NetworkImgLayer(
                    width: 80,
                    height: 80,
                    type: 'avatar',
                    src: card.face,
                  ),
                ),
              ),
              // 挂件 - 头像框
              if (card.pendant?.image?.isNotEmpty == true)
                Positioned(
                  top: -0.375 * (80 - 4), // -(80 * 1.75 - 80) / 2
                  child: IgnorePointer(
                    child: CachedNetworkImage(
                      width: 80 * 1.75,
                      height: 80 * 1.75,
                      imageUrl: card.pendant!.image!,
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              // 直播状态
              if (live?.liveStatus == 1)
                Positioned(
                  bottom: 0,
                  child: InkWell(
                    onTap: () {
                      Get.toNamed('/liveRoom?roomid=${live!.roomid}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(Get.context!).colorScheme.primary,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(36)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.equalizer_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const Text(
                            '直播中',
                            style: TextStyle(
                              height: 1,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // 认证标识
              else if (card.officialVerify?.type != null &&
                  card.officialVerify!.type! >= 0)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.offline_bolt,
                        color: card.officialVerify!.type == 0
                            ? const Color(0xFFFFCC00)
                            : Colors.lightBlueAccent,
                        size: 20,
                      ),
                    ),
                  ),
                )
              // VIP标识
              else if ((card.vip?.status ?? -1) > 0)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Image.asset(
                        'assets/images/big-vip.png',
                        height: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  // 竖屏布局
  Column _buildV(BuildContext context, ColorScheme colorScheme, bool isLight) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(colorScheme, isLight),
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.textScalerOf(context).scale(30) + 60,
                  ),
                ],
              ),
              Positioned(
                top: 110,
                left: 20,
                child: _buildAvatar,
              ),
              Positioned(
                left: 160,
                top: 140,
                right: 15,
                bottom: 0,
                child: _buildRight(colorScheme),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ..._buildLeft(colorScheme, isLight),
          if (card.prInfo?.content?.isNotEmpty == true)
            _buildPrInfo(colorScheme, isLight, card.prInfo!),
          const SizedBox(height: 5),
        ],
      );

  // 横屏布局
  Column _buildH(BuildContext context, ColorScheme colorScheme, bool isLight) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 56),
          Row(
            children: [
              const SizedBox(width: 20),
              Padding(
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: card.prInfo?.content?.isNotEmpty == true ? 0 : 10,
                ),
                child: _buildAvatar,
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    ..._buildLeft(colorScheme, isLight),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: _buildRight(colorScheme),
              ),
              const SizedBox(width: 20),
            ],
          ),
          if (card.prInfo?.content?.isNotEmpty == true)
            _buildPrInfo(colorScheme, isLight, card.prInfo!),
        ],
      );

  // 推广信息
  Widget _buildPrInfo(
    ColorScheme colorScheme,
    bool isLight,
    SpacePrInfo prInfo,
  ) {
    final textColor = ColorUtils.parseColor(
          isLight ? prInfo.textColor : prInfo.textColorNight,
        ) ??
        colorScheme.onSurface;

    Widget child = Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: ColorUtils.parseColor(
            isLight ? prInfo.bgColor : prInfo.bgColorNight,
          ) ??
          colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          if (!isLight && prInfo.iconNight?.isNotEmpty == true) ...[
            CachedNetworkImage(
              imageUrl: prInfo.iconNight!,
              height: 20,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 16),
          ] else if (prInfo.icon?.isNotEmpty == true) ...[
            CachedNetworkImage(
              imageUrl: prInfo.icon!,
              height: 20,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              prInfo.content!,
              style: TextStyle(fontSize: 13, color: textColor),
            ),
          ),
          if (prInfo.url?.isNotEmpty == true) ...[
            const SizedBox(width: 10),
            Icon(
              Icons.keyboard_arrow_right,
              color: textColor,
            ),
          ],
        ],
      ),
    );

    if (prInfo.url?.isNotEmpty == true) {
      return GestureDetector(
        onTap: () {
          Get.toNamed('/webview', parameters: {
            'url': prInfo.url!,
            'type': 'url',
            'pageTitle': '推广',
          });
        },
        child: child,
      );
    }
    return child;
  }
}
