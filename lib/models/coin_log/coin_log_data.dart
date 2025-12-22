import 'package:PiliPalaX/models/coin_log/coin_log_item.dart';

class CoinLogData {
  final List<CoinLogItem>? list;

  CoinLogData({this.list});

  factory CoinLogData.fromJson(Map<String, dynamic> json) {
    return CoinLogData(
      list: json['list'] != null
          ? (json['list'] as List).map((e) => CoinLogItem.fromJson(e)).toList()
          : null,
    );
  }
}
