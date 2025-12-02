import 'package:PiliPalaX/common/widgets/list_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/models/video_detail_res.dart';
import 'package:PiliPalaX/pages/video/index.dart';
import 'package:PiliPalaX/pages/video/introduction/detail/controller.dart';

class SeasonPanel extends StatefulWidget {
  const SeasonPanel({
    super.key,
    required this.ugcSeason,
    this.cid,
    required this.changeFuc,
    required this.heroTag,
  });
  final UgcSeason ugcSeason;
  final int? cid;
  final Function changeFuc;
  final String heroTag;

  @override
  State<SeasonPanel> createState() => _SeasonPanelState();
}

class _SeasonPanelState extends State<SeasonPanel> {
  List<EpisodeItem>? episodes;
  late int cid;
  int currentIndex = 0;
  // final String heroTag = Get.arguments['heroTag'];
  late final String heroTag;
  late VideoDetailController _videoDetailController;
  late VideoIntroController _videoIntroController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    heroTag = widget.heroTag;
    _videoDetailController = Get.find<VideoDetailController>(tag: heroTag);
    _videoIntroController = Get.find<VideoIntroController>(tag: heroTag);
    initEpisodes();

    _videoDetailController.cid.listen((int p0) {
      cid = p0;
      if (episodes != null) {
        currentIndex = episodes!.indexWhere((EpisodeItem e) => e.cid == cid);
        if (currentIndex == -1) {
          String currentBvid = _videoDetailController.bvid;
          currentIndex =
              episodes!.indexWhere((EpisodeItem e) => e.bvid == currentBvid);
        }
        if (currentIndex == -1) {
          int currentAid = _videoDetailController.oid.value;
          currentIndex =
              episodes!.indexWhere((EpisodeItem e) => e.aid == currentAid);
        }
        if (!mounted) return;
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(SeasonPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cid != oldWidget.cid ||
        widget.ugcSeason != oldWidget.ugcSeason) {
      initEpisodes();
    }
  }

  void initEpisodes() {
    cid = widget.cid!;
    final List<SectionItem> sections = widget.ugcSeason.sections!;
    episodes = null;

    // 1. Try to find by CID first
    for (int i = 0; i < sections.length; i++) {
      final List<EpisodeItem> episodesList = sections[i].episodes!;
      for (int j = 0; j < episodesList.length; j++) {
        if (episodesList[j].cid == cid) {
          episodes = episodesList;
          break;
        }
      }
      if (episodes != null) break;
    }

    // 2. If not found by CID, try by BVID
    if (episodes == null) {
      String currentBvid = _videoDetailController.bvid;
      for (int i = 0; i < sections.length; i++) {
        final List<EpisodeItem> episodesList = sections[i].episodes!;
        for (int j = 0; j < episodesList.length; j++) {
          if (episodesList[j].bvid == currentBvid) {
            episodes = episodesList;
            break;
          }
        }
        if (episodes != null) break;
      }
    }

    // 3. If not found by BVID, try by AID
    if (episodes == null) {
      int currentAid = _videoDetailController.oid.value;
      if (currentAid != 0) {
        for (int i = 0; i < sections.length; i++) {
          final List<EpisodeItem> episodesList = sections[i].episodes!;
          for (int j = 0; j < episodesList.length; j++) {
            if (episodesList[j].aid == currentAid) {
              episodes = episodesList;
              break;
            }
          }
          if (episodes != null) break;
        }
      }
    }

    if (episodes != null) {
      currentIndex = episodes!.indexWhere((EpisodeItem e) => e.cid == cid);
      if (currentIndex == -1) {
        String currentBvid = _videoDetailController.bvid;
        currentIndex =
            episodes!.indexWhere((EpisodeItem e) => e.bvid == currentBvid);
      }
      if (currentIndex == -1) {
        int currentAid = _videoDetailController.oid.value;
        currentIndex =
            episodes!.indexWhere((EpisodeItem e) => e.aid == currentAid);
      }
    }
  }

  // void changeFucCall(item, int i) async {
  //   await widget.changeFuc!(
  //     IdUtils.av2bv(item.aid),
  //     item.cid,
  //     item.aid,
  //   );
  //   currentIndex = i;
  //   Get.back();
  //   setState(() {});
  // }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (episodes == null) {
      return const SizedBox();
    }
    return Builder(builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.only(
          top: 8,
          left: 2,
          right: 2,
          bottom: 2,
        ),
        child: Material(
          color: Theme.of(context).colorScheme.onInverseSurface,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () {
              ListSheet(
                      episodes: episodes,
                      bvid: _videoDetailController.bvid,
                      aid: _videoDetailController.oid.value,
                      currentCid: cid,
                      changeFucCall: widget.changeFuc,
                      context: context,
                      pages: _videoIntroController.videoDetail.value.pages)
                  .buildShowBottomSheet();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '合集：${widget.ugcSeason.title!}',
                      style: Theme.of(context).textTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Image.asset(
                    'assets/images/live.png',
                    color: Theme.of(context).colorScheme.primary,
                    height: 12,
                    semanticLabel: "正在播放：",
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${currentIndex + 1}/${episodes!.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                    semanticsLabel:
                        '第${currentIndex + 1}集，共${episodes!.length}集',
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 13,
                    semanticLabel: '查看',
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
