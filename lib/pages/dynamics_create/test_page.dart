import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class TestCreateDynamicPage extends StatelessWidget {
  const TestCreateDynamicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('测试发布动态'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('动态发布功能开发中...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                SmartDialog.showToast('功能开发中，敬请期待！');
              },
              child: const Text('发布动态'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
