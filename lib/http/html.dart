import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'index.dart';

class HtmlHttp {
  // 将JSON格式的专栏内容转换为HTML
  static String _convertJsonToHtml(String jsonContent) {
    try {
      final jsonData = json.decode(jsonContent);
      final ops = jsonData['ops'] as List;

      StringBuffer html = StringBuffer();

      for (var op in ops) {
        final insert = op['insert'];
        final attributes = op['attributes'];

        if (insert is String) {
          // 文本内容
          String text = insert;

          // 处理换行
          if (text == '\n') {
            if (attributes != null) {
              // 带属性的换行（如标题、列表等）
              if (attributes['header'] != null) {
                // 标题已在前面处理，这里跳过
                continue;
              } else if (attributes['list'] != null) {
                // 列表项结束
                html.write('</li>');
                continue;
              }
            }
            html.write('<br/>');
            continue;
          }

          // 应用文本样式
          String styledText = text;
          if (attributes != null) {
            if (attributes['bold'] == true) {
              styledText = '<strong>$styledText</strong>';
            }
            if (attributes['italic'] == true) {
              styledText = '<em>$styledText</em>';
            }
            if (attributes['strike'] == true) {
              styledText = '<s>$styledText</s>';
            }
            if (attributes['link'] != null) {
              styledText = '<a href="${attributes['link']}">$styledText</a>';
            }
            if (attributes['header'] != null) {
              int level = attributes['header'];
              styledText = '<h$level>$styledText</h$level>';
            }
            if (attributes['list'] != null) {
              String listType = attributes['list'];
              if (listType == 'bullet') {
                styledText = '<li>$styledText';
              } else if (listType == 'ordered') {
                styledText = '<li>$styledText';
              }
            }
          }

          html.write(styledText);
        } else if (insert is Map) {
          // 特殊内容（图片、视频卡片等）
          if (insert.containsKey('native-image')) {
            final img = insert['native-image'];
            html.write(
                '<img src="${img['url']}" alt="${img['alt'] ?? ''}" style="max-width:100%;"/>');
          } else if (insert.containsKey('cut-off')) {
            html.write('<hr/>');
          } else if (insert.containsKey('video-card')) {
            final card = insert['video-card'];
            html.write('<div class="video-card">[视频: ${card['id']}]</div>');
          } else if (insert.containsKey('article-card')) {
            final card = insert['article-card'];
            html.write('<div class="article-card">[专栏: ${card['id']}]</div>');
          }
        }
      }

      return html.toString();
    } catch (e) {
      // print('_convertJsonToHtml error: $e');
      rethrow;
    }
  }

  // article
  static Future reqHtml(id, dynamicType) async {
    var response = await Request().get(
      "https://www.bilibili.com/opus/$id",
      extra: {'ua': 'pc'},
    );

    if (response.data.contains('Redirecting to')) {
      RegExp regex = RegExp(r'//([\w\.]+)/(\w+)/(\w+)');
      Match match = regex.firstMatch(response.data)!;
      String matchedString = match.group(0)!;
      response = await Request().get(
        'https:$matchedString/',
        extra: {'ua': 'pc'},
      );
    }
    try {
      Document rootTree = parse(response.data);
      // log(response.data.body.toString());
      Element body = rootTree.body!;
      Element appDom = body.querySelector('#app')!;
      Element authorHeader = appDom.querySelector('.fixed-author-header')!;
      // 头像
      String avatar = authorHeader.querySelector('img')!.attributes['src']!;
      avatar = 'https:${avatar.split('@')[0]}';
      String uname = authorHeader
          .querySelector('.fixed-author-header__author__name')!
          .text;

      // 动态详情
      Element opusDetail = appDom.querySelector('.opus-detail')!;
      // 发布时间
      String updateTime =
          opusDetail.querySelector('.opus-module-author__pub__text')!.text;
      //
      String opusContent =
          opusDetail.querySelector('.opus-module-content')!.innerHtml;
      String? test;
      test = opusDetail
              .querySelector('.horizontal-scroll-album__pic__img')
              ?.innerHtml ??
          '';

      String commentId = opusDetail
          .querySelector('.bili-comment-container')!
          .className
          .split(' ')[1]
          .split('-')[2];
      // List imgList = opusDetail.querySelectorAll('bili-album__preview__picture__img');
      return {
        'status': true,
        'avatar': avatar,
        'uname': uname,
        'updateTime': updateTime,
        'content': test + opusContent,
        'commentId': int.parse(commentId)
      };
    } catch (err) {
      // print('err: $err');
    }
  }

  // read - 使用API方式获取专栏内容
  static Future reqReadHtml(id, dynamicType) async {
    try {
      // 提取数字ID
      RegExp digitRegExp = RegExp(r'\d+');
      Iterable<Match> matches = digitRegExp.allMatches(id);
      String cvId = matches.first.group(0)!;

      // 调用专栏API
      var response = await Request().get(
        Api.articleView,
        data: {
          'id': cvId,
        },
      );

      if (response.data['code'] == 0) {
        var data = response.data['data'];
        String avatar = data['author']['face'] ?? '';
        if (avatar.startsWith('//')) {
          avatar = 'https:$avatar';
        }
        avatar = avatar.split('@')[0];

        String uname = data['author']['name'] ?? '';
        String content = data['content'] ?? '';

        // 如果content是JSON格式(type=3)，需要转换为HTML
        if (data['type'] == 3 && content.isNotEmpty) {
          try {
            content = _convertJsonToHtml(content);
          } catch (e) {
            // print('JSON转换失败: $e');
            // 如果转换失败，保持原样
          }
        }

        return {
          'status': true,
          'avatar': avatar,
          'uname': uname,
          'updateTime': '',
          'content': content,
          'commentId': int.parse(cvId)
        };
      } else {
        return {'status': false, 'msg': response.data['message'] ?? '获取专栏内容失败'};
      }
    } catch (err) {
      // print('reqReadHtml error: $err');
      return {'status': false, 'msg': '获取专栏内容失败: $err'};
    }
  }
}
