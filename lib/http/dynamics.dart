import '../models/dynamics/result.dart';
import '../models/dynamics/up.dart';
import '../models/dynamics/topic_item.dart';
import '../models/dynamics/topic_card_list.dart';
import '../models/dynamics/topic_top_details.dart';
import '../models/dynamics/vote_model.dart';
import '../utils/utils.dart';
import 'index.dart';

class DynamicsHttp {
  static Future followDynamic({
    String? type,
    String? offset,
    int? mid,
  }) async {
    Map<String, dynamic> data = {
      'type': type ?? 'all',
      'timezone_offset': '-480',
      'offset': offset,
      'features': 'itemOpusStyle'
    };
    if (mid != -1) {
      data['host_mid'] = mid;
      data.remove('timezone_offset');
    }
    var res = await Request().get(Api.followDynamic, data: data);
    if (res.data['code'] == 0) {
      try {
        return {
          'status': true,
          'data': DynamicsDataModel.fromJson(res.data['data']),
        };
      } catch (err) {
        return {
          'status': false,
          'data': [],
          'msg': err.toString(),
        };
      }
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future followUp() async {
    var res = await Request().get(Api.followUp);
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': FollowUpModel.fromJson(res.data['data']),
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 动态点赞
  static Future likeDynamic({
    required String? dynamicId,
    required int? up,
  }) async {
    var res = await Request().post(
      Api.likeDynamic,
      queryParameters: {
        'dynamic_id': dynamicId,
        'up': up,
        'csrf': await Request.getCsrf(),
      },
    );
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

  //
  static Future dynamicDetail({
    String? id,
  }) async {
    var res = await Request().get(Api.dynamicDetail, data: {
      'timezone_offset': -480,
      'id': id,
      'features': 'itemOpusStyle',
    });
    if (res.data['code'] == 0) {
      try {
        return {
          'status': true,
          'data': DynamicItemModel.fromJson(res.data['data']['item']),
        };
      } catch (err) {
        return {
          'status': false,
          'data': [],
          'msg': err.toString(),
        };
      }
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 创建动态
  static Future createDynamic({
    String? content,
    String? title,
    List<String>? images,
    TopicItem? topic,
    int? voteId,
    bool isPrivate = false,
    bool allowReply = true,
    DateTime? scheduledTime,
    List<Map<String, dynamic>>? richContent,
  }) async {
    try {
      // 日志：接收到的参数
      print('=== createDynamic 参数 ===');
      print('content: $content');
      print('title: $title');
      print('images: $images');
      print('topic: $topic');
      if (topic != null) {
        print('topic.id: ${topic.id}');
        print('topic.name: ${topic.name}');
        print('topic类型: ${topic.runtimeType}');
      }
      print('voteId: $voteId');
      print('isPrivate: $isPrivate');
      print('allowReply: $allowReply');
      print('scheduledTime: $scheduledTime');

      // 构建动态内容
      List<Map<String, dynamic>> contents = [];

      // 如果提供了富文本内容，使用富文本
      if (richContent != null && richContent.isNotEmpty) {
        contents.addAll(richContent);
      } else if (content != null && content.isNotEmpty) {
        // 否则使用普通文本
        contents.add({
          'raw_text': content,
          'type': 1,
          'biz_id': '',
        });
      }

      // 添加投票（如果有）
      if (voteId != null) {
        print('=== 添加投票到内容 ===');
        print('投票ID: $voteId');
        contents.add({
          'raw_text': ' 投票 ',
          'type': 4, // 4: 投票类型
          'biz_id': voteId.toString(),
        });
      }

      // 构建请求数据
      Map<String, dynamic> dynReq = {
        'content': {
          'contents': contents,
          // 标题作为content对象的独立字段，不是contents数组的一部分
          if (title?.isNotEmpty == true) 'title': title,
        },
        'scene': images != null && images.isNotEmpty ? 2 : 1,
        'upload_id':
            '${DateTime.now().millisecondsSinceEpoch ~/ 1000}_${Utils.random.nextInt(9000) + 1000}',
        'meta': {
          'app_meta': {
            'from': 'create.dynamic.web',
            'mobi_app': 'web',
          },
        },
      };

      // 添加图片
      if (images != null && images.isNotEmpty) {
        dynReq['pics'] = images
            .map((url) => {
                  'img_src': url,
                  'img_width': 1080,
                  'img_height': 1080,
                  'img_size': 1024.0,
                })
            .toList();
      }

      // 添加话题
      if (topic != null) {
        print('=== 添加话题到请求 ===');
        final topicData = {
          'id': topic.id,
          'name': topic.name,
          'from_source': 'dyn.web.list',
          'from_topic_id': 0,
        };
        print('话题数据: $topicData');
        dynReq['topic'] = topicData;
      } else {
        print('=== 未添加话题（topic为null）===');
      }

      // 添加选项
      Map<String, dynamic> options = {};
      if (isPrivate) {
        options['private_pub'] = 1;
      }
      if (!allowReply) {
        options['close_comment'] = 1;
      }
      if (scheduledTime != null) {
        options['timer_pub_time'] =
            scheduledTime.millisecondsSinceEpoch ~/ 1000;
      }
      if (options.isNotEmpty) {
        dynReq['option'] = options;
      }

      // 最终请求数据
      Map<String, dynamic> requestData = {
        'dyn_req': dynReq,
      };

      // 日志：完整的请求数据
      print('=== 完整请求数据 ===');
      print('requestData: $requestData');
      print('dyn_req.topic: ${dynReq['topic']}');

      var res = await Request().post(
        Api.createDynamic,
        queryParameters: {
          'csrf': await Request.getCsrf(),
        },
        data: requestData,
      );

      // 日志：服务器响应
      print('=== 服务器响应 ===');
      print('code: ${res.data['code']}');
      print('message: ${res.data['message']}');
      print('data: ${res.data['data']}');

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
    } catch (err) {
      print('=== 发布动态异常 ===');
      print('错误: $err');
      return {
        'status': false,
        'msg': err.toString(),
      };
    }
  }

  // 获取话题推荐
  static Future getTopicRecommend({
    String keywords = '',
    String content = '',
    int pageSize = 20,
    int pageNum = 1,
  }) async {
    try {
      // 生成upload_id
      final uploadId =
          '${DateTime.now().millisecondsSinceEpoch ~/ 1000}_${Utils.random.nextInt(9000) + 1000}';

      var res = await Request().get(
        Api.topicPubSearch,
        data: {
          'keywords': keywords,
          'content': content,
          'upload_id': uploadId,
          'page_size': pageSize,
          'page_num': pageNum,
          'web_location': 333.1365,
        },
      );

      if (res.data['code'] == 0) {
        final topicItems = (res.data['data']?['topic_items'] as List?)
                ?.map((e) => TopicItem.fromJson(e))
                .toList() ??
            [];

        return {
          'status': true,
          'data': topicItems,
        };
      } else {
        return {
          'status': false,
          'msg': res.data['message'],
        };
      }
    } catch (err) {
      return {
        'status': false,
        'msg': err.toString(),
      };
    }
  }

  // 搜索话题
  static Future searchTopics({
    required String keywords,
    String content = '',
    int pageSize = 20,
    int pageNum = 1,
  }) async {
    return getTopicRecommend(
      keywords: keywords,
      content: content,
      pageSize: pageSize,
      pageNum: pageNum,
    );
  }

  // 创建投票
  static Future createVote(VoteInfo voteInfo) async {
    try {
      print('=== createVote 开始 ===');
      print('投票标题: ${voteInfo.title}');
      print('投票选项数: ${voteInfo.options.length}');
      print('是否多选: ${voteInfo.multiChoice}');
      print('持续时间(秒): ${voteInfo.getDurationInSeconds()}');

      // 使用新的 API 格式（JSON）
      final voteData = voteInfo.toJson();
      print('投票数据: $voteData');

      var res = await Request().post(
        Api.createVote,
        queryParameters: {
          'csrf': await Request.getCsrf(),
        },
        data: {
          'vote_info': voteData,
        },
      );

      print('=== createVote 响应 ===');
      print('code: ${res.data['code']}');
      print('message: ${res.data['message']}');
      print('data: ${res.data['data']}');

      if (res.data['code'] == 0) {
        return {
          'status': true,
          'data': res.data['data'],
        };
      } else {
        return {
          'status': false,
          'msg': res.data['msg'] ?? res.data['message'],
        };
      }
    } catch (err) {
      print('=== createVote 异常 ===');
      print('错误: $err');
      return {
        'status': false,
        'msg': err.toString(),
      };
    }
  }

  // 获取投票信息
  static Future getVoteInfo(int voteId) async {
    try {
      var res = await Request().get(
        Api.voteInfo,
        data: {
          'vote_id': voteId,
        },
      );

      if (res.data['code'] == 0) {
        return {
          'status': true,
          'data': VoteInfo.fromJson(res.data['data']),
        };
      } else {
        return {
          'status': false,
          'msg': res.data['message'],
        };
      }
    } catch (err) {
      return {
        'status': false,
        'msg': err.toString(),
      };
    }
  }

  // 获取话题详情
  static Future topicTop({required String topicId}) async {
    try {
      var res = await Request().get(
        Api.topicTop,
        data: {
          'topic_id': topicId,
          'source': 'Web',
        },
      );

      if (res.data['code'] == 0) {
        TopicTopDetails? data = res.data['data']?['top_details'] == null
            ? null
            : TopicTopDetails.fromJson(res.data['data']['top_details']);
        return {
          'status': true,
          'data': data,
        };
      } else {
        return {
          'status': false,
          'msg': res.data['message'],
        };
      }
    } catch (err) {
      return {
        'status': false,
        'msg': err.toString(),
      };
    }
  }

  // 获取话题下的动态列表
  static Future topicFeed({
    required String topicId,
    required String offset,
    required int sortBy,
  }) async {
    try {
      var res = await Request().get(
        Api.topicFeed,
        data: {
          'topic_id': topicId,
          'sort_by': sortBy,
          'offset': offset,
          'page_size': 20,
          'source': 'Web',
          'features': 'itemOpusStyle,listOnlyfans',
        },
      );

      if (res.data['code'] == 0) {
        TopicCardList? data = res.data['data']?['topic_card_list'] == null
            ? null
            : TopicCardList.fromJson(res.data['data']['topic_card_list']);
        return {
          'status': true,
          'data': data,
        };
      } else {
        return {
          'status': false,
          'msg': res.data['message'],
        };
      }
    } catch (err) {
      return {
        'status': false,
        'msg': err.toString(),
      };
    }
  }

  // 删除动态
  static Future removeDynamic({
    required String dynIdStr,
    String? dynType,
    String? ridStr,
  }) async {
    try {
      var res = await Request().post(
        Api.removeDynamic,
        queryParameters: {
          'platform': 'web',
          'csrf': await Request.getCsrf(),
        },
        data: {
          'dyn_id_str': dynIdStr,
          if (dynType != null) 'dyn_type': dynType,
          if (ridStr != null) 'rid_str': ridStr,
        },
      );

      if (res.data['code'] == 0) {
        return {
          'status': true,
        };
      } else {
        return {
          'status': false,
          'msg': res.data['message'],
        };
      }
    } catch (err) {
      return {
        'status': false,
        'msg': err.toString(),
      };
    }
  }
}
