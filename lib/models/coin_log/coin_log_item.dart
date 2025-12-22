class CoinLogItem {
  final String time;
  final String delta;
  final String reason;

  const CoinLogItem({
    required this.time,
    required this.delta,
    required this.reason,
  });

  factory CoinLogItem.fromJson(Map<String, dynamic> json) {
    final int deltaInt = json['delta'] ?? 0;
    final String deltaStr = deltaInt > 0 ? '+$deltaInt' : '$deltaInt';

    return CoinLogItem(
      time: json['time'] ?? '',
      delta: deltaStr,
      reason: json['reason'] ?? '',
    );
  }
}
