import 'dart:convert';

import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/http/constants.dart';
import 'package:PiliPalaX/http/init.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/sponsor_block_api.dart';
import 'package:PiliPalaX/models/common/sponsor_block/post_segment_model.dart';
import 'package:PiliPalaX/models/common/sponsor_block/segment_type.dart';
import 'package:PiliPalaX/models_new/sponsor_block/segment_item.dart';
import 'package:PiliPalaX/models_new/sponsor_block/user_info.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:dio/dio.dart';

/// https://github.com/hanydd/BilibiliSponsorBlock/wiki/API
abstract class SponsorBlock {
  static String get blockServer => GStorage.setting
      .get('blockServer', defaultValue: HttpString.sponsorBlockBaseUrl);

  static final options = Options(
    followRedirects: true,
    validateStatus: (status) => true,
  );

  static Error getErrMsg(Response res) {
    String statusMessage;
    switch (res.statusCode) {
      case 200:
        statusMessage = '意料之外的响应';
        break;
      case 400:
        statusMessage = '参数错误';
        break;
      case 403:
        statusMessage = '被自动审核机制拒绝';
        break;
      case 404:
        statusMessage = '未找到数据';
        break;
      case 409:
        statusMessage = '重复提交';
        break;
      case 429:
        statusMessage = '提交太快（触发速率控制）';
        break;
      case 500:
        statusMessage = '服务器无法获取信息';
        break;
      case -1:
        statusMessage = res.data['message'].toString();
        break;
      default:
        statusMessage = res.statusMessage ?? res.statusCode.toString();
    }

    if (res.statusCode != null && res.statusCode != -1) {
      final data = res.data;
      if (res.statusCode == 200 ||
          (data is String && data.isNotEmpty && data.length < 200)) {
        statusMessage = '$statusMessage：$data';
      }
    }
    return Error(statusMessage, code: res.statusCode);
  }

  static String _api(String url) => '$blockServer/api/$url';

  static Future<LoadingState> getSkipSegments({
    required String bvid,
    required int cid,
  }) async {
    try {
      print('🔍 [SponsorBlock.getSkipSegments] 请求参数: bvid=$bvid, cid=$cid');

      final res = await Request().get(
        _api(SponsorBlockApi.skipSegments),
        data: {
          'videoID': bvid,
          'cid': cid,
        },
        options: options,
      );

      // print('🔍 [SponsorBlock.getSkipSegments] 响应状态码: ${res.statusCode}');
      // print(
      //     '🔍 [SponsorBlock.getSkipSegments] 响应数据类型: ${res.data.runtimeType}');
      // print('🔍 [SponsorBlock.getSkipSegments] 响应数据: ${res.data}');

      if (res.statusCode == 200) {
        if (res.data is List) {
          final list = res.data as List;
          // print('✅ [SponsorBlock.getSkipSegments] 解析列表，长度: ${list.length}');
          return Success(
            list.map((i) => SegmentItemModel.fromJson(i)).toList(),
          );
        } else {
          // print('⚠️ [SponsorBlock.getSkipSegments] 响应不是列表');
        }
      }
      return getErrMsg(res);
    } catch (e) {
      // print('❌ [SponsorBlock.getSkipSegments] 异常: $e');
      return Error(e.toString());
    }
  }

  static Future<LoadingState> voteOnSponsorTime({
    required String uuid,
    int? type,
    SegmentType? category,
  }) async {
    assert((type == null) == (category == null));
    try {
      final String blockUserID =
          GStorage.setting.get('blockUserID', defaultValue: '');
      final res = await Request().post(
        _api(SponsorBlockApi.voteOnSponsorTime),
        data: {
          'UUID': uuid,
          if (type != null) 'type': type,
          if (category != null) 'category': category.name,
          'userID': blockUserID,
        },
        options: options,
      );
      return res.statusCode == 200 ? const Success(null) : getErrMsg(res);
    } catch (e) {
      return Error(e.toString());
    }
  }

  static Future<LoadingState> viewedVideoSponsorTime(String uuid) async {
    try {
      final res = await Request().post(
        _api(SponsorBlockApi.viewedVideoSponsorTime),
        data: {'UUID': uuid},
        options: options,
      );
      return res.statusCode == 200 ? const Success(null) : getErrMsg(res);
    } catch (e) {
      return Error(e.toString());
    }
  }

  static Future<LoadingState> uptimeStatus() async {
    try {
      final res = await Request().get(
        _api(SponsorBlockApi.uptimeStatus),
        options: options,
      );
      if (res.statusCode == 200 &&
          res.data is String &&
          _isStringNumeric(res.data)) {
        return const Success(null);
      }
      return getErrMsg(res);
    } catch (e) {
      return Error(e.toString());
    }
  }

  static bool _isStringNumeric(String str) {
    return double.tryParse(str) != null;
  }

  static Future<LoadingState> userInfo(
    List<String> query, {
    String? userId,
  }) async {
    try {
      final String blockUserID =
          GStorage.setting.get('blockUserID', defaultValue: '');
      final res = await Request().get(
        _api(SponsorBlockApi.userInfo),
        data: {
          'userID': userId ?? blockUserID,
          'values': jsonEncode(query),
        },
        options: options,
      );
      if (res.statusCode == 200) {
        return Success(UserInfo.fromJson(res.data));
      }
      return getErrMsg(res);
    } catch (e) {
      return Error(e.toString());
    }
  }

  static Future<LoadingState> postSkipSegments({
    required String bvid,
    required int cid,
    required double videoDuration,
    required List<PostSegmentModel> segments,
  }) async {
    try {
      final String blockUserID =
          GStorage.setting.get('blockUserID', defaultValue: '');
      final res = await Request().post(
        _api(SponsorBlockApi.skipSegments),
        data: {
          'videoID': bvid,
          'cid': cid.toString(),
          'userID': blockUserID,
          'userAgent': Constants.userAgent,
          'videoDuration': videoDuration,
          'segments': segments
              .map(
                (item) => {
                  'segment': [item.segment.first, item.segment.second],
                  'category': item.category.name,
                  'actionType': item.actionType.name,
                },
              )
              .toList(),
        },
        options: options,
      );

      if (res.statusCode == 200) {
        if (res.data is List) {
          final list = res.data as List;
          return Success(
            list.map((i) => SegmentItemModel.fromJson(i)).toList(),
          );
        }
      }
      return getErrMsg(res);
    } catch (e) {
      return Error(e.toString());
    }
  }

  static Future<LoadingState> getPortVideo({
    required String bvid,
    required int cid,
  }) async {
    try {
      final res = await Request().get(
        _api(SponsorBlockApi.portVideo),
        data: {
          'videoID': bvid,
          'cid': cid.toString(),
        },
        options: options,
      );

      if (res.statusCode == 200) {
        if (res.data is Map<String, dynamic>) {
          final data = res.data as Map<String, dynamic>;
          if (data['ytbID'] is String) {
            final ytbId = data['ytbID'] as String;
            return Success(ytbId);
          }
        }
      }
      return getErrMsg(res);
    } catch (e) {
      return Error(e.toString());
    }
  }

  static Future<LoadingState> postPortVideo({
    required String bvid,
    required int cid,
    required String ytbId,
    required int videoDuration,
  }) async {
    try {
      final String blockUserID =
          GStorage.setting.get('blockUserID', defaultValue: '');
      final res = await Request().post(
        _api(SponsorBlockApi.portVideo),
        data: {
          'bvID': bvid,
          'cid': cid.toString(),
          'ytbID': ytbId,
          'userID': blockUserID,
          'biliDuration': videoDuration,
        },
        options: options,
      );

      if (res.statusCode == 200) {
        if (res.data is Map<String, dynamic>) {
          final data = res.data as Map<String, dynamic>;
          if (data['UUID'] is String) {
            final uuid = data['UUID'] as String;
            return Success(uuid);
          }
        }
      }
      return getErrMsg(res);
    } catch (e) {
      return Error(e.toString());
    }
  }
}
