import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/space_setting/privacy.dart';
import 'package:PiliPalaX/models/space_setting/space_setting_model.dart';
import 'package:PiliPalaX/pages/space_setting/controller.dart';

class SpaceSettingPage extends StatefulWidget {
  const SpaceSettingPage({super.key});

  @override
  State<SpaceSettingPage> createState() => _SpaceSettingPageState();
}

class _SpaceSettingPageState extends State<SpaceSettingPage> {
  late final SpaceSettingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(SpaceSettingController());
  }

  @override
  void dispose() {
    _controller.onMod();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('空间设置')),
      body: Obx(() => _buildBody(theme, _controller.loadingState.value)),
    );
  }

  Widget _buildBody(ThemeData theme, LoadingState loadingState) {
    if (loadingState is Loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (loadingState is Error) {
      return HttpError(
        errMsg: loadingState.errMsg ?? '加载失败',
        fn: _controller.onReload,
      );
    }

    final Privacy? response = loadingState.data as Privacy?;
    if (response == null) {
      return HttpError(
        errMsg: '暂无数据',
        fn: _controller.onReload,
      );
    }

    return Builder(
      builder: (context) {
        final padding = MediaQuery.of(context).padding;
        final divider = Divider(
          height: 1,
          indent: max(16, padding.left),
          color: theme.colorScheme.outline.withOpacity(0.1),
        );
        final dividerL = SliverToBoxAdapter(
          child: Divider(
            height: 12,
            thickness: 12,
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        );
        return CustomScrollView(
          slivers: [
            dividerL,
            SliverList.separated(
              itemCount: response.list1.length,
              itemBuilder: (context, index) {
                return _item(response.list1[index]);
              },
              separatorBuilder: (context, index) => divider,
            ),
            dividerL,
            SliverList.separated(
              itemCount: response.list2.length,
              itemBuilder: (context, index) {
                return _item(response.list2[index]);
              },
              separatorBuilder: (context, index) => divider,
            ),
            dividerL,
            SliverList.separated(
              itemCount: response.list3.length,
              itemBuilder: (context, index) {
                return _item(response.list3[index]);
              },
              separatorBuilder: (context, index) => divider,
            ),
            dividerL,
            SliverToBoxAdapter(
              child: SizedBox(height: padding.bottom + 100),
            ),
          ],
        );
      },
    );
  }

  Widget _item(SpaceSettingModel item) {
    return Builder(
      builder: (context) {
        void onChanged([bool? value]) {
          _controller.hasMod ??= true;

          value ??= !item.boolVal;
          item.value = item.isReverse
              ? value
                  ? 0
                  : 1
              : value
                  ? 1
                  : 0;
          (context as Element).markNeedsBuild();
        }

        return ListTile(
          dense: true,
          onTap: onChanged,
          title: Text(
            item.name,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Transform.scale(
            alignment: Alignment.centerRight,
            scale: 0.8,
            child: Switch(
              value: item.boolVal,
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}
