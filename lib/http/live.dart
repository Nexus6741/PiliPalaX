import 'package:dio/dio.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/models/live_new/live_emote/data.dart';
import 'package:PiliPalaX/utils/app_sign.dart';
import 'package:PiliPalaX/utils/login.dart';
import 'package:PiliPalaX/utils/wbi_sign.dart';
import 'package:flutter/foundation.dart';
import '../models/live/item.dart';
import '../models/live/room_info.dart';
import '../models/live_new/live_room_info_h5/data.dart';
import '../models/live/live_feed_index/index.dart';
import '../models/live/live_second_list/index.dart';
import '../models/live/live_area_list/index.dart';
import '../models/live/live_follow/index.dart';
import '../models/live/live_dm_info/index.dart';
import 'api.dart';
import 'init.dart';
import 'loading_state.dart';

class LiveHttp {
  static Future liveList(
      {int? vmid, int? pn, int? ps, String? orderType}) async {
    var res = await Request().get(Api.liveList, data: {'platform': 'web'});
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data']['recommend_room_list']
            .map<LiveItemModel>((e) => LiveItemModel.fromJson(e))
            .toList()
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future liveRoomInfo({roomId, qn}) async {
    // debugPrint('[LiveHttp] liveRoomInfo: roomId=$roomId, qn=$qn');
    final wbiSign = WbiSign();
    final params = await wbiSign.makSign({
      'room_id': roomId,
      'protocol': '0,1',
      'format': '0,1,2',
      'codec': '0,1,2',
      'qn': qn,
      'platform': 'web',
      'ptype': 8,
      'dolby': 5,
      'panorama': 1,
    });
    // debugPrint('[LiveHttp] liveRoomInfo params: $params');
    var res = await Request().get(Api.liveRoomInfo, data: params);
    // debugPrint(
    //     '[LiveHttp] liveRoomInfo response code: ${res.data['code']}, msg: ${res.data['message']}');
    if (res.data['code'] == 0) {
      return {'status': true, 'data': RoomInfoModel.fromJson(res.data['data'])};
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future liveRoomInfoH5({roomId, qn}) async {
    var res = await Request().get(Api.liveRoomInfoH5, data: {
      'room_id': roomId,
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': RoomInfoH5Data.fromJson(res.data['data']),
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future liveEmoteList({required int roomId}) async {
    final res = await Request().get(
      Api.liveEmoteList,
      data: {
        'platform': 'pc',
        'room_id': roomId,
      },
    );
    if (res.data['code'] == 0) {
      try {
        return {
          'status': true,
          'data': LiveEmoteData.fromJson(res.data['data']).data ?? [],
        };
      } catch (e) {
        return {
          'status': false,
          'msg': e.toString(),
        };
      }
    } else {
      return {
        'status': false,
        'msg': res.data['message'],
      };
    }
  }

  /// 直播首页Feed
  static Future<LoadingState<LiveIndexData>> liveFeedIndex({
    required int pn,
    bool moduleSelect = false,
  }) async {
    final params = <String, dynamic>{
      'channel': 'master',
      'actionKey': 'appkey',
      'build': 8430300,
      'version': '8.43.0',
      'c_locale': 'zh_CN',
      'device': 'android',
      'device_name': 'android',
      'device_type': 0,
      'fnval': 912,
      'disable_rcmd': 0,
      'https_url_req': 1,
      if (moduleSelect) 'module_select': 1,
      'mobi_app': 'android',
      'network': 'wifi',
      'page': pn,
      'platform': 'android',
      's_locale': 'zh_CN',
      'scale': 2,
      'statistics': '{"appId":1,"platform":3,"version":"8.43.0","abtest":""}',
      'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    AppSign.appSign(params);

    var res = await Request().get(
      Api.liveFeedIndex,
      data: params,
      options: Options(
        headers: {
          'buvid': LoginUtils.buvid,
          'fp_local':
              '1111111111111111111111111111111111111111111111111111111111111111',
          'fp_remote':
              '1111111111111111111111111111111111111111111111111111111111111111',
          'session_id': '11111111',
          'env': 'prod',
          'app-key': 'android',
          'User-Agent': Constants.userAgent,
          'x-bili-trace-id': Constants.traceId,
          'x-bili-aurora-eid': '',
          'x-bili-aurora-zone': '',
        },
      ),
    );
    if (res.data['code'] == 0) {
      return Success(LiveIndexData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  /// 直播关注列表
  static Future<LoadingState<LiveFollowData>> liveFollow(int page) async {
    var res = await Request().get(
      Api.liveFollow,
      data: {
        'page': page,
        'page_size': 9,
        'ignoreRecord': 1,
        'hit_ab': true,
      },
    );
    if (res.data['code'] == 0) {
      return Success(LiveFollowData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  /// 直播二级分区列表
  static Future<LoadingState<LiveSecondData>> liveSecondList({
    required int pn,
    required dynamic areaId,
    required dynamic parentAreaId,
    String? sortType,
  }) async {
    final params = <String, dynamic>{
      'actionKey': 'appkey',
      'channel': 'master',
      'area_id': areaId,
      'parent_area_id': parentAreaId,
      'build': 8430300,
      'version': '8.43.0',
      'c_locale': 'zh_CN',
      'device': 'android',
      'device_name': 'android',
      'device_type': 0,
      'fnval': 912,
      'disable_rcmd': 0,
      'https_url_req': 1,
      'mobi_app': 'android',
      'module_select': 0,
      'network': 'wifi',
      'page': pn,
      'page_size': 20,
      'platform': 'android',
      'qn': 0,
      if (sortType != null) 'sort_type': sortType,
      'tag_version': 1,
      's_locale': 'zh_CN',
      'scale': 2,
      'statistics': '{"appId":1,"platform":3,"version":"8.43.0","abtest":""}',
      'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    AppSign.appSign(params);

    var res = await Request().get(
      Api.liveSecondList,
      data: params,
      options: Options(
        headers: {
          'buvid': LoginUtils.buvid,
          'fp_local':
              '1111111111111111111111111111111111111111111111111111111111111111',
          'fp_remote':
              '1111111111111111111111111111111111111111111111111111111111111111',
          'session_id': '11111111',
          'env': 'prod',
          'app-key': 'android',
          'User-Agent': Constants.userAgent,
          'x-bili-trace-id': Constants.traceId,
          'x-bili-aurora-eid': '',
          'x-bili-aurora-zone': '',
        },
      ),
    );
    if (res.data['code'] == 0) {
      return Success(LiveSecondData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  /// 直播分区列表
  static Future<LoadingState<List<AreaList>?>> liveAreaList() async {
    final params = {
      'appkey': Constants.appKey,
      'actionKey': 'appkey',
      'build': 8430300,
      'channel': 'master',
      'version': '8.43.0',
      'c_locale': 'zh_CN',
      'device': 'android',
      'disable_rcmd': 0,
      'mobi_app': 'android',
      'platform': 'android',
      's_locale': 'zh_CN',
      'statistics': Constants.statistics,
      'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    AppSign.appSign(params);

    var res = await Request().get(
      Api.liveAreaList,
      data: params,
    );
    if (res.data['code'] == 0) {
      return Success(
        (res.data['data']?['list'] as List?)
            ?.map((e) => AreaList.fromJson(e))
            .toList(),
      );
    } else {
      return Error(res.data['message']);
    }
  }

  /// 直播分区二级分类列表
  static Future<LoadingState<List<AreaItem>?>> liveRoomAreaList({
    required dynamic parentid,
  }) async {
    var res = await Request().get(
      Api.liveRoomAreaList,
      data: {'parent_id': parentid},
    );
    if (res.data['code'] == 0) {
      return Success(
        (res.data['data'] as List?)?.map((e) => AreaItem.fromJson(e)).toList(),
      );
    } else {
      return Error(res.data['message']);
    }
  }

  /// 获取直播弹幕Token
  static Future liveRoomGetDanmakuToken({roomId}) async {
    var res = await Request().get(
      Api.liveRoomDmToken,
      data: await WbiSign().makSign({
        'id': roomId,
        'web_location': 444.8,
      }),
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': LiveDmInfoData.fromJson(res.data['data']),
      };
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  /// 直播弹幕预取
  static Future liveRoomDanmaPrefetch({roomId}) async {
    var res = await Request().get(
      Api.liveRoomDmPrefetch,
      data: {'roomid': roomId},
      options: Options(
        headers: {
          'referer': 'https://live.bilibili.com/$roomId',
        },
      ),
    );
    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']?['room']};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  /// 发送直播弹幕
  static Future sendLiveMsg({
    required Object roomId,
    required Object msg,
    Object? dmType,
    Object? emoticonOptions,
  }) async {
    final csrf = await Request.getCsrf();
    var res = await Request().post(
      Api.sendLiveMsg,
      data: FormData.fromMap({
        'bubble': 0,
        'msg': msg,
        'color': 16777215,
        'mode': 1,
        if (dmType != null) 'dm_type': dmType,
        if (emoticonOptions != null)
          'emoticonOptions': emoticonOptions
        else ...{
          'room_type': 0,
          'jumpfrom': 0,
          'reply_mid': 0,
          'reply_attr': 0,
          'replay_dmid': '',
          'statistics': Constants.statistics,
          'reply_type': 0,
          'reply_uname': '',
        },
        'fontsize': 25,
        'rnd': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'roomid': roomId,
        'csrf': csrf,
        'csrf_token': csrf,
      }),
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data'],
      };
    } else {
      return {
        'status': false,
        'msg': res.data['message'],
      };
    }
  }

  static Future liveLikeReport({
    required int clickTime,
    required int roomId,
    required int uid,
    int? anchorId,
  }) async {
    final csrf = await Request.getCsrf();
    var res = await Request().post(
      Api.liveLikeReport,
      data: await WbiSign().makSign({
        'click_time': clickTime,
        'room_id': roomId,
        'uid': uid,
        'anchor_id': anchorId ?? 0,
        'web_location': 444.8,
        'csrf': csrf,
        'csrf_token': csrf,
      }),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (res.data['code'] == 0) {
      return {'status': true};
    } else {
      return {
        'status': false,
        'msg': res.data['message'],
      };
    }
  }

  /// 获取直播屏蔽信息
  static Future getLiveShieldInfo(dynamic roomId) async {
    var res = await Request().get(
      Api.liveShieldInfo,
      data: {'roomid': roomId},
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data'],
      };
    } else {
      return {
        'status': false,
        'msg': res.data['message'],
      };
    }
  }

  /// 添加屏蔽关键词
  static Future addShieldKeyword({required String keyword}) async {
    var res = await Request().post(
      Api.liveAddShieldKeyword,
      data: FormData.fromMap({'keyword': keyword}),
    );
    if (res.data['code'] == 0) {
      return {'status': true};
    } else {
      return {
        'status': false,
        'msg': res.data['message'],
      };
    }
  }

  /// 删除屏蔽关键词
  static Future delShieldKeyword({required String keyword}) async {
    var res = await Request().post(
      Api.liveDelShieldKeyword,
      data: FormData.fromMap({'keyword': keyword}),
    );
    if (res.data['code'] == 0) {
      return {'status': true};
    } else {
      return {
        'status': false,
        'msg': res.data['message'],
      };
    }
  }

  /// 屏蔽/取消屏蔽用户
  static Future liveShieldUser({
    required dynamic uid,
    required dynamic roomid,
    required int type, // 1: 屏蔽, 0: 取消屏蔽
  }) async {
    var res = await Request().post(
      Api.liveShieldUser,
      data: FormData.fromMap({
        'uid': uid,
        'roomid': roomid,
        'type': type,
      }),
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data'],
      };
    } else {
      return {
        'status': false,
        'msg': res.data['message'],
      };
    }
  }
}
