import 'dart:developer';

import 'package:dio/dio.dart';

import '../common/constants.dart';
import '../models/dynamics/result.dart';
import '../models/follow/result.dart';
import '../models/member/archive.dart';
import '../models/member/coin.dart';
import '../models/member/info.dart';
import '../models/member/seasons.dart';
import '../models/member/tags.dart';
import '../models/member/space_data.dart';
import '../utils/storage.dart';
import '../utils/utils.dart';
import '../utils/wbi_sign.dart';
import '../utils/app_sign.dart';
import 'index.dart';

class MemberHttp {
  // 获取用户空间完整信息（使用App API，与PiliPlus一致）
  static Future<Map<String, dynamic>> space({
    required int mid,
    String? fromViewAid,
  }) async {
    // 获取 access_key
    final accessKeyInfo = GStorage.localCache.get(
      LocalCacheKey.accessKey,
      defaultValue: {'mid': -1, 'value': '', 'refresh': ''},
    );
    final accessKey = accessKeyInfo['value'] as String?;

    final params = <String, dynamic>{
      'build': 8430300,
      'version': '8.43.0',
      'c_locale': 'zh_CN',
      'channel': 'master',
      'mobi_app': 'android',
      'platform': 'android',
      's_locale': 'zh_CN',
      'statistics': '{"appId":1,"platform":3,"version":"8.43.0","abtest":""}',
      'vmid': mid,
      'ts': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    };

    // 添加 access_key（如果已登录）
    if (accessKey != null && accessKey.isNotEmpty) {
      params['access_key'] = accessKey;
    }

    if (fromViewAid != null) {
      params['from_view_aid'] = fromViewAid;
    }

    // 对参数进行签名
    AppSign.appSign(params);

    print('========== memberSpace API Request ==========');
    print('Has access_key: ${accessKey != null && accessKey.isNotEmpty}');
    print('Params keys: ${params.keys.toList()}');
    print('Has sign: ${params.containsKey('sign')}');
    print('==============================================');

    var res = await Request().get(
      Api.memberSpace,
      data: params,
      options: Options(
        headers: {
          'bili-http-engine': 'cronet',
          'user-agent':
              'Mozilla/5.0 BiliDroid/8.43.0 (bbcallen@gmail.com) os/android model/android mobi_app/android build/8430300 channel/master innerVer/8430300 osVer/15 network/2',
        },
      ),
    );

    print('========== memberSpace API Response ==========');
    print('Response code: ${res.data['code']}');
    print('Message: ${res.data['message']}');
    if (res.data['code'] == 0) {
      try {
        final rawData = res.data['data'];
        print('Raw data keys: ${rawData.keys.toList()}');

        // 详细打印 archive 数据
        if (rawData['archive'] != null) {
          print('---------- Archive Data ----------');
          print('Archive count: ${rawData['archive']['count']}');
          if (rawData['archive']['item'] != null &&
              rawData['archive']['item'].isNotEmpty) {
            print('First archive item:');
            final firstItem = rawData['archive']['item'][0];
            print('  - bvid: ${firstItem['bvid']}');
            print('  - title: ${firstItem['title']}');
            print('  - pic: ${firstItem['pic']}');
            print('  - duration: ${firstItem['duration']}');
            print('  - play: ${firstItem['play']}');
          }
          print('----------------------------------');
        }

        // 详细打印 coinArchive 数据
        if (rawData['coin_archive'] != null) {
          print('---------- CoinArchive Data ----------');
          print('CoinArchive count: ${rawData['coin_archive']['count']}');
          if (rawData['coin_archive']['item'] != null &&
              rawData['coin_archive']['item'].isNotEmpty) {
            print('First coin_archive item:');
            final firstItem = rawData['coin_archive']['item'][0];
            print('  - ALL KEYS: ${firstItem.keys.toList()}');
            print('  - bvid: ${firstItem['bvid']}');
            print('  - title: ${firstItem['title']}');
            print('  - pic: ${firstItem['pic']}');
            print('  - cover: ${firstItem['cover']}');
            print('  - duration: ${firstItem['duration']}');
          }
          print('--------------------------------------');
        }

        // 详细打印 likeArchive 数据
        if (rawData['like_archive'] != null) {
          print('---------- LikeArchive Data ----------');
          print('LikeArchive count: ${rawData['like_archive']['count']}');
          if (rawData['like_archive']['item'] != null &&
              rawData['like_archive']['item'].isNotEmpty) {
            print('First like_archive item:');
            final firstItem = rawData['like_archive']['item'][0];
            print('  - bvid: ${firstItem['bvid']}');
            print('  - title: ${firstItem['title']}');
            print('  - pic: ${firstItem['pic']}');
            print('  - duration: ${firstItem['duration']}');
          }
          print('--------------------------------------');
        }

        final spaceData = SpaceData.fromJson(rawData);
        print('✅ Parsed successfully');
        print('Card parsed: ${spaceData.card != null}');
        print('Card fans: ${spaceData.card?.fans}');
        print('Card attention: ${spaceData.card?.attention}');
        print('Card likes: ${spaceData.card?.likes?.likeNum}');
        print('Images parsed: ${spaceData.images != null}');
        print('Archive count: ${spaceData.archive?.count}');
        print('Favourite2 count: ${spaceData.favourite2?.count}');
        print('CoinArchive count: ${spaceData.coinArchive?.count}');
        print('LikeArchive count: ${spaceData.likeArchive?.count}');
        print('Tab2 count: ${spaceData.tab2?.length}');
        print('==============================================');
        return {'status': true, 'data': spaceData};
      } catch (e, stackTrace) {
        print('❌ Parse error: $e');
        print('Stack trace: $stackTrace');
        print('==============================================');
        return {
          'status': false,
          'data': null,
          'msg': 'Failed to parse data: $e',
        };
      }
    } else {
      return {
        'status': false,
        'data': null,
        'msg': res.data['message'],
      };
    }
  }

  static Future memberInfo({
    int? mid,
    String token = '',
    dynamic wwebid,
  }) async {
    Map<String, dynamic> map = {
      'mid': mid,
      'token': token,
      'platform': 'web',
      'web_location': 1550101,
    };
    if (wwebid != null) {
      map['w_webid'] = wwebid;
    }
    Map params = await WbiSign().makSign(map);
    var res = await Request().get(
      Api.memberInfo,
      data: params,
      extra: {'ua': 'pc'},
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': MemberInfoModel.fromJson(res.data['data'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future memberStat({int? mid}) async {
    var res = await Request().get(Api.userStat, data: {'vmid': mid});
    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future memberCardInfo({int? mid}) async {
    var res = await Request()
        .get(Api.memberCardInfo, data: {'mid': mid, 'photo': true});
    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future memberArchive({
    int? mid,
    int ps = 40,
    int tid = 0,
    int? pn,
    String? keyword,
    String order = 'pubdate',
    bool orderAvoided = true,
  }) async {
    Map params = await WbiSign().makSign({
      'mid': mid,
      'ps': ps,
      'tid': tid,
      'pn': pn,
      'keyword': keyword ?? '',
      'order': order,
      'platform': 'web',
      'web_location': 1550101,
      'order_avoided': orderAvoided,
    });
    var res = await Request().get(
      Api.memberArchive,
      data: params,
      extra: {'ua': 'Mozilla/5.0'},
    );
    log('memberArchive: ${res.data}');
    log(res.toString());
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': MemberArchiveDataModel.fromJson(res.data['data'])
      };
    } else {
      Map errMap = {
        -352: '风控校验失败，请检查登录状态',
      };
      return {
        'status': false,
        'data': [],
        'msg': errMap[res.data['code']] ?? res.data['message'],
      };
    }
  }

  // 用户动态
  static Future memberDynamic({String? offset, int? mid}) async {
    String dmImgStr = Utils.base64EncodeRandomString(16, 64);
    String dmCoverImgStr = Utils.base64EncodeRandomString(32, 128);
    Map params = await WbiSign().makSign({
      'offset': offset ?? '',
      'host_mid': mid,
      'timezone_offset': '-480',
      'features': 'itemOpusStyle,listOnlyfans',
      'platform': 'web',
      'web_location': '333.1387',
      'dm_img_list': '[]',
      'dm_img_str': dmImgStr,
      'dm_cover_img_str': dmCoverImgStr,
      'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
      'x-bili-device-req-json':
          '{"platform":"web","device":"pc","spmid":"333.1387"}',
    });
    var res = await Request().get(
      Api.memberDynamic,
      data: params,
      extra: {
        'ua': 'pc',
        'origin': 'https://space.bilibili.com',
        'referer': 'https://space.bilibili.com/$mid/dynamic',
      },
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': DynamicsDataModel.fromJson(res.data['data']),
      };
    } else {
      Map errMap = {
        -352: '风控校验失败，请检查登录状态',
      };
      return {
        'status': false,
        'data': [],
        'msg': errMap[res.data['code']] ?? res.data['message'],
      };
    }
  }

  // 搜索用户动态
  static Future memberDynamicSearch({int? pn, int? ps, int? mid}) async {
    var res = await Request().get(Api.memberDynamic, data: {
      'keyword': '海拔',
      'mid': mid,
      'pn': pn,
      'ps': ps,
      'platform': 'web'
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': DynamicsDataModel.fromJson(res.data['data']),
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 查询分组
  static Future followUpTags() async {
    var res = await Request().get(Api.followUpTag);
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data']
            .map<MemberTagItemModel>((e) => MemberTagItemModel.fromJson(e))
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

  // 设置分组
  static Future addUsers(int? fids, String? tagids) async {
    var res = await Request().post(Api.addUsers, queryParameters: {
      'fids': fids,
      'tagids': tagids ?? '0',
      'csrf': await Request.getCsrf(),
    }, data: {
      'cross_domain': true
    });
    if (res.data['code'] == 0) {
      return {'status': true, 'data': [], 'msg': '操作成功'};
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 获取某分组下的up
  static Future followUpGroup(
    int? mid,
    int? tagid,
    int? pn,
    int? ps,
  ) async {
    var res = await Request().get(Api.followUpGroup, data: {
      'mid': mid,
      'tagid': tagid,
      'pn': pn,
      'ps': ps,
    });
    if (res.data['code'] == 0) {
      // FollowItemModel
      return {
        'status': true,
        'data': res.data['data']
            .map<FollowItemModel>((e) => FollowItemModel.fromJson(e))
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

  // 获取up置顶
  static Future getTopVideo(String? vmid) async {
    var res = await Request().get(Api.getTopVideoApi);
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data']
            .map<MemberTagItemModel>((e) => MemberTagItemModel.fromJson(e))
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

  // 获取up合集与视频列表
  static Future getMemberSeasonsAndSeries(int? mid, int? pn, int? ps) async {
    var res = await Request().get(Api.getMemberSeasonsAndSeriesApi, data: {
      'mid': mid,
      'page_num': pn,
      'page_size': ps,
      'web_location': "333.999",
    });
    // log(res.toString());
    // print(res.data['data']['items_lists']);
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': MemberSeasonsAndSeriesDataModel.fromJson(
            res.data['data']['items_lists'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 最近投币
  static Future getRecentCoinVideo({required int mid}) async {
    Map params = await WbiSign().makSign({
      'mid': mid,
      'gaia_source': 'main_web',
      'web_location': 333.999,
    });
    var res = await Request().get(
      Api.getRecentCoinVideoApi,
      data: {
        'vmid': mid,
        'gaia_source': 'main_web',
        'web_location': 333.999,
        'w_rid': params['w_rid'],
        'wts': params['wts'],
      },
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data']
            .map<MemberCoinsDataModel>((e) => MemberCoinsDataModel.fromJson(e))
            .toList(),
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 最近点赞
  static Future getRecentLikeVideo({required int mid}) async {
    Map params = await WbiSign().makSign({
      'mid': mid,
      'gaia_source': 'main_web',
      'web_location': 333.999,
    });
    var res = await Request().get(
      Api.getRecentLikeVideoApi,
      data: {
        'vmid': mid,
        'gaia_source': 'main_web',
        'web_location': 333.999,
        'w_rid': params['w_rid'],
        'wts': params['wts'],
      },
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': MemberSeasonsAndSeriesDataModel.fromJson(
            res.data['data']['items_lists'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 查看某个合集
  static Future getSeasonDetail({
    required int mid,
    required int seasonId,
    bool sortReverse = false,
    required int pn,
    required int ps,
  }) async {
    var res = await Request().get(
      Api.getSeasonDetailApi,
      data: {
        'mid': mid,
        'season_id': seasonId,
        'sort_reverse': sortReverse,
        'page_num': pn,
        'page_size': ps,
      },
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': MemberSeasonsList.fromJson(res.data['data'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  //https://api.bilibili.com/x/series/archives?mid=39665558&series_id=534501&sort=asc&pn=1&ps=30&current_mid=1070915568
  // 查看某个视频列表
  static Future getSeriesDetail({
    required int mid,
    required int seriesId,
    bool sortReverse = false,
    required int pn,
    required int ps,
  }) async {
    int? currentMid = GStorage.userInfo.get('userInfoCache')?.mid;
    var res = await Request().get(
      Api.getSeriesDetailApi,
      data: {
        'mid': mid,
        'series_id': seriesId,
        'sort': sortReverse ? 'desc' : 'asc',
        'pn': pn,
        'ps': ps,
        if (currentMid != null) 'current_mid': currentMid,
      },
    );
    print(res);
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': MemberSeriesList.fromJson(res.data['data'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 获取up播放数、点赞数
  static Future memberView({required int mid}) async {
    var res = await Request().get(Api.getMemberViewApi, data: {'mid': mid});
    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 搜索follow
  static Future getfollowSearch({
    required int mid,
    required int ps,
    required int pn,
    required String name,
  }) async {
    Map<String, dynamic> data = {
      'vmid': mid,
      'pn': pn,
      'ps': ps,
      'order': 'desc',
      'order_type': 'attention',
      'gaia_source': 'main_web',
      'name': name,
      'web_location': 333.999,
    };
    Map params = await WbiSign().makSign(data);
    var res = await Request().get(Api.followSearch, data: {
      ...data,
      'w_rid': params['w_rid'],
      'wts': params['wts'],
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': FollowDataModel.fromJson(res.data['data'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 获取用户投稿视频（支持不同类型：普通、充电专属、合集、列表）
  static Future spaceArchive({
    required String type, // 'video', 'charging', 'season', 'series'
    required int mid,
    String? aid, // 用于游标分页
    String? order, // 'pubdate' 或 'click'
    String? sort, // 'desc' 或 'asc'
    int? pn, // 页码（充电专属使用）
    int? next, // 下一页标识
    int? seasonId, // 合集ID
    int? seriesId, // 列表ID
    bool? includeCursor, // 是否包含游标信息
  }) async {
    // 获取 access_key
    final accessKeyInfo = GStorage.localCache.get(
      LocalCacheKey.accessKey,
      defaultValue: {'mid': -1, 'value': '', 'refresh': ''},
    );
    final accessKey = accessKeyInfo['value'] as String?;

    final params = <String, dynamic>{
      'build': 8430300,
      'version': '8.43.0',
      'c_locale': 'zh_CN',
      'channel': 'master',
      'mobi_app': 'android',
      'platform': 'android',
      's_locale': 'zh_CN',
      'ps': 20,
      'statistics': '{"appId":1,"platform":3,"version":"8.43.0","abtest":""}',
      'vmid': mid,
      'ts': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    };

    // 添加 access_key（如果已登录）
    if (accessKey != null && accessKey.isNotEmpty) {
      params['access_key'] = accessKey;
    }

    // 根据类型添加特定参数
    if (aid != null) params['aid'] = aid;
    if (order != null) params['order'] = order;
    if (sort != null) params['sort'] = sort;
    if (pn != null) params['pn'] = pn;
    if (next != null) params['next'] = next;
    if (seasonId != null) params['season_id'] = seasonId;
    if (seriesId != null) params['series_id'] = seriesId;
    if (includeCursor != null) params['include_cursor'] = includeCursor;

    // 设置qn参数
    params['qn'] = type == 'video' ? 80 : 32;

    // 对参数进行签名
    AppSign.appSign(params);

    // 根据类型选择API端点
    String apiUrl;
    switch (type) {
      case 'video':
        apiUrl = Api.spaceArchive;
        break;
      case 'charging':
        apiUrl = Api.spaceChargingArchive;
        break;
      case 'season':
        apiUrl = Api.spaceSeason;
        break;
      case 'series':
        apiUrl = Api.spaceSeries;
        break;
      default:
        apiUrl = Api.spaceArchive;
    }

    print('========== spaceArchive API Request ==========');
    print('Type: $type');
    print('API URL: $apiUrl');
    print('Season ID: $seasonId');
    print('Series ID: $seriesId');
    print('Order: $order');
    print('==============================================');

    var res = await Request().get(
      apiUrl,
      data: params,
      options: Options(
        headers: {
          'bili-http-engine': 'cronet',
          'user-agent':
              'Mozilla/5.0 BiliDroid/8.43.0 (bbcallen@gmail.com) os/android model/android mobi_app/android build/8430300 channel/master innerVer/8430300 osVer/15 network/2',
        },
      ),
    );

    print('========== spaceArchive API Response ==========');
    print('Response code: ${res.data['code']}');
    print('Message: ${res.data['message']}');
    if (res.data['code'] == 0 && res.data['data'] != null) {
      print('Data keys: ${res.data['data'].keys}');
      print('Has cursor: ${res.data['data'].containsKey('cursor')}');
      print('Has has_more: ${res.data['data'].containsKey('has_more')}');
      print('Item count: ${res.data['data']['item']?.length ?? 0}');
      if (res.data['data'].containsKey('cursor')) {
        print('Cursor: ${res.data['data']['cursor']}');
      }
      if (res.data['data'].containsKey('has_more')) {
        print('Has more: ${res.data['data']['has_more']}');
      }
    }
    print('==============================================');

    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 获取用户图文（opus）
  static Future memberOpus({
    required int hostMid,
    required int page,
    String offset = '',
    String type = 'all',
  }) async {
    Map<String, dynamic> data = {
      'host_mid': hostMid,
      'page': page,
      'offset': offset,
      'type': type,
      'web_location': 333.1387,
    };

    Map params = await WbiSign().makSign(data);

    print('========== memberOpus API Request ==========');
    print('Host MID: $hostMid');
    print('Page: $page');
    print('Offset: $offset');
    print('Type: $type');
    print('==============================================');

    var res = await Request().get(
      Api.memberOpus,
      data: {
        ...data,
        'w_rid': params['w_rid'],
        'wts': params['wts'],
      },
    );

    print('========== memberOpus API Response ==========');
    print('Response code: ${res.data['code']}');
    print('Message: ${res.data['message']}');
    if (res.data['code'] == 0) {
      print('Items count: ${res.data['data']?['items']?.length ?? 0}');
      print('Has more: ${res.data['data']?['has_more']}');
      print('Offset: ${res.data['data']?['offset']}');
    }
    print('==============================================');

    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 获取用户投币视频列表（App API）
  static Future spaceCoinArc({
    required int mid,
    required int page,
    int pageSize = 20,
  }) async {
    // 获取 access_key
    final accessKeyInfo = GStorage.localCache.get(
      LocalCacheKey.accessKey,
      defaultValue: {'mid': -1, 'value': '', 'refresh': ''},
    );
    final accessKey = accessKeyInfo['value'] as String?;

    final params = <String, dynamic>{
      'build': 8430300,
      'version': '8.43.0',
      'c_locale': 'zh_CN',
      'channel': 'master',
      'mobi_app': 'android',
      'platform': 'android',
      's_locale': 'zh_CN',
      'vmid': mid,
      'pn': page,
      'ps': pageSize,
      'ts': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    };

    // 添加 access_key（如果已登录）
    if (accessKey != null && accessKey.isNotEmpty) {
      params['access_key'] = accessKey;
    }

    // 添加 App 签名
    AppSign.appSign(params);

    var res = await Request().get(
      Api.spaceCoinArc,
      data: params,
    );

    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }

  // 获取用户点赞视频列表（App API）
  static Future spaceLikeArc({
    required int mid,
    required int page,
    int pageSize = 20,
  }) async {
    // 获取 access_key
    final accessKeyInfo = GStorage.localCache.get(
      LocalCacheKey.accessKey,
      defaultValue: {'mid': -1, 'value': '', 'refresh': ''},
    );
    final accessKey = accessKeyInfo['value'] as String?;

    final params = <String, dynamic>{
      'build': 8430300,
      'version': '8.43.0',
      'c_locale': 'zh_CN',
      'channel': 'master',
      'mobi_app': 'android',
      'platform': 'android',
      's_locale': 'zh_CN',
      'vmid': mid,
      'pn': page,
      'ps': pageSize,
      'ts': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    };

    // 添加 access_key（如果已登录）
    if (accessKey != null && accessKey.isNotEmpty) {
      params['access_key'] = accessKey;
    }

    // 添加 App 签名
    AppSign.appSign(params);

    var res = await Request().get(
      Api.spaceLikeArc,
      data: params,
    );

    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {'status': false, 'msg': res.data['message']};
    }
  }
}
