class ExpLogItem {
  final String time;
  final String delta;
  final String reason;

  const ExpLogItem({
    required this.time,
    required this.delta,
    required this.reason,
  });

  factory ExpLogItem.fromJson(Map<String, dynamic> json) {
    final int deltaInt = json['delta'] ?? 0;
    final String deltaStr = deltaInt > 0 ? '+$deltaInt' : '$deltaInt';

    return ExpLogItem(
      time: json['time'] ?? '',
      delta: deltaStr,
      reason: json['reason'] ?? '',
    );
  }
}
