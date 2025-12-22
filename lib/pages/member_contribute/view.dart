import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/models/member/space_data.dart';
import 'package:PiliPalaX/pages/member_contribute/controller.dart';
import 'package:PiliPalaX/pages/member_archive/view.dart';
import 'package:PiliPalaX/pages/member_opus/view.dart';

class MemberContribute extends StatefulWidget {
  const MemberContribute({
    super.key,
    this.heroTag,
    this.initialIndex,
    required this.mid,
  });

  final String? heroTag;
  final int? initialIndex;
  final int mid;

  @override
  State<MemberContribute> createState() => _MemberContributeState();
}

class _MemberContributeState extends State<MemberContribute>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final _controller = Get.put(
    MemberContributeController(
      heroTag: widget.heroTag,
      initialIndex: widget.initialIndex,
    ),
    tag: widget.heroTag,
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    // 如果没有items，显示错误
    if (_controller.items == null || _controller.items!.isEmpty) {
      return HttpError(
        errMsg: '暂无投稿内容',
        fn: () {},
      );
    }

    // 如果有多个Tab，显示TabBar
    if (_controller.tabs != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            overlayColor: const WidgetStatePropertyAll(
              Colors.transparent,
            ),
            splashFactory: NoSplash.splashFactory,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            isScrollable: true,
            tabs: _controller.tabs!,
            tabAlignment: TabAlignment.start,
            controller: _controller.tabController,
            dividerHeight: 0,
            indicatorWeight: 0,
            indicatorPadding: const EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 8,
            ),
            indicator: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TabBarTheme.of(context).labelStyle?.copyWith(
                      fontSize: 14,
                    ) ??
                const TextStyle(fontSize: 14),
            labelColor: theme.colorScheme.onSecondaryContainer,
            unselectedLabelColor: theme.colorScheme.outline,
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _controller.tabController,
              children: _controller.items!.map(_getPageFromType).toList(),
            ),
          ),
        ],
      );
    }

    // 只有一个Tab，直接显示内容
    return _getPageFromType(_controller.items!.first);
  }

  Widget _getPageFromType(SpaceTab2Item item) {
    print(
        '_getPageFromType called with: title=${item.title}, param=${item.param}, seasonId=${item.seasonId}, seriesId=${item.seriesId}');

    switch (item.param) {
      case 'video':
        return MemberArchivePage(
          mid: widget.mid,
          type: 'video',
        );
      case 'charging_video':
        return MemberArchivePage(
          mid: widget.mid,
          type: 'charging',
        );
      case 'article':
        return _buildPlaceholder('专栏', item.title);
      case 'opus':
        return MemberOpusPage(mid: widget.mid);
      case 'audio':
        return _buildPlaceholder('音频', item.title);
      case 'comic':
        return _buildPlaceholder('漫画', item.title);
      case 'season_video':
        return MemberArchivePage(
          mid: widget.mid,
          type: 'season',
          seasonId: item.seasonId,
          title: item.title,
        );
      case 'series':
        return MemberArchivePage(
          mid: widget.mid,
          type: 'series',
          seriesId: item.seriesId,
          title: item.title,
        );
      case 'ugcSeason':
        return _buildPlaceholder('全部合集/列表', item.title);
      default:
        print('Unknown param type: ${item.param}');
        return Center(child: Text(item.title ?? '未知类型'));
    }
  }

  Widget _buildPlaceholder(String type, String? title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '$type功能开发中',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (title != null) ...[
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
