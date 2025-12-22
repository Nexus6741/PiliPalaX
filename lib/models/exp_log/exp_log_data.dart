import 'package:PiliPalaX/models/exp_log/exp_log_item.dart';

class ExpLogData {
  final List<ExpLogItem>? list;

  ExpLogData({this.list});

  factory ExpLogData.fromJson(Map<String, dynamic> json) {
    return ExpLogData(
      list: json['list'] != null
          ? (json['list'] as List).map((e) => ExpLogItem.fromJson(e)).toList()
          : null,
    );
  }
}
