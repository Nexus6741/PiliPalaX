import 'dart:io';

import 'package:dio/dio.dart';

import '../models/video/reply/data.dart';
import '../models/video/reply/emote.dart';
import '../utils/storage.dart';
import 'api.dart';
import 'init.dart';

class ReplyHttp {
  static Future replyList({
    required int oid,
    required String nextOffset,
    required int type,
    int sort = 1,
  }) async {
    Options? options = GStorage.userInfo.get('userInfoCache') == null
        ? Options(
            headers: {HttpHeaders.cookieHeader: "buvid3= ; b_nut= ; sid= "})
        : null;
    var res = await Request().get(Api.replyList,
        data: {
          'oid': oid,
          'type': type,
          'pagination_str': '{"offset":"${nextOffset.replaceAll('"', '\\"')}"}',
          'mode': sort + 2, //2:按时间排序；3：按热度排序
        },
        options: options);
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': ReplyData.fromJson(res.data['data']),
      };
    } else {
      return {
        'status': false,
        'date': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future replyReplyList({
    required int oid,
    required String root,
    required int pageNum,
    required int type,
    int sort = 1,
  }) async {
    // 未登录状态下，将cookie设为空，可以请求到全部的评论
    Options? options = GStorage.userInfo.get('userInfoCache') == null
        ? Options(
            headers: {HttpHeaders.cookieHeader: "buvid3= ; b_nut= ; sid= "})
        : null;
    var res = await Request().get(Api.replyReplyList,
        data: {
          'oid': oid,
          'root': root,
          'pn': pageNum,
          'type': type,
          'sort': sort, // 使用传入的排序参数: 0=按时间, 1=按热度
          'csrf': await Request.getCsrf(),
        },
        options: options);
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': ReplyReplyData.fromJson(res.data['data']),
      };
    } else {
      return {
        'status': false,
        'date': [],
        'msg': res.data['message'],
      };
    }
  }

  // 获取对话列表（查看对话）
  static Future replyDialogList({
    required int oid,
    required int root,
    required int dialog,
    required int type,
    int size = 20,
    int? minFloor,
  }) async {
    Options? options = GStorage.userInfo.get('userInfoCache') == null
        ? Options(
            headers: {HttpHeaders.cookieHeader: "buvid3= ; b_nut= ; sid= "})
        : null;
    Map<String, dynamic> data = {
      'oid': oid,
      'root': root,
      'dialog': dialog,
      'type': type,
      'size': size,
    };
    if (minFloor != null) {
      data['min_floor'] = minFloor;
    }
    var res =
        await Request().get(Api.replyDialog, data: data, options: options);
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data'],
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 评论点赞
  static Future likeReply({
    required int type,
    required int oid,
    required int rpid,
    required int action,
  }) async {
    var res = await Request().post(
      Api.likeReply,
      queryParameters: {
        'type': type,
        'oid': oid,
        'rpid': rpid,
        'action': action,
        'csrf': await Request.getCsrf(),
      },
    );
    if (res.data['code'] == 0) {
      return {'status': true, 'data': res.data['data']};
    } else {
      return {
        'status': false,
        'date': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future getEmoteList({String? business}) async {
    var res = await Request().get(Api.myEmote, data: {
      'business': business ?? 'reply',
      'web_location': '333.1245',
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': EmoteModelData.fromJson(res.data['data']),
      };
    } else {
      return {
        'status': false,
        'date': [],
        'msg': res.data['message'],
      };
    }
  }
}
