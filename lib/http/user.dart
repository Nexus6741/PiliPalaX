import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../common/constants.dart';
import '../models/model_hot_video_item.dart';
import '../models/user/fav_detail.dart';
import '../models/user/fav_folder.dart';
import '../models/user/history.dart';
import '../models/user/info.dart';
import '../models/user/stat.dart';
import '../models/user/sub_detail.dart';
import '../models/user/sub_folder.dart';
import '../models/space_setting/privacy.dart';
import '../utils/storage.dart';
import 'api.dart';
import 'init.dart';

class UserHttp {
  static Future<dynamic> userStat({required int mid}) async {
    var res = await Request().get(Api.userStat, data: {'vmid': mid});
    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {'status': false};
    }
  }

  static Future<dynamic> userInfo() async {
    var res = await Request().get(Api.userInfo);
    if (res.data['code'] == 0) {
      UserInfoData data = UserInfoData.fromJson(res.data['data']);
      return {'status': true, 'data': data};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  static Future<dynamic> userStatOwner() async {
    var res = await Request().get(Api.userStatOwner);
    if (res.data['code'] == 0) {
      UserStat data = UserStat.fromJson(res.data['data']);
      return {'status': true, 'data': data};
    } else {
      return {'status': false, 'data': [], 'msg': res.data['message']};
    }
  }

  // 收藏夹
  static Future<dynamic> userfavFolder({
    required int pn,
    required int ps,
    required int mid,
  }) async {
    var res = await Request().get(Api.userFavFolder, data: {
      'pn': pn,
      'ps': ps,
      'up_mid': mid,
    });
    if (res.data['code'] == 0) {
      late FavFolderData data;
      if (res.data['data'] != null) {
        data = FavFolderData.fromJson(res.data['data']);
        return {'status': true, 'data': data};
      }
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'] ?? '账号未登录'
      };
    }
  }

  static Future<dynamic> userFavFolderDetail(
      {required int mediaId,
      required int pn,
      required int ps,
      String keyword = '',
      String order = 'mtime',
      int type = 0}) async {
    var res = await Request().get(Api.userFavFolderDetail, data: {
      'media_id': mediaId,
      'pn': pn,
      'ps': ps,
      'keyword': keyword,
      'order': order,
      'type': type,
      'tid': 0,
      'platform': 'web'
    });
    if (res.data['code'] == 0) {
      FavDetailData data = FavDetailData.fromJson(res.data['data']);
      return {'status': true, 'data': data};
    } else {
      return {'status': false, 'data': [], 'msg': res.data['message']};
    }
  }

  // 稍后再看
  static Future<dynamic> seeYouLater() async {
    var res = await Request().get(Api.seeYouLater);
    if (res.data['code'] == 0) {
      if (res.data['data']['count'] == 0) {
        return {
          'status': true,
          'data': {'list': [], 'count': 0}
        };
      }
      List<HotVideoItemModel> list = [];
      for (var i in res.data['data']['list']) {
        list.add(HotVideoItemModel.fromJson(i));
      }
      return {
        'status': true,
        'data': {'list': list, 'count': res.data['data']['count']}
      };
    } else {
      return {'status': false, 'data': [], 'msg': res.data['message']};
    }
  }

  // 观看历史
  static Future historyList(int? max, int? viewAt) async {
    var res = await Request().get(Api.historyList, data: {
      'type': 'all',
      'ps': 20,
      'max': max ?? 0,
      'view_at': viewAt ?? 0,
    });
    if (res.data['code'] == 0) {
      return {'status': true, 'data': HistoryData.fromJson(res.data['data'])};
    } else {
      return {'status': false, 'data': [], 'msg': res.data['message']};
    }
  }

  // 暂停观看历史
  static Future pauseHistory(bool switchStatus) async {
    // 暂停switchStatus传true 否则false
    var res = await Request().post(
      Api.pauseHistory,
      queryParameters: {
        'switch': switchStatus,
        'jsonp': 'jsonp',
        'csrf': await Request.getCsrf(),
      },
    );
    return res;
  }

  // 观看历史暂停状态
  static Future historyStatus() async {
    var res = await Request().get(Api.historyStatus);
    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {'status': false, 'data': [], 'msg': res.data['message']};
    }
  }

  // 清空历史记录
  static Future clearHistory() async {
    var res = await Request().post(
      Api.clearHistory,
      queryParameters: {
        'jsonp': 'jsonp',
        'csrf': await Request.getCsrf(),
      },
    );
    return res;
  }

  // 稍后再看
  static Future toViewLater({String? bvid, dynamic aid}) async {
    var data = {'csrf': await Request.getCsrf()};
    if (bvid != null) {
      data['bvid'] = bvid;
    } else if (aid != null) {
      data['aid'] = aid;
    }
    var res = await Request().post(
      Api.toViewLater,
      queryParameters: data,
    );
    if (res.data['code'] == 0) {
      return {'status': true, 'msg': 'yeah！稍后再看'};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 移除已观看
  static Future toViewDel({int? aid}) async {
    final Map<String, dynamic> params = {
      'jsonp': 'jsonp',
      'csrf': await Request.getCsrf(),
    };

    params[aid != null ? 'aid' : 'viewed'] = aid ?? true;
    var res = await Request().post(
      Api.toViewDel,
      queryParameters: params,
    );
    if (res.data['code'] == 0) {
      return {'status': true, 'msg': 'yeah！成功移除'};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 获取用户凭证 失效
  static Future thirdLogin() async {
    var res = await Request().get(
      'https://passport.bilibili.com/login/app/third',
      data: {
        'appkey': Constants.appKey,
        'api': Constants.thirdApi,
        'sign': Constants.thirdSign,
      },
    );
    try {
      if (res.data['code'] == 0 && res.data['data']['has_login'] == 1) {
        Request().get(res.data['data']['confirm_uri']);
      }
    } catch (err) {
      SmartDialog.showNotify(msg: '获取用户凭证: $err', notifyType: NotifyType.error);
    }
  }

  // 清空稍后再看
  static Future toViewClear() async {
    var res = await Request().post(
      Api.toViewClear,
      queryParameters: {
        'jsonp': 'jsonp',
        'csrf': await Request.getCsrf(),
      },
    );
    if (res.data['code'] == 0) {
      return {'status': true, 'msg': '操作完成'};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 删除历史记录
  static Future delHistory(kid) async {
    var res = await Request().post(
      Api.delHistory,
      queryParameters: {
        'kid': kid,
        'jsonp': 'jsonp',
        'csrf': await Request.getCsrf(),
      },
    );
    if (res.data['code'] == 0) {
      return {'status': true, 'msg': '已删除'};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  static Future hasFollow(int mid) async {
    var res = await Request().get(
      Api.hasFollow,
      data: {
        'fid': mid,
      },
    );
    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }
  // // 相互关系查询
  // static Future relationSearch(int mid) async {
  //   Map params = await WbiSign().makSign({
  //     'mid': mid,
  //     'token': '',
  //     'platform': 'web',
  //     'web_location': 1550101,
  //   });
  //   var res = await Request().get(
  //     Api.relationSearch,
  //     data: {
  //       'mid': mid,
  //       'w_rid': params['w_rid'],
  //       'wts': params['wts'],
  //     },
  //   );
  //   if (res.data['code'] == 0) {
  //     // relation 主动状态
  //     // 被动状态
  //     return {'status': true, 'data': res.data['data']};
  //   } else {
  //     return {'status': false, 'msg': res.data['message']};
  //   }
  // }

  // 搜索历史记录
  static Future searchHistory(
      {required int pn, required String keyword}) async {
    var res = await Request().get(
      Api.searchHistory,
      data: {
        'pn': pn,
        'keyword': keyword,
        'business': 'all',
      },
    );
    if (res.data['code'] == 0) {
      return {'status': true, 'data': HistoryData.fromJson(res.data['data'])};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 我的订阅
  static Future userSubFolder({
    required int mid,
    required int pn,
    required int ps,
  }) async {
    var res = await Request().get(Api.userSubFolder, data: {
      'up_mid': mid,
      'ps': ps,
      'pn': pn,
      'platform': 'web',
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': SubFolderModelData.fromJson(res.data['data'])
      };
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 用户空间收藏（包含创建的收藏夹和订阅）
  static Future spaceFav({required int mid}) async {
    var res = await Request().get(
      Api.spaceFav,
      data: {
        'build': 8430300,
        'version': '8.43.0',
        'c_locale': 'zh_CN',
        'channel': 'master',
        'mobi_app': 'android',
        'platform': 'android',
        's_locale': 'zh_CN',
        'statistics': Constants.statistics,
        'up_mid': mid,
      },
      options: Options(
        headers: {
          'bili-http-engine': 'cronet',
          'user-agent': Constants.userAgent,
        },
      ),
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data'],
      };
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  static Future favSeasonList({
    required int id,
    required int pn,
    required int ps,
  }) async {
    var res = await Request().get(Api.favSeasonList, data: {
      'season_id': id,
      'ps': ps,
      'pn': pn,
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': SubDetailModelData.fromJson(res.data['data'])
      };
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  static Future favResourceList({
    required int id,
    required int pn,
    required int ps,
  }) async {
    var res = await Request().get(Api.favResourceList, data: {
      'media_id': id,
      'ps': ps,
      'pn': pn,
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': SubDetailModelData.fromJson(res.data['data'])
      };
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 取消订阅
  static Future cancelSub({required int id, required int type}) async {
    late dynamic res;
    if (type == 11) {
      res = await Request().post(
        Api.unfavFolder,
        queryParameters: {
          'media_id': id,
          'csrf': await Request.getCsrf(),
        },
      );
    } else {
      res = await Request().post(
        Api.unfavSeason,
        queryParameters: {
          'platform': 'web',
          'season_id': id,
          'csrf': await Request.getCsrf(),
        },
      );
    }
    if (res.data['code'] == 0) {
      return {'status': true};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 收藏话题
  static Future<dynamic> addFavTopic(String topicId) async {
    try {
      String csrf = await Request.getCsrf();
      print('🔍 [addFavTopic] topic_id: $topicId');
      print('🔍 [addFavTopic] csrf: $csrf');
      print('🔍 [addFavTopic] API endpoint: ${Api.addFavTopic}');

      var res = await Request().post(
        Api.addFavTopic,
        data: {
          'csrf': csrf,
          'topic_id': topicId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      print('🔍 [addFavTopic] Response code: ${res.data['code']}');
      print('🔍 [addFavTopic] Response: ${res.data}');

      if (res.data['code'] == 0) {
        return {'status': true};
      } else {
        return {'status': false, 'msg': res.data['message']};
      }
    } catch (err) {
      print('❌ [addFavTopic] Error: $err');
      return {'status': false, 'msg': err.toString()};
    }
  }

  // 取消收藏话题
  static Future<dynamic> delFavTopic(String topicId) async {
    try {
      String csrf = await Request.getCsrf();
      print('🔍 [delFavTopic] topic_id: $topicId');
      print('🔍 [delFavTopic] csrf: $csrf');
      print('🔍 [delFavTopic] API endpoint: ${Api.delFavTopic}');

      var res = await Request().post(
        Api.delFavTopic,
        data: {
          'csrf': csrf,
          'topic_id': topicId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      print('🔍 [delFavTopic] Response code: ${res.data['code']}');
      print('🔍 [delFavTopic] Response: ${res.data}');

      if (res.data['code'] == 0) {
        return {'status': true};
      } else {
        return {'status': false, 'msg': res.data['message']};
      }
    } catch (err) {
      print('❌ [delFavTopic] Error: $err');
      return {'status': false, 'msg': err.toString()};
    }
  }

  // 点赞话题
  static Future<dynamic> likeTopic(String topicId, bool isLike) async {
    try {
      // 获取当前登录用户的 mid
      var userInfo = GStorage.userInfo.get('userInfoCache');
      int upMid = userInfo != null ? userInfo.mid : 0;
      String csrf = await Request.getCsrf();
      String action = isLike ? 'cancel_like' : 'like';

      print('🔍 [likeTopic] topic_id: $topicId');
      print('🔍 [likeTopic] isLike: $isLike');
      print('🔍 [likeTopic] action: $action');
      print('🔍 [likeTopic] up_mid: $upMid');
      print('🔍 [likeTopic] csrf: $csrf');
      print('🔍 [likeTopic] API endpoint: ${Api.likeTopic}');

      var res = await Request().post(
        Api.likeTopic,
        data: {
          'csrf': csrf,
          'action': action,
          'up_mid': upMid,
          'topic_id': topicId,
          'business': 'topic',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      print('🔍 [likeTopic] Response code: ${res.data['code']}');
      print('🔍 [likeTopic] Response: ${res.data}');

      if (res.data['code'] == 0) {
        return {'status': true};
      } else {
        return {'status': false, 'msg': res.data['message']};
      }
    } catch (err) {
      print('❌ [likeTopic] Error: $err');
      return {'status': false, 'msg': err.toString()};
    }
  }

  // 获取登录记录
  static Future<Map<String, dynamic>> loginLog() async {
    print('========== loginLog API START ==========');
    try {
      print('Calling Request().get with Api.loginLog: ${Api.loginLog}');
      var res = await Request().get(
        Api.loginLog,
        data: {
          'jsonp': 'jsonp',
        },
      );
      print('Response code: ${res.data['code']}');
      print('Response data keys: ${res.data['data']?.keys}');

      if (res.data['code'] == 0) {
        print('Login log data: ${res.data['data']}');
        return {'status': true, 'data': res.data['data']};
      } else {
        print('API error: ${res.data['message']}');
        return {'status': false, 'msg': res.data['message']};
      }
    } catch (e, stackTrace) {
      print('Exception in loginLog: $e');
      print('StackTrace: $stackTrace');
      return {'status': false, 'msg': e.toString()};
    } finally {
      print('========== loginLog API END ==========');
    }
  }

  // 获取硬币记录
  static Future<Map<String, dynamic>> coinLog() async {
    print('========== coinLog API START ==========');
    try {
      print('Calling Request().get with Api.coinLog: ${Api.coinLog}');
      var res = await Request().get(
        Api.coinLog,
        data: {
          'jsonp': 'jsonp',
        },
      );
      print('Response code: ${res.data['code']}');
      print('Response data keys: ${res.data['data']?.keys}');

      if (res.data['code'] == 0) {
        print('Coin log data: ${res.data['data']}');
        return {'status': true, 'data': res.data['data']};
      } else {
        print('API error: ${res.data['message']}');
        return {'status': false, 'msg': res.data['message']};
      }
    } catch (e, stackTrace) {
      print('Exception in coinLog: $e');
      print('StackTrace: $stackTrace');
      return {'status': false, 'msg': e.toString()};
    } finally {
      print('========== coinLog API END ==========');
    }
  }

  // 获取经验记录
  static Future<Map<String, dynamic>> expLog() async {
    print('========== expLog API START ==========');
    try {
      print('Calling Request().get with Api.expLog: ${Api.expLog}');
      var res = await Request().get(
        Api.expLog,
        data: {
          'jsonp': 'jsonp',
        },
      );
      print('Response code: ${res.data['code']}');
      print('Response data keys: ${res.data['data']?.keys}');

      if (res.data['code'] == 0) {
        print('Exp log data: ${res.data['data']}');
        return {'status': true, 'data': res.data['data']};
      } else {
        print('API error: ${res.data['message']}');
        return {'status': false, 'msg': res.data['message']};
      }
    } catch (e, stackTrace) {
      print('Exception in expLog: $e');
      print('StackTrace: $stackTrace');
      return {'status': false, 'msg': e.toString()};
    } finally {
      print('========== expLog API END ==========');
    }
  }

  // 获取空间设置
  static Future<Map<String, dynamic>> spaceSetting() async {
    print('========== spaceSetting API START ==========');
    try {
      var userInfo = GStorage.userInfo.get('userInfoCache');
      int mid = userInfo != null ? userInfo.mid : 0;
      print('User mid: $mid');

      print('Calling Request().get with Api.spaceSetting: ${Api.spaceSetting}');
      var res = await Request().get(
        Api.spaceSetting,
        data: {
          'mid': mid,
        },
      );
      print('Response code: ${res.data['code']}');
      print('Response data keys: ${res.data['data']?.keys}');

      if (res.data['code'] == 0) {
        final privacy = res.data['data']?['privacy'];
        print('Privacy data: ${privacy != null ? "exists" : "null"}');
        if (privacy != null) {
          print('Privacy keys: ${privacy.keys}');
          return {'status': true, 'data': Privacy.fromJson(privacy)};
        }
        return {'status': false, 'msg': '数据格式错误'};
      } else {
        print('API error: ${res.data['message']}');
        return {'status': false, 'msg': res.data['message']};
      }
    } catch (e, stackTrace) {
      print('Exception in spaceSetting: $e');
      print('StackTrace: $stackTrace');
      return {'status': false, 'msg': e.toString()};
    } finally {
      print('========== spaceSetting API END ==========');
    }
  }

  // 修改空间设置
  static Future<Map<String, dynamic>> spaceSettingMod(
      Map<String, int> data) async {
    var res = await Request().post(
      Api.spaceSettingMod,
      queryParameters: {
        'csrf': await Request.getCsrf(),
      },
      data: data,
    );
    if (res.data['code'] == 0) {
      return {'status': true};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }
}
