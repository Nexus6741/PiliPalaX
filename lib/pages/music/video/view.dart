import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/music/bgm_recommend_list.dart';
import 'package:PiliPalaX/pages/music/video/controller.dart';
import 'package:PiliPalaX/pages/music/widgets/music_video_card_h.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 音乐推荐视频页面
class MusicRecommendPage extends StatefulWidget {
  const MusicRecommendPage({super.key});

  @override
  State<MusicRecommendPage> createState() => _MusicRecommendPageState();
}

class _MusicRecommendPageState extends State<MusicRecommendPage> {
  late final MusicRecommendController controller = Get.put(
    MusicRecommendController(),
    tag: (Get.arguments as Map)['musicId'],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: _buildAppBar(theme),
      body: RefreshIndicator(
        onRefresh: controller.onRefresh,
        child: Obx(() => _buildBody(theme)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final info = controller.musicDetail;
    return AppBar(
      title: Row(
        children: [
          NetworkImgLayer(
            width: 40,
            height: 40,
            src: info.mvCover ?? '',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.musicTitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                Obx(() {
                  final state = controller.loadingState.value;
                  int? count;
                  if (state is Success<List<BgmRecommend>?>) {
                    count = state.data?.length;
                  }
                  return count == null
                      ? const SizedBox.shrink()
                      : Text(
                          '共$count条视频',
                          style: theme.textTheme.labelMedium,
                        );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final state = controller.loadingState.value;
    if (state is Success<List<BgmRecommend>?>) {
      final response = state.data;
      if (response != null && response.isNotEmpty) {
        return ListView.builder(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: response.length,
          itemBuilder: (context, index) {
            return MusicVideoCardH(videoItem: response[index]);
          },
        );
      } else {
        return HttpError(
          errMsg: '暂无使用该音乐的视频',
          fn: controller.onReload,
        );
      }
    } else if (state is Error<List<BgmRecommend>?>) {
      return HttpError(
        errMsg: state.errMsg ?? '加载失败',
        fn: controller.onReload,
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
