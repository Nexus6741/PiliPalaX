import 'audio_handler.dart';
import 'audio_session.dart';
import 'download_service.dart';
import 'package:flutter_floating/floating/assist/floating_slide_type.dart';
import 'package:flutter_floating/floating/floating.dart';
import 'package:flutter_floating/floating/manager/floating_manager.dart';
import 'package:get/get.dart';

late VideoPlayerServiceHandler videoPlayerServiceHandler;
late AudioSessionHandler audioSessionHandler;
Floating? floatingWindow;
const globalId = 'global_floating_window';

Future<void> setupServiceLocator() async {
  final audio = await initAudioService();
  videoPlayerServiceHandler = audio;
  audioSessionHandler = AudioSessionHandler();

  // 初始化下载服务
  Get.put(DownloadService());
}
