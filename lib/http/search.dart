import 'dart:convert';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hive/hive.dart';
import '../models/bangumi/info.dart';
import '../models/common/search_type.dart';
import '../models/search/hot.dart';
import '../models/search/result.dart';
import '../models/search/suggest.dart';
import '../models/search/trending.dart';
import '../utils/storage.dart';
import 'index.dart';

class SearchHttp {
  static Box localCache = GStorage.localCache;
  static Future hotSearchList() async {
    var res = await Request().get(Api.hotSearchList);
    if (res.data is String) {
      Map<String, dynamic> resultMap = json.decode(res.data);
      if (resultMap['code'] == 0) {
        return {
          'status': true,
          'data': HotSearchModel.fromJson(resultMap),
        };
      }
    } else if (res.data is Map<String, dynamic> && res.data['code'] == 0) {
      return {
        'status': true,
        'data': HotSearchModel.fromJson(res.data),
      };
    }

    return {
      'status': false,
      'data': [],
      'msg': '请求错误 🙅',
    };
  }

  // 获取搜索建议
  static Future searchSuggest({required term}) async {
    var res = await Request().get(Api.searchSuggest,
        data: {'term': term, 'main_ver': 'v1', 'highlight': term});
    if (res.data is String) {
      Map<String, dynamic> resultMap = json.decode(res.data);
      if (resultMap['code'] == 0) {
        if (resultMap['result'] is Map) {
          resultMap['result']['term'] = term;
        }
        return {
          'status': true,
          'data': resultMap['result'] is Map
              ? SearchSuggestModel.fromJson(resultMap['result'])
              : [],
        };
      } else {
        return {
          'status': false,
          'data': [],
          'msg': '请求错误 🙅',
        };
      }
    } else {
      return {
        'status': false,
        'data': [],
        'msg': '请求错误 🙅',
      };
    }
  }

  // 分类搜索
  static Future searchByType({
    required SearchType searchType,
    required String keyword,
    required page,
    String? order,
    int? duration,
  }) async {
    var reqData = {
      'search_type': searchType.type,
      'keyword': keyword,
      // 'order_sort': 0,
      // 'user_type': 0,
      'page': page,
      if (order != null) 'order': order,
      if (duration != null) 'duration': duration,
    };
    var res = await Request().get(Api.searchByType, data: reqData);
    if (res.data['code'] == 0 && res.data['data']['numPages'] > 0) {
      Object data;
      try {
        switch (searchType) {
          case SearchType.video:
            List<int> blackMidsList = localCache
                .get(LocalCacheKey.blackMidsList, defaultValue: [-1])
                .map<int>((i) => i as int)
                .toList();
            for (var i in res.data['data']['result']) {
              // 屏蔽推广和拉黑用户
              i['available'] = !blackMidsList.contains(i['mid']);
            }
            data = SearchVideoModel.fromJson(res.data['data']);
            break;
          case SearchType.live_room:
            data = SearchLiveModel.fromJson(res.data['data']);
            break;
          case SearchType.bili_user:
            data = SearchUserModel.fromJson(res.data['data']);
            break;
          case SearchType.media_bangumi:
          case SearchType.media_ft:
            data = SearchMBangumiModel.fromJson(res.data['data']);
            break;
          case SearchType.article:
            data = SearchArticleModel.fromJson(res.data['data']);
            break;
        }
        return {
          'status': true,
          'data': data,
        };
      } catch (err) {
        // print(err);
      }
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['data'] != null && res.data['data']['numPages'] == 0
            ? '没有相关数据'
            : res.data['message'],
      };
    }
  }

  static Future<int> ab2c({int? aid, String? bvid}) async {
    Map<String, dynamic> data = {};
    if (aid != null) {
      data['aid'] = aid;
    } else if (bvid != null) {
      data['bvid'] = bvid;
    }
    final dynamic res =
        await Request().get(Api.ab2c, data: <String, dynamic>{...data});
    if (res.data['code'] == 0) {
      return res.data['data'].first['cid'];
    } else {
      SmartDialog.showToast("ab2c error: ${res.data['message']}");
      return -1;
    }
  }

  static Future<Map<String, dynamic>> bangumiInfo(
      {int? seasonId, int? epId}) async {
    final Map<String, dynamic> data = {};
    if (seasonId != null) {
      data['season_id'] = seasonId;
    } else if (epId != null) {
      data['ep_id'] = epId;
    }
    final dynamic res =
        await Request().get(Api.bangumiInfo, data: <String, dynamic>{...data});
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': BangumiInfoModel.fromJson(res.data['result']),
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 获取热搜榜单（完整）
  static Future<Map<String, dynamic>> searchTrending({int limit = 30}) async {
    try {
      var res = await Request().get(Api.searchTrending, data: {'limit': limit});
      if (res.data['code'] == 0) {
        var model = SearchTrendingModel.fromJson(res.data['data']);
        return {
          'status': true,
          'data': model,
        };
      } else {
        return {
          'status': false,
          'data': null,
          'msg': res.data['message'] ?? '请求错误',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'data': null,
        'msg': e.toString(),
      };
    }
  }

  // 获取搜索发现
  static Future<Map<String, dynamic>> searchRecommend() async {
    try {
      var res = await Request().get(Api.searchRecommend, data: {
        'build': 8430300,
        'channel': 'master',
        'version': '8.43.0',
        'c_locale': 'zh_CN',
        'mobi_app': 'android',
        'platform': 'android',
        's_locale': 'zh_CN',
        'from': 2,
      });
      if (res.data['code'] == 0) {
        var model = SearchRecommendModel.fromJson(res.data['data']);
        return {
          'status': true,
          'data': model,
        };
      } else {
        return {
          'status': false,
          'data': null,
          'msg': res.data['message'] ?? '请求错误',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'data': null,
        'msg': e.toString(),
      };
    }
  }
}
