import '../models/bangumi/list.dart';
import '../models/bangumi/timeline.dart';
import 'index.dart';

class BangumiHttp {
  static Future bangumiList({int? page}) async {
    var res = await Request().get(Api.bangumiList, data: {'page': page});
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': BangumiListDataModel.fromJson(res.data['data'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future bangumiFollow({int? mid, int pn = 1}) async {
    var res = await Request().get(Api.bangumiFollow, data: {
      'vmid': mid,
      'type': 1, // 1=追番, 2=追剧
      'pn': pn,
      'ps': 15,
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': BangumiListDataModel.fromJson(res.data['data'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 追番时间表
  // types: 1-番剧, 3-电影, 4-国创
  // before: 前几天
  // after: 后几天
  static Future<Map<String, dynamic>> bangumiTimeline({
    int types = 1,
    int before = 6,
    int after = 6,
  }) async {
    try {
      var res = await Request().get(
        Api.pgcTimeline,
        data: {
          'types': types,
          'before': before,
          'after': after,
        },
      );
      if (res.data['code'] == 0) {
        List<TimelineModel> list = [];
        if (res.data['result'] != null) {
          list = (res.data['result'] as List)
              .map((e) => TimelineModel.fromJson(e))
              .toList();
        }
        return {
          'status': true,
          'data': list,
        };
      } else {
        return {
          'status': false,
          'data': [],
          'msg': res.data['message'],
        };
      }
    } catch (e) {
      return {
        'status': false,
        'data': [],
        'msg': e.toString(),
      };
    }
  }
}
