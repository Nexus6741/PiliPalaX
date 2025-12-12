// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/pages/msg_feed_top/at_me/view.dart';
import 'package:PiliPalaX/pages/msg_feed_top/reply_me/view.dart';
import 'package:PiliPalaX/pages/msg_feed_top/like_me/view.dart';
import 'package:PiliPalaX/pages/follow_search/view.dart';
import 'package:PiliPalaX/pages/setting/pages/logs.dart';
import 'package:PiliPalaX/pages/dynamics_topic/view.dart';

import '../pages/about/index.dart';
import '../pages/blacklist/index.dart';
import '../pages/danmaku_block/index.dart';
import '../pages/dynamics/detail/index.dart';
import '../pages/dynamics/index.dart';
import '../pages/dynamics_create/simple_view_fixed.dart';
import '../pages/fan/index.dart';
import '../pages/fav/index.dart';
import '../pages/fav_detail/index.dart';
import '../pages/fav_search/index.dart';
import '../pages/follow/index.dart';
import '../pages/history/index.dart';
import '../pages/history_search/index.dart';
import '../pages/home/index.dart';
import '../pages/hot/index.dart';
import '../pages/html/index.dart';
import '../pages/later/index.dart';
import '../pages/live_area/view.dart';
import '../pages/live_area_detail/view.dart';
import '../pages/live_dm_block/view.dart';
import '../pages/live_follow/view.dart';
import '../pages/live_room/view.dart';
import '../pages/login/index.dart';
import '../pages/media/index.dart';
import '../pages/member/index.dart';
import '../pages/pgc/view.dart';
import '../pages/pgc/controller.dart';
import '../pages/pgc_index/view.dart';
import '../pages/member_coin/index.dart';
import '../pages/member_like/index.dart';
import '../pages/member_search/index.dart';
import '../pages/member_season/view.dart';
import '../pages/member_series/view.dart';
import '../pages/msg_feed_top/sys_msg/view.dart';
import '../pages/search/index.dart';
import '../pages/search_result/index.dart';
import '../pages/setting/extra_setting.dart';
import '../pages/setting/index.dart';
import '../pages/setting/pages/color_select.dart';
import '../pages/setting/pages/display_mode.dart';
import '../pages/setting/pages/font_size_select.dart';
import '../pages/setting/pages/gesture_select.dart';
import '../pages/setting/pages/home_tabbar_set.dart';
import '../pages/setting/pages/play_speed_set.dart';
import '../pages/setting/recommend_setting.dart';
import '../pages/setting/play_setting.dart';
import '../pages/setting/video_setting.dart';
import '../pages/setting/privacy_setting.dart';
import '../pages/setting/style_setting.dart';
import '../pages/setting/hidden_settings.dart';
import '../pages/subscription/index.dart';
import '../pages/subscription_detail/index.dart';
import '../pages/video/index.dart';
import '../pages/video/reply_reply/index.dart';
import '../pages/webview/index.dart';
import '../pages/whisper/index.dart';
import '../pages/whisper_detail/index.dart';
import '../utils/storage.dart';

Box<dynamic> setting = GStorage.setting;

class Routes {
  static final List<GetPage<dynamic>> getPages = [
    // 首页(推荐)
    CustomGetPage(name: '/', page: () => const HomePage()),
    // 热门
    CustomGetPage(name: '/hot', page: () => const HotPage()),
    // 视频详情
    GetPage(
      name: '/video',
      page: () => const VideoDetailPage(),
      customTransition: EnterFadeInExitNoneTransition(),
      // transition: Transition.fadeIn,
      curve: Curves.fastOutSlowIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    // 图片预览
    // GetPage(
    //   name: '/preview',
    //   page: () => const ImagePreview(),
    //   transition: Transition.fade,
    //   transitionDuration: const Duration(milliseconds: 300),
    //   showCupertinoParallax: false,
    // ),
    //
    CustomGetPage(name: '/webview', page: () => const WebviewPage()),
    // 设置
    CustomGetPage(name: '/setting', page: () => const SettingPage()),
    //
    CustomGetPage(name: '/media', page: () => const MediaPage()),
    // 番剧分区
    CustomGetPage(
        name: '/bangumi',
        page: () => const PgcPage(tabType: PgcTabType.bangumi)),
    // 影视分区
    CustomGetPage(
        name: '/cinema', page: () => const PgcPage(tabType: PgcTabType.cinema)),
    // 影视索引页面
    CustomGetPage(name: '/pgcIndex', page: () => const PgcIndexPage()),
    //
    CustomGetPage(name: '/fav', page: () => const FavPage()),
    //
    CustomGetPage(name: '/favDetail', page: () => const FavDetailPage()),
    // 稍后再看
    CustomGetPage(name: '/later', page: () => const LaterPage()),
    // 历史记录
    CustomGetPage(name: '/history', page: () => const HistoryPage()),
    // 搜索页面 - 使用自定义展开动画（从首页搜索框展开）
    // 注意：实际动画由 SearchExpandPageRoute 处理，这里作为备用
    GetPage(
      name: '/search',
      page: () => const SearchPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
      popGesture: false,
      preventDuplicates: true,
      opaque: true,
    ),
    // 搜索结果 - 使用从底部滑出的动画
    GetPage(
      name: '/searchResult',
      page: () => const SearchResultPage(),
      customTransition: BottomSlideUpTransition(),
      transitionDuration: const Duration(milliseconds: 450),
      popGesture: true,
      preventDuplicates: true,
      opaque: true,
    ),
    // 动态
    CustomGetPage(name: '/dynamics', page: () => const DynamicsPage()),
    // 创建动态
    CustomGetPage(
        name: '/dynamics/create', page: () => const SimpleDynamicCreatePage()),
    // 动态详情
    CustomGetPage(
        name: '/dynamicDetail', page: () => const DynamicDetailPage()),
    // 关注
    CustomGetPage(name: '/follow', page: () => const FollowPage()),
    // 粉丝
    CustomGetPage(name: '/fan', page: () => const FansPage()),
    // 直播详情 - 使用从右下角展开的动画
    GetPage(
      name: '/liveRoom',
      page: () => const LiveRoomPage(),
      customTransition: BottomRightExpandTransition(),
      transitionDuration: const Duration(milliseconds: 500),
      popGesture: false,
    ),
    // 直播关注
    CustomGetPage(name: '/liveFollow', page: () => const LiveFollowPage()),
    // 直播全部标签
    CustomGetPage(name: '/liveArea', page: () => const LiveAreaPage()),
    // 直播分区详情
    CustomGetPage(
        name: '/liveAreaDetail', page: () => const LiveAreaDetailPage()),
    // 直播弹幕屏蔽
    CustomGetPage(
        name: '/liveDmBlockPage', page: () => const LiveDmBlockPage()),
    // 用户中心
    CustomGetPage(name: '/member', page: () => const MemberPage()),
    CustomGetPage(name: '/memberSearch', page: () => const MemberSearchPage()),
    // 二级回复
    CustomGetPage(
        name: '/replyReply', page: () => const VideoReplyReplyPanel()),
    // 推荐流设置
    CustomGetPage(
        name: '/recommendSetting', page: () => const RecommendSetting()),
    // 音视频设置
    CustomGetPage(name: '/videoSetting', page: () => const VideoSetting()),
    // 播放器设置
    CustomGetPage(name: '/playSetting', page: () => const PlaySetting()),
    // 外观设置
    CustomGetPage(name: '/styleSetting', page: () => const StyleSetting()),
    // 隐私设置
    CustomGetPage(name: '/privacySetting', page: () => const PrivacySetting()),
    // 其它设置
    CustomGetPage(name: '/extraSetting', page: () => const ExtraSetting()),
    //
    CustomGetPage(name: '/blackListPage', page: () => const BlackListPage()),
    CustomGetPage(name: '/colorSetting', page: () => const ColorSelectPage()),
    CustomGetPage(
        name: '/gestureSetting', page: () => const GestureSelectPage()),
    // 开发人员选项
    CustomGetPage(name: '/hiddenSetting', page: () => const HiddenSetting()),
    // 首页tabbar
    CustomGetPage(name: '/tabbarSetting', page: () => const TabbarSetPage()),
    CustomGetPage(
        name: '/fontSizeSetting', page: () => const FontSizeSelectPage()),
    // 屏幕帧率
    CustomGetPage(
        name: '/displayModeSetting', page: () => const SetDisplayMode()),
    // 关于
    CustomGetPage(name: '/about', page: () => const AboutPage()),
    //
    CustomGetPage(name: '/htmlRender', page: () => const HtmlRenderPage()),
    // 历史记录搜索
    CustomGetPage(
        name: '/historySearch', page: () => const HistorySearchPage()),

    CustomGetPage(name: '/playSpeedSet', page: () => const PlaySpeedPage()),
    // 收藏搜索
    CustomGetPage(name: '/favSearch', page: () => const FavSearchPage()),
    // 消息页面
    CustomGetPage(name: '/whisper', page: () => const WhisperPage()),
    // 私信详情
    CustomGetPage(
        name: '/whisperDetail', page: () => const WhisperDetailPage()),
    // 回复我的
    CustomGetPage(name: '/replyMe', page: () => const ReplyMePage()),
    // @我的
    CustomGetPage(name: '/atMe', page: () => const AtMePage()),
    // 收到的赞
    CustomGetPage(name: '/likeMe', page: () => const LikeMePage()),
    // 系统消息
    CustomGetPage(name: '/sysMsg', page: () => const SysMsgPage()),
    // 登录页面
    CustomGetPage(name: '/loginPage', page: () => const LoginPage()),
    // 用户动态
    // CustomGetPage(
    //     name: '/memberDynamics', page: () => const MemberDynamicsPage()),
    // 用户投稿
    // CustomGetPage(
    //     name: '/memberArchive', page: () => const MemberArchivePage()),
    // 用户最近投币
    CustomGetPage(name: '/memberCoin', page: () => const MemberCoinPage()),
    // 用户最近喜欢
    CustomGetPage(name: '/memberLike', page: () => const MemberLikePage()),
    // 用户专栏
    // CustomGetPage(
    //     name: '/memberSeasons', page: () => const MemberSeasonsPage()),
    CustomGetPage(name: '/memberSeason', page: () => const MemberSeasonPage()),

    CustomGetPage(name: '/memberSeries', page: () => const MemberSeriesPage()),
    // 日志
    CustomGetPage(name: '/logs', page: () => const LogsPage()),
    // 搜索关注
    CustomGetPage(name: '/followSearch', page: () => const FollowSearchPage()),
    // 订阅
    CustomGetPage(name: '/subscription', page: () => const SubPage()),
    // 订阅详情
    CustomGetPage(name: '/subDetail', page: () => const SubDetailPage()),
    // 弹幕屏蔽管理
    CustomGetPage(name: '/danmakuBlock', page: () => const DanmakuBlockPage()),
    // 话题页
    CustomGetPage(
        name: '/dynamicsTopic', page: () => const DynamicsTopicPage()),
  ];
}

class CustomGetPage extends GetPage<dynamic> {
  CustomGetPage({
    required super.name,
    required super.page,
    this.fullscreen,
    super.transitionDuration,
  }) : super(
          curve: Curves.linear,
          transition: Transition.native,
          showCupertinoParallax: false,
          popGesture: false,
          fullscreenDialog: fullscreen != null && fullscreen,
        );
  bool? fullscreen = false;
}

class EnterFadeInExitNoneTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve ?? Curves.linear,
        reverseCurve: const Threshold(1.0),
      ),
      child: child,
    );
  }
}

/// 从右下角展开的"神奇"效果过渡动画 - 带圆角变形
/// 进入时从右下角展开，离开时从左上角收缩
/// 性能优化版本
class BottomRightExpandTransition extends CustomTransition {
  // 缓存曲线对象，避免重复创建
  static const _scaleCurve = Cubic(0.25, 0.1, 0.25, 1.0);
  static const _borderRadiusCurve = Curves.easeOutQuart;

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 缓存屏幕尺寸，避免每帧查询
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return AnimatedBuilder(
      animation: animation,
      // 使用 child 参数避免重建子树
      child: child,
      builder: (context, cachedChild) {
        final animValue = animation.value;
        final isReversing = animation.status == AnimationStatus.reverse;

        // 计算进度和尺寸
        final progress = _scaleCurve.transform(animValue);
        final currentWidth = screenWidth * progress;
        final currentHeight = screenHeight * progress;
        final borderRadius =
            500.0 * (1.0 - _borderRadiusCurve.transform(animValue));

        // 根据方向选择位置参数
        final left = isReversing ? 0.0 : null;
        final top = isReversing ? 0.0 : null;
        final right = isReversing ? null : 0.0;
        final bottom = isReversing ? null : 0.0;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              right: right,
              bottom: bottom,
              width: currentWidth,
              height: currentHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: cachedChild!,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 幕布式下落过渡动画 - 极致性能优化版
/// 幕布式下落过渡动画 - 极致性能优化版
/// 页面从顶部像幕布一样优雅地落下，带有弹跳效果
/// 退出时快速向上收起
class CurtainDropTransition extends CustomTransition {
  // 缓存 Tween 对象，避免重复创建
  static final _slideTween = Tween<Offset>(
    begin: const Offset(0.0, -1.0),
    end: Offset.zero,
  );

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 根据动画方向使用不同的曲线
    // 进入动画使用 bounceOut，退出动画使用 easeInCubic
    final dropAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut, // 进入时的弹跳效果
      reverseCurve: Curves.easeInCubic, // 退出时的快速加速
    );

    // 使用 SlideTransition 替代手动计算，性能更好
    // RepaintBoundary 放在最外层，减少整个动画树的重绘
    return RepaintBoundary(
      child: SlideTransition(
        position: _slideTween.animate(dropAnimation),
        // 使用 transformHitTests: false 提升性能（动画期间不需要点击检测）
        transformHitTests: false,
        // 子组件也用 RepaintBoundary 包裹，进一步隔离重绘
        child: RepaintBoundary(
          child: child,
        ),
      ),
    );
  }
}

/// 底部滑出过渡动画 - 性能优化版
/// 页面从底部自然流畅地滑出，使用非线性曲线
/// 退出时向下滑出
class BottomSlideUpTransition extends CustomTransition {
  // 缓存 Tween 对象，避免重复创建
  static final _slideTween = Tween<Offset>(
    begin: const Offset(0.0, 1.0), // 从底部开始
    end: Offset.zero,
  );

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 使用非线性曲线，让动画更自然流畅
    // 进入：快速启动，平滑减速
    // 退出：平滑加速
    final slideAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic, // 进入时平滑减速
      reverseCurve: Curves.easeInCubic, // 退出时平滑加速
    );

    // 使用 SlideTransition 提供最佳性能
    // RepaintBoundary 隔离重绘范围
    return RepaintBoundary(
      child: SlideTransition(
        position: _slideTween.animate(slideAnimation),
        transformHitTests: false, // 动画期间禁用点击检测，提升性能
        child: RepaintBoundary(
          child: child,
        ),
      ),
    );
  }
}
