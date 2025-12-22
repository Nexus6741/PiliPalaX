import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/login_devices/login_device.dart';
import 'package:PiliPalaX/pages/login_devices/controller.dart';

class LoginDevicesPage extends StatefulWidget {
  const LoginDevicesPage({super.key});

  @override
  State<LoginDevicesPage> createState() => _LoginDevicesPageState();
}

class _LoginDevicesPageState extends State<LoginDevicesPage> {
  late final LoginDevicesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(LoginDevicesController());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('登录设备')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: RefreshIndicator(
            onRefresh: _controller.onRefresh,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: Obx(
                    () => _buildBody(
                      colorScheme,
                      _controller.loadingState.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    ColorScheme colorScheme,
    LoadingState loadingState,
  ) {
    if (loadingState is Loading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (loadingState is Error) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: loadingState.errMsg ?? '加载失败',
          fn: _controller.onReload,
        ),
      );
    }

    final List<LoginDevice>? response = loadingState.data as List<LoginDevice>?;
    if (response == null || response.isEmpty) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: '暂无登录设备',
          fn: _controller.onReload,
        ),
      );
    }

    final divider = Divider(
      height: 1,
      color: colorScheme.outline.withOpacity(0.1),
    );

    return SliverList.separated(
      itemBuilder: (context, index) {
        return _buildItem(colorScheme, response[index]);
      },
      itemCount: response.length,
      separatorBuilder: (context, index) => divider,
    );
  }

  Widget _buildItem(ColorScheme colorScheme, LoginDevice item) {
    final style = TextStyle(fontSize: 13, color: colorScheme.outline);
    return ListTile(
      dense: true,
      title: Text(
        item.deviceName ?? '',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${item.latestLoginAt} ${item.source}',
        style: style,
      ),
      trailing:
          item.isCurrentDevice == true ? Text('(本机)', style: style) : null,
    );
  }
}
