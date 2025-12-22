class LoginLogItem {
  final String timeAt;
  final String ip;
  final String geo;

  const LoginLogItem({
    required this.timeAt,
    required this.ip,
    required this.geo,
  });

  factory LoginLogItem.fromJson(Map<String, dynamic> json) {
    return LoginLogItem(
      timeAt: json['time_at'] ?? '',
      ip: json['ip'] ?? '',
      geo: json['geo'] ?? '',
    );
  }
}
