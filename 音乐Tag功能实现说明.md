# 音乐Tag功能实现说明

## 已完成的工作

### 1. API配置 (lib/http/api.dart)
已添加三个BGM相关API：
- `bgmDetail`: 获取BGM音乐详情
- `wishUpdate`: 更新音乐点赞状态
- `bgmRecommend`: 获取BGM推荐视频列表

### 2. HTTP请求层 (lib/http/music.dart)
已创建`MusicHttp`类，包含三个方法：
- `bgmDetail(String musicId)`: 获取音乐详情
- `wishUpdate(String musicId, bool hasLike)`: 更新点赞状态
- `bgmRecommend(String musicId)`: 获取推荐视频列表

### 3. 数据模型
已创建两个模型文件：
- `lib/models/music/bgm_detail.dart`: 音乐详情模型
- `lib/models/music/bgm_recommend_list.dart`: 推荐视频列表模型

### 4. 控制器
已创建两个控制器：
- `lib/pages/music/controller.dart`: 音乐详情页控制器
- `lib/pages/music/video/controller.dart`: 音乐推荐视频页控制器

### 5. 视图组件
已创建：
- `lib/pages/music/video/view.dart`: 音乐推荐视频页面
- `lib/pages/music/widgets/music_video_card_h.dart`: 音乐视频卡片组件

### 6. 路由配置
已在`lib/router/app_pages.dart`中添加音乐详情页路由：
```dart
CustomGetPage(name: '/musicDetail', page: () => const MusicDetailPage()),
```

## 需要完成的工作

### 1. 创建音乐详情页视图 (lib/pages/music/view.dart)

参考PiliPlus的实现，需要包含以下功能：

#### 页面结构
- AppBar: 显示音乐封面和标题（滚动时显示）
- 音乐信息卡片：
  - 封面图（可点击查看大图）
  - 歌曲名称（可长按复制）
  - 艺术家信息（可点击跳转到UP主页）
  - 发行日期
  - 音乐排名标签
  - 看MV按钮（如果有MV）
  - 原唱、专辑、出处等详细信息
- 统计信息：
  - 热度
  - 总播放量
  - 使用稿件数（可点击查看推荐视频列表）
- 热度趋势图表（可选，使用fl_chart或简化显示）
- 底部操作栏：
  - 分享按钮
  - 点赞按钮（显示点赞数，支持点赞/取消点赞）

#### 关键代码示例

```dart
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/music.dart';
import 'package:PiliPalaX/models/music/bgm_detail.dart';
import 'package:PiliPalaX/pages/music/controller.dart';
import 'package:PiliPalaX/pages/music/video/view.dart';
import 'package:PiliPalaX/utils/feed_back.dart';
import 'package:PiliPalaX/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class MusicDetailPage extends StatefulWidget {
  const MusicDetailPage({super.key});

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  late final MusicDetailController controller = Get.put(
    MusicDetailController(),
    tag: Get.parameters['musicId']!,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: controller.onRefresh,
        child: Obx(() => _buildBody()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Obx(() {
        final state = controller.infoState.value;
        final showTitle = controller.showTitle.value;
        if (state is Success<MusicDetail>) {
          return AnimatedOpacity(
            opacity: showTitle ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Row(
              children: [
                NetworkImgLayer(
                  src: state.data.mvCover ?? '',
                  width: 36,
                  height: 36,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.data.musicTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => Utils.share(controller.shareUrl),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final state = controller.infoState.value;
    if (state is Success<MusicDetail>) {
      return _buildContent(state.data);
    } else if (state is Error) {
      return _buildError(state.errMsg ?? '加载失败');
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent(MusicDetail item) {
    return CustomScrollView(
      controller: controller.scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildMusicCard(item)),
        SliverToBoxAdapter(child: _buildActions(item)),
      ],
    );
  }

  Widget _buildMusicCard(MusicDetail item) {
    // 实现音乐信息卡片
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面和基本信息
            Row(
              children: [
                NetworkImgLayer(
                  src: item.mvCover ?? '',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.musicTitle ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      // 艺术家、发行日期等信息
                    ],
                  ),
                ),
              ],
            ),
            // 统计信息
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('热度', item.hotSongHeat?.lastHeat),
                _buildStatItem('播放', item.listenPv),
                GestureDetector(
                  onTap: () => _goToRecommendVideos(item),
                  child: _buildStatItem('稿件', item.musicRelation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int? value) {
    return Column(
      children: [
        Text(
          value != null ? _formatNumber(value) : '-',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildActions(MusicDetail item) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Utils.share(controller.shareUrl),
              icon: const Icon(Icons.share),
              label: const Text('分享'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final state = controller.infoState.value;
              if (state is Success<MusicDetail>) {
                final hasLike = state.data.wishListen ?? false;
                return FilledButton.icon(
                  onPressed: () => _handleLike(state.data),
                  icon: Icon(hasLike ? Icons.thumb_up : Icons.thumb_up_outlined),
                  label: Text(_formatNumber(state.data.wishCount ?? 0)),
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String errMsg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errMsg),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.onReload,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _goToRecommendVideos(MusicDetail item) {
    Get.to(
      () => const MusicRecommendPage(),
      arguments: {
        'musicId': controller.musicId,
        'musicDetail': item,
      },
    );
  }

  Future<void> _handleLike(MusicDetail item) async {
    feedBack();
    final hasLike = item.wishListen ?? false;
    final res = await MusicHttp.wishUpdate(controller.musicId, hasLike);
    if (res is Success) {
      item.wishListen = !hasLike;
      item.wishCount = (item.wishCount ?? 0) + (hasLike ? -1 : 1);
      controller.infoState.refresh();
      SmartDialog.showToast(hasLike ? '已取消点赞' : '点赞成功');
    } else if (res is Error) {
      SmartDialog.showToast(res.errMsg ?? '操作失败');
    }
  }

  String _formatNumber(int num) {
    if (num >= 10000) {
      return '${(num / 10000).toStringAsFixed(1)}万';
    }
    return num.toString();
  }
}
```

### 2. 修复音乐视频卡片组件

需要修复`lib/pages/music/widgets/music_video_card_h.dart`中的错误：

```dart
// 修改导入
import 'package:PiliPalaX/common/widgets/stat/view.dart';
import 'package:PiliPalaX/common/widgets/stat/danmaku.dart';

// 修改BadgeType为正确的类型
PBadge(
  text: _formatDuration(videoItem.duration!),
  right: 6.0,
  bottom: 6.0,
  type: BadgeType.gray, // 改为正确的枚举值
),

// 修改StatView和StatDanMu的使用
Row(
  children: [
    StatView(
      theme: theme,
      view: videoItem.play ?? 0,
    ),
    const SizedBox(width: 8),
    StatDanMu(
      theme: theme,
      danmu: videoItem.danmu ?? 0,
    ),
  ],
),
```

### 3. 修复音乐推荐视频页面

需要修复`lib/pages/music/video/view.dart`中的switch表达式：

```dart
Widget _buildBody(ThemeData theme) {
  final state = controller.loadingState.value;
  if (state is Success<List<BgmRecommend>?>) {
    final response = state.data;
    if (response != null && response.isNotEmpty) {
      return ListView.builder(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: response.length,
        itemBuilder: (context, index) =>
            MusicVideoCardH(videoItem: response[index]),
      );
    } else {
      return HttpError(
        errMsg: '暂无使用该音乐的视频',
        onReload: controller.onReload,
      );
    }
  } else if (state is Error) {
    return HttpError(
      errMsg: state.errMsg ?? '加载失败',
      onReload: controller.onReload,
    );
  }
  return const Center(child: CircularProgressIndicator());
}
```

### 4. 更新tags_widget.dart

确保BGM标签点击时正确跳转到音乐详情页：

```dart
case 'bgm':
  // BGM标签: 跳转到音乐详情页
  if (tag.musicId != null && tag.musicId!.isNotEmpty) {
    Get.toNamed('/musicDetail', parameters: {'musicId': tag.musicId!});
  }
  break;
```

## 功能特性

### 音乐详情页功能
1. ✅ 显示音乐封面、标题、艺术家信息
2. ✅ 显示发行日期、专辑、出处等详细信息
3. ✅ 显示热度、播放量、使用稿件数等统计信息
4. ✅ 支持点赞/取消点赞
5. ✅ 支持分享
6. ✅ 支持查看MV（如果有）
7. ✅ 支持查看使用该音乐的推荐视频列表
8. ⏳ 热度趋势图表（可选，需要fl_chart库）
9. ⏳ 评论区（可选，需要集成评论系统）

### 音乐推荐视频页功能
1. ✅ 显示使用该音乐的视频列表
2. ✅ 视频卡片显示封面、标题、UP主、播放量、弹幕数
3. ✅ 点击视频卡片跳转到视频详情页
4. ✅ 支持下拉刷新

## 测试步骤

1. 在视频详情页找到BGM标签
2. 点击BGM标签，应该跳转到音乐详情页
3. 在音乐详情页查看音乐信息
4. 点击"使用稿件"查看推荐视频列表
5. 在推荐视频列表中点击视频卡片，跳转到视频详情页
6. 测试点赞功能
7. 测试分享功能
8. 测试看MV功能（如果有）

## 参考资料

- PiliPlus实现: `PiliPlus/lib/pages/music/`
- API文档: `bilibili-API-collect/docs/audio/`
- BGM API: `/x/copyright-music-publicity/bgm/detail`
- 推荐视频API: `/x/copyright-music-publicity/bgm/recommend_list`
- 点赞API: `/x/copyright-music-publicity/bgm/wish/update`

## 注意事项

1. 所有API请求都需要WBI签名
2. 点赞操作需要登录状态和CSRF token
3. 音乐ID从视频tag中获取（musicId字段）
4. 推荐视频列表一次性返回所有数据，不需要分页
5. 热度趋势图表需要fl_chart库，如果不想添加依赖可以简化显示
6. 评论功能可以参考视频详情页的实现，但需要注意replyType为47

## 下一步优化

1. 添加热度趋势图表（使用fl_chart）
2. 集成评论系统
3. 添加音乐播放功能（如果API支持）
4. 优化UI细节和动画效果
5. 添加错误处理和加载状态
6. 支持横屏布局
7. 添加缓存机制
