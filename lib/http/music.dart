import 'package:dio/dio.dart';
import 'package:PiliPalaX/http/api.dart';
import 'package:PiliPalaX/http/init.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/music/bgm_detail.dart';
import 'package:PiliPalaX/models/music/bgm_recommend_list.dart';
import 'package:PiliPalaX/utils/wbi_sign.dart';

/// 音乐相关HTTP请求
class MusicHttp {
  /// 获取BGM详情
  /// [musicId] 音乐ID
  static Future<LoadingState<MusicDetail>> bgmDetail(String musicId) async {
    try {
      final params = await WbiSign().makSign({
        'music_id': musicId,
        'relation_from': 'bgm_page',
      });
      final res = await Request().get(
        Api.bgmDetail,
        data: params,
      );
      if (res.data['code'] == 0) {
        return Success(MusicDetail.fromJson(res.data['data']));
      } else {
        return Error(res.data['message']);
      }
    } catch (e) {
      return Error(e.toString());
    }
  }

  /// 更新音乐点赞状态
  /// [musicId] 音乐ID
  /// [hasLike] 是否已点赞
  static Future<LoadingState<void>> wishUpdate(
    String musicId,
    bool hasLike,
  ) async {
    try {
      final csrf = await Request.getCsrf();
      final res = await Request().post(
        Api.wishUpdate,
        data: {
          'music_id': musicId,
          'state': hasLike ? 2 : 1,
          'csrf': csrf,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (res.data['code'] == 0) {
        return const Success(null);
      } else {
        return Error(res.data['message']);
      }
    } catch (e) {
      return Error(e.toString());
    }
  }

  /// 获取BGM推荐视频列表
  /// [musicId] 音乐ID
  static Future<LoadingState<List<BgmRecommend>?>> bgmRecommend(
    String musicId,
  ) async {
    try {
      final res = await Request().get(
        Api.bgmRecommend,
        data: {
          'music_id': musicId,
        },
      );
      if (res.data['code'] == 0) {
        final list = (res.data['data']?['list'] as List?)
            ?.map((i) => BgmRecommend.fromJson(i))
            .toList();
        return Success(list);
      } else {
        return Error(res.data['message']);
      }
    } catch (e) {
      return Error(e.toString());
    }
  }
}
