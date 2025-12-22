import 'package:PiliPalaX/models/login_devices/login_device.dart';

class LoginDevicesData {
  final List<LoginDevice>? devices;

  LoginDevicesData({this.devices});

  factory LoginDevicesData.fromJson(Map<String, dynamic> json) {
    return LoginDevicesData(
      devices: json['devices'] != null
          ? (json['devices'] as List)
              .map((e) => LoginDevice.fromJson(e))
              .toList()
          : null,
    );
  }
}
