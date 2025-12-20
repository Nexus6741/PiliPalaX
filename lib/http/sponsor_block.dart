import 'dart:convert';
import 'package:PiliPalaX/http/init.dart';
import 'package:PiliPalaX/http/sponsor_block_api.dart';
import 'package:PiliPalaX/models_new/sponsor_block/segment_item.dart';
import 'package:PiliPalaX/models_new/sponsor_block/user_info.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:dio/dio.dart';

/// SponsorBlock API
/// https://github.com/hanydd/BilibiliSponsorBlock/wiki/API
class SponsorBlock {
  static String get blockServer => GStorage.setting
      .get('blockServer', defaultValue: 'https://api.biliplus.com') as String;

  static final options = Options(
    followRedirects: true,
    validateStatus: (status) => true,
  );

  static String _api(String url) => '$blockServer/api/$url';

  /// 获取跳过片段
  static Future<Map<String, dynamic>> getSkipSegments({
    required String bvid,
    required int cid,
  }) async {
    try {
      final res = await Request().get(
        _api(SponsorBlockApi.skipSegments),
        data: {
          'videoID': bvid,
          'cid': cid,
        },
        options: options,
      );

      if (res.statusCode == 200) {
        if (res.data is List) {
          final list = (res.data as List)
              .map((i) => SegmentItemModel.fromJson(i))
              .toList();
          return {'code': 0, 'data': list};
        }
      }
      return {'code': res.statusCode ?? -1, 'msg': '获取片段失败'};
    } catch (e) {
      return {'code': -1, 'msg': e.toString()};
    }
  }

  /// 投票
  static Future<Map<String, dynamic>> voteOnSponsorTime({
    required String uuid,
    int? type,
    String? category,
  }) async {
    try {
      final userId = GStorage.setting.get('blockUserID', defaultValue: '');
      final res = await Request().post(
        _api(SponsorBlockApi.voteOnSponsorTime),
        data: {
          'UUID': uuid,
          if (type != null) 'type': type,
          if (category != null) 'category': category,
          'userID': userId,
        },
        options: options,
      );
      return {
        'code': res.statusCode == 200 ? 0 : res.statusCode ?? -1,
        'msg': res.statusCode == 200 ? 'success' : '投票失败'
      };
    } catch (e) {
      return {'code': -1, 'msg': e.toString()};
    }
  }

  /// 标记已观看
  static Future<Map<String, dynamic>> viewedVideoSponsorTime(
      String uuid) async {
    try {
      final res = await Request().post(
        _api(SponsorBlockApi.viewedVideoSponsorTime),
        data: {'UUID': uuid},
        options: options,
      );
      return {
        'code': res.statusCode == 200 ? 0 : res.statusCode ?? -1,
        'msg': res.statusCode == 200 ? 'success' : '标记失败'
      };
    } catch (e) {
      return {'code': -1, 'msg': e.toString()};
    }
  }

  /// 检查服务器状态
  static Future<Map<String, dynamic>> uptimeStatus() async {
    try {
      final res = await Request().get(
        _api(SponsorBlockApi.uptimeStatus),
        options: options,
      );
      if (res.statusCode == 200 && res.data is String) {
        return {'code': 0, 'msg': 'success'};
      }
      return {'code': res.statusCode ?? -1, 'msg': '服务器异常'};
    } catch (e) {
      return {'code': -1, 'msg': e.toString()};
    }
  }

  /// 获取用户信息
  static Future<Map<String, dynamic>> userInfo(
    List<String> query, {
    String? userId,
  }) async {
    try {
      final defaultUserId =
          GStorage.setting.get('blockUserID', defaultValue: '');
      final res = await Request().get(
        _api(SponsorBlockApi.userInfo),
        data: {
          'userID': userId ?? defaultUserId,
          'values': jsonEncode(query),
        },
        options: options,
      );
      if (res.statusCode == 200) {
        return {'code': 0, 'data': UserInfo.fromJson(res.data)};
      }
      return {'code': res.statusCode ?? -1, 'msg': '获取用户信息失败'};
    } catch (e) {
      return {'code': -1, 'msg': e.toString()};
    }
  }
}
