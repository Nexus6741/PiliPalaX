import 'package:PiliPalaX/models/login_log/login_log_item.dart';

class LoginLogData {
  final List<LoginLogItem>? list;

  LoginLogData({this.list});

  factory LoginLogData.fromJson(Map<String, dynamic> json) {
    return LoginLogData(
      list: json['list'] != null
          ? (json['list'] as List).map((e) => LoginLogItem.fromJson(e)).toList()
          : null,
    );
  }
}
