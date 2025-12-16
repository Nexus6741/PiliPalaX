import 'package:PiliPalaX/models/pgc/pgc_index_result/data.dart';
import 'package:PiliPalaX/models/pgc/fav_pgc/data.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_condition/data.dart';
import 'index.dart';

class PgcHttp {
  /// 获取PGC索引结果
  static Future<Map<String, dynamic>> pgcIndex({
    int? page,
    int? indexType,
  }) async {
    try {
      var res = await Request().get(
        Api.pgcIndexResult,
        data: {
          'st': 1,
          'order': 3,
          'season_version': -1,
          'spoken_language_type': -1,
          'area': -1,
          'is_finish': -1,
          'copyright': -1,
          'season_status': -1,
          'season_month': -1,
          'year': -1,
          'style_id': -1,
          'sort': 0,
          // 番剧(indexType==null)使用season_type=1，影视(indexType!=null)不传season_type
          if (indexType == null) 'season_type': 1,
          'pagesize': 20,
          'type': indexType == null ? 1 : 0,
          'page': page ?? 1,
          if (indexType != null) 'index_type': indexType,
        },
      );
      if (res.data['code'] == 0) {
        final result = PgcIndexResult.fromJson(res.data['data']);
        return {
          'status': true,
          'data': result.list ?? [],
        };
      } else {
        return {
          'status': false,
          'data': [],
          'msg': res.data['message'] ?? '加载失败',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'data': [],
        'msg': '网络错误: $e',
      };
    }
  }

  /// 获取PGC索引结果（带完整数据）
  static Future<Map<String, dynamic>> pgcIndexResult({
    required int page,
    required Map<String, dynamic> params,
    int? seasonType,
    int? type,
    int? indexType,
  }) async {
    try {
      var res = await Request().get(
        Api.pgcIndexResult,
        data: {
          ...params,
          'page': page,
          'pagesize': 21,
          if (seasonType != null) 'season_type': seasonType,
          if (type != null) 'type': type,
          if (indexType != null) 'index_type': indexType,
        },
      );
      if (res.data['code'] == 0) {
        final result = PgcIndexResult.fromJson(res.data['data']);
        return {
          'status': true,
          'data': result,
        };
      } else {
        return {
          'status': false,
          'msg': res.data['message'] ?? '加载失败',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'msg': '网络错误: $e',
      };
    }
  }

  /// 获取PGC索引筛选条件
  static Future<Map<String, dynamic>> pgcIndexCondition({
    int? seasonType,
    int? type,
    int? indexType,
  }) async {
    try {
      var res = await Request().get(
        Api.pgcIndexCondition,
        data: {
          if (seasonType != null) 'season_type': seasonType,
          if (type != null) 'type': type,
          if (indexType != null) 'index_type': indexType,
        },
      );
      if (res.data['code'] == 0) {
        final data = PgcIndexConditionData.fromJson(res.data['data']);
        return {
          'status': true,
          'data': data,
        };
      } else {
        return {
          'status': false,
          'msg': res.data['message'] ?? '加载失败',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'msg': '网络错误: $e',
      };
    }
  }

  /// 获取收藏PGC列表
  static Future<Map<String, dynamic>> favPgc({
    required int mid,
    required int type,
    required int pn,
    int? followStatus,
  }) async {
    try {
      var res = await Request().get(
        Api.favPgc,
        data: {
          'vmid': mid,
          'type': type,
          'pn': pn,
          if (followStatus != null) 'follow_status': followStatus,
        },
      );
      if (res.data['code'] == 0) {
        final data = FavPgcData.fromJson(res.data['data']);
        return {
          'status': true,
          'data': data,
        };
      } else {
        return {
          'status': false,
          'msg': res.data['message'] ?? '加载失败',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'msg': '网络错误: $e',
      };
    }
  }

  /// 获取番剧/国创排行榜
  /// [seasonType] 1=番剧, 4=国创
  /// [day] 3=三日榜
  static Future<Map<String, dynamic>> pgcRankList({
    required int seasonType,
    int day = 3,
  }) async {
    try {
      // 番剧使用 /pgc/web/rank/list，国创使用 /pgc/season/rank/web/list
      final apiUrl = seasonType == 1 ? Api.pgcRankList : Api.pgcSeasonRankList;

      var res = await Request().get(
        apiUrl,
        data: {
          'day': day,
          'season_type': seasonType,
        },
      );

      if (res.data['code'] == 0) {
        // 番剧API使用result字段，国创API使用data字段
        final data = res.data['data'];
        final result = res.data['result'];
        List? list;

        if (data != null) {
          if (data is Map) {
            list = data['list'] as List?;
          } else if (data is List) {
            list = data;
          }
        } else if (result != null) {
          if (result is Map) {
            list = result['list'] as List?;
          } else if (result is List) {
            list = result;
          }
        }

        return {
          'status': true,
          'data': list ?? [],
        };
      } else {
        return {
          'status': false,
          'data': [],
          'msg': res.data['message'] ?? '加载失败',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'data': [],
        'msg': '网络错误: $e',
      };
    }
  }
}
