import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/pages/log_table/controller.dart';

class LogPage<T> extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage<T>> createState() => _LogPageState<T>();
}

class _LogPageState<T> extends State<LogPage<T>> {
  late final LogController<dynamic, T> _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.arguments as LogController<dynamic, T>;
    Get.put(_controller);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(_controller.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  left: 10 + padding.left,
                  right: 10 + padding.right,
                  bottom: padding.bottom + 100,
                ),
                sliver: Obx(() => _buildBody(_controller.loadingState.value)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState loadingState) {
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

    final List<T>? response = loadingState.data as List<T>?;
    if (response == null || response.isEmpty) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: '暂无数据',
          fn: _controller.onReload,
        ),
      );
    }

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final outline = theme.colorScheme.outline.withOpacity(0.1);
        final divider = Divider(height: 1, color: outline);
        final sliverDivider = SliverToBoxAdapter(child: divider);
        final dividerV = VerticalDivider(width: 1, color: outline);

        return SliverMainAxisGroup(
          slivers: [
            sliverDivider,
            SliverToBoxAdapter(
              child: ColoredBox(
                color: theme.colorScheme.onInverseSurface,
                child: _item(_controller.header, dividerV, isHeader: true),
              ),
            ),
            sliverDivider,
            SliverList.separated(
              itemCount: response.length,
              itemBuilder: (context, index) {
                return _item(response[index], dividerV);
              },
              separatorBuilder: (context, index) => divider,
            ),
            sliverDivider,
          ],
        );
      },
    );
  }

  Widget _item(T item, Widget divider, {bool isHeader = false}) {
    Widget text(int flex, String text) => Expanded(
          flex: flex,
          child: Padding(
            padding: isHeader
                ? const EdgeInsets.symmetric(vertical: 6)
                : const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: isHeader
                    ? const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)
                    : const TextStyle(fontSize: 13),
              ),
            ),
          ),
        );

    final columns = _controller.getFlexAndText(item);
    Widget content = Row(
      children: [
        divider,
        for (var col in columns) ...[
          text(col.flex, col.text),
          divider,
        ],
      ],
    );

    return IntrinsicHeight(
      child: isHeader ? content : SelectionArea(child: content),
    );
  }
}
