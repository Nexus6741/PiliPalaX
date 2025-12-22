class LoginDevice {
  final String? deviceName;
  final String? latestLoginAt;
  final String? source;
  final bool? isCurrentDevice;

  LoginDevice({
    this.deviceName,
    this.latestLoginAt,
    this.source,
    this.isCurrentDevice,
  });

  factory LoginDevice.fromJson(Map<String, dynamic> json) {
    return LoginDevice(
      deviceName: json['device_name'],
      latestLoginAt: json['latest_login_at'],
      source: json['source'],
      isCurrentDevice: json['is_current_device'] == 1,
    );
  }
}
