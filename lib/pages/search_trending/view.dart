import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'controller.dart';

class SearchTrendingPage extends StatefulWidget {
  const SearchTrendingPage({super.key});

  @override
  State<SearchTrendingPage> createState() => _SearchTrendingPageState();
}

class _SearchTrendingPageState extends State<SearchTrendingPage> {
  final SearchTrendingController _controller =
      Get.put(SearchTrendingController());
  late double _offset;
  final RxDouble _scrollRatio = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _controller.scrollController.addListener(_listener);
  }

  @override
  void dispose() {
    _controller.scrollController.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (_controller.scrollController.hasClients) {
      _scrollRatio.value =
          (_controller.scrollController.position.pixels / _offset)
              .clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width - padding.left - padding.right;
    final isPortrait = size.height > size.width;
    final width = isPortrait ? maxWidth : min(640.0, maxWidth * 0.6);
    final height = width * 528 / 1125;
    _offset = height - 56 - padding.top;
    _listener();

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Obx(() {
          final scrollRatio = _scrollRatio.value;
          final flag = maxWidth > width || scrollRatio >= 0.5;
          return AppBar(
            title: Opacity(
              opacity: scrollRatio,
              child: Text(
                'bilibili热搜',
                style: TextStyle(
                  color: flag ? null : Colors.white,
                ),
              ),
            ),
            backgroundColor: colorScheme.surface.withOpacity(scrollRatio),
            foregroundColor: flag ? null : Colors.white,
            systemOverlayStyle: flag
                ? null
                : const SystemUiOverlayStyle(
                    statusBarBrightness: Brightness.dark,
                    statusBarIconBrightness: Brightness.light,
                  ),
            shape: scrollRatio == 1
                ? Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  )
                : null,
          );
        }),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: padding.left,
          right: padding.right,
        ),
        child: Center(
          child: SizedBox(
            width: width,
            child: RefreshIndicator(
              onRefresh: _controller.onRefresh,
              child: CustomScrollView(
                controller: _controller.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withOpacity(0.8),
                            colorScheme.secondary.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 80,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'bilibili热搜',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: padding.bottom + 100),
                    sliver: Obx(() => _buildBody(theme)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final divider = Divider(
      height: 1,
      indent: 48,
      color: colorScheme.outline.withOpacity(0.1),
    );

    if (_controller.isLoading.value) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_controller.errorMsg.value.isNotEmpty) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: _controller.errorMsg.value,
          fn: _controller.onRefresh,
        ),
      );
    }

    if (_controller.trendingList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('暂无数据'),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: _controller.trendingList.length,
      itemBuilder: (context, index) {
        final item = _controller.trendingList[index];
        final isTop = index < _controller.topCount.value;
        final displayIndex = isTop ? index : index - _controller.topCount.value;

        return ListTile(
          dense: true,
          onTap: () {
            Get.back();
            Get.toNamed('/searchResult', parameters: {
              'keyword': item.keyword ?? '',
            });
          },
          leading: isTop
              ? const Icon(
                  size: 17,
                  Icons.vertical_align_top_outlined,
                  color: Color(0xFFd1403e),
                )
              : Text(
                  '${displayIndex + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: displayIndex == 0
                        ? const Color(0xFFfdad13)
                        : displayIndex == 1
                            ? const Color(0xFF8aace1)
                            : displayIndex == 2
                                ? const Color(0xFFdfa777)
                                : colorScheme.outline,
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                  ),
                ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  item.keyword ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              if (item.icon?.isNotEmpty == true) ...[
                const SizedBox(width: 4),
                CachedNetworkImage(
                  imageUrl: item.icon!,
                  height: 16,
                  errorWidget: (context, url, error) => const SizedBox(),
                ),
              ] else if (item.showLiveIcon == true) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6699),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => divider,
    );
  }
}
