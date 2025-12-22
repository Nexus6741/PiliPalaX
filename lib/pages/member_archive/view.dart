import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/utils/utils.dart';
import '../../common/constants.dart';
import '../../common/widgets/http_error.dart';
import '../../models/space_archive/space_archive_item.dart';
import '../../utils/grid.dart';
import 'controller.dart';
import 'widgets/video_card_h_member.dart';

class MemberArchivePage extends StatefulWidget {
  const MemberArchivePage({
    super.key,
    required this.mid,
    this.type = 'video',
    this.seasonId,
    this.seriesId,
    this.title,
  });

  final int mid;
  final String type; // 'video', 'charging', 'season', 'series'
  final int? seasonId;
  final int? seriesId;
  final String? title;

  @override
  State<MemberArchivePage> createState() => _MemberArchivePageState();
}

class _MemberArchivePageState extends State<MemberArchivePage> {
  late MemberArchiveController _memberArchivesController;
  late Future _futureBuilderFuture;
  late int mid;

  @override
  void initState() {
    super.initState();
    mid = widget.mid;
    final String heroTag = Utils.makeHeroTag(mid);

    // 根据type、seasonId、seriesId生成唯一的tag
    String controllerTag = heroTag;
    if (widget.seasonId != null) {
      controllerTag = '${heroTag}_season_${widget.seasonId}';
    } else if (widget.seriesId != null) {
      controllerTag = '${heroTag}_series_${widget.seriesId}';
    } else if (widget.type != 'video') {
      controllerTag = '${heroTag}_${widget.type}';
    }

    _memberArchivesController = Get.put(
      MemberArchiveController(
        mid: mid,
        type: widget.type,
        seasonId: widget.seasonId,
        seriesId: widget.seriesId,
      ),
      tag: controllerTag,
    );
    _futureBuilderFuture = _memberArchivesController.getMemberArchive('init');
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if ((scrollNotification is ScrollEndNotification &&
                scrollNotification.metrics.extentAfter == 0) ||
            (scrollNotification is ScrollUpdateNotification &&
                scrollNotification.metrics.maxScrollExtent -
                        scrollNotification.metrics.pixels <=
                    200)) {
          // 触发分页加载
          EasyThrottle.throttle(
              'member_archives', const Duration(milliseconds: 500), () {
            _memberArchivesController.onLoad();
          });
        }
        return true;
      },
      child: RefreshIndicator(
        displacement: 10.0,
        edgeOffset: 10.0,
        onRefresh: _memberArchivesController.onRefresh, // 下拉刷新时触发的异步操作
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // Section分类Tab（仅在合集类型且有多个section时显示）
            Obx(() {
              if (_memberArchivesController.sections.length > 1) {
                return SliverToBoxAdapter(
                  child: _buildSectionTabs(context),
                );
              }
              return const SliverToBoxAdapter();
            }),
            SliverToBoxAdapter(
              child: Row(children: [
                TextButton.icon(
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  onPressed: _memberArchivesController.episodicButton,
                  label: Text(_memberArchivesController.episodicButtonText),
                ),
                const Spacer(),
                Obx(
                  () => TextButton.icon(
                    icon: const Icon(Icons.sort, size: 20),
                    onPressed: _memberArchivesController.toggleSort,
                    label:
                        Text(_memberArchivesController.currentOrder['label']!),
                  ),
                ),
              ]),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: StyleString.safeSpace),
              sliver: FutureBuilder(
                future: _futureBuilderFuture,
                builder: (BuildContext context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SliverToBoxAdapter();
                  }
                  if (snapshot.data == null) {
                    return HttpError(
                        errMsg: "投稿页出现错误",
                        fn: _memberArchivesController.onRefresh);
                  }
                  Map data = snapshot.data as Map;
                  List<SpaceArchiveItem> list =
                      _memberArchivesController.archivesList;
                  if (!data['status']) {
                    return HttpError(
                        errMsg: snapshot.data['msg'],
                        fn: _memberArchivesController.onRefresh);
                  }
                  return Obx(() {
                    if (list.isEmpty) return const SliverToBoxAdapter();
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithExtentAndRatio(
                          mainAxisSpacing: StyleString.safeSpace,
                          crossAxisSpacing: StyleString.safeSpace,
                          maxCrossAxisExtent: Grid.maxRowWidth * 2,
                          childAspectRatio: StyleString.aspectRatio * 2.4,
                          mainAxisExtent: 0),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, index) {
                          return VideoCardHMember(
                            videoItem: list[index],
                          );
                        },
                        childCount: list.length,
                      ),
                    );
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // 构建Section分类Tab
  Widget _buildSectionTabs(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _memberArchivesController.sections.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final section = _memberArchivesController.sections[index];
          return Obx(() {
            final isSelected =
                _memberArchivesController.currentSection.value?.id ==
                    section.id;
            return Material(
              color: isSelected
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _memberArchivesController.changeSection(section);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Center(
                    child: Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
