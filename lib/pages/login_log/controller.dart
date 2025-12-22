import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/models/login_log/login_log_item.dart';
import 'package:PiliPalaX/pages/log_table/controller.dart';

class LoginLogController extends LogController<dynamic, LoginLogItem> {
  @override
  List<LoginLogItem>? getDataList(dynamic data) {
    if (data is Map<String, dynamic> && data['list'] != null) {
      return (data['list'] as List)
          .map((e) => LoginLogItem.fromJson(e))
          .toList();
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> customGetData() => UserHttp.loginLog();

  @override
  List<LogColumnData> getFlexAndText(LoginLogItem item) {
    return [
      LogColumnData(3, item.timeAt),
      LogColumnData(2, item.ip),
      LogColumnData(3, item.geo),
    ];
  }

  @override
  final LoginLogItem header = const LoginLogItem(
    timeAt: '时间',
    ip: 'IP',
    geo: '地理位置',
  );

  @override
  final String title = '登录记录';
}
