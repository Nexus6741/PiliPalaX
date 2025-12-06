import 'dart:convert';

import 'package:PiliPalaX/common/constants.dart';
import 'package:crypto/crypto.dart';

/// App 签名工具类
abstract class AppSign {
  /// 对请求参数进行签名
  /// 会在 params 中添加 appkey 和 sign 字段
  static void appSign(
    Map<String, dynamic> params, {
    String appkey = Constants.appKey,
    String appsec = Constants.appSec,
  }) {
    params['appkey'] = appkey;
    var searchParams = Uri(
      queryParameters: params.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    ).query;
    var sortedQueryString = (searchParams.split('&')..sort()).join('&');

    params['sign'] =
        md5.convert(utf8.encode(sortedQueryString + appsec)).toString();
  }
}
