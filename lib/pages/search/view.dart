import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'controller.dart';
import 'widgets/hot_keyword.dart';
import 'widgets/search_text.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();
}

class _SearchPageState extends State<SearchPage> with RouteAware {
  final SSearchController _searchController = Get.put(SSearchController());
  late Future? _futureBuilderFuture;
  bool _showContent = false; // 控制内容动画的显�?

  @override
  void initState() {
    super.initState();
    _futureBuilderFuture = _searchController.queryHotSearchList();

    // 检查是否是从搜索结果页面跳转过来的，需要保留关键词
    // 由于控制器可能被缓存，onInit() 不会再次执行，所以在这里处理
    if (Get.parameters['searchType'] == 'fromSearchResult' &&
        Get.parameters['keyword'] != null) {
      _searchController.searchKeyWord.value = Get.parameters['keyword']!;
      _searchController.controller.value.text = Get.parameters['keyword']!;
    }

    // 延迟显示内容动画，等待展开动画接近完成
    // 展开动画 400ms，延�?280ms 后开始内容动�?
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _showContent = true;
        });
      }
    });
  }

  @override
  // 返回当前页面�?
  void didPopNext() async {
    _searchController.searchFocusNode.requestFocus();
    super.didPopNext();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SearchPage.routeObserver
        .subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    // 只有从搜索结果页面跳转过来的才不清空搜索框，其他情况都清�?
    if (Get.parameters['searchType'] != 'fromSearchResult') {
      // 页面销毁时清空搜索框内容，确保下次进入时搜索框为空
      _searchController.controller.value.clear();
      _searchController.searchKeyWord.value = '';
      _searchController.searchSuggestList.value = [];
    }
    SearchPage.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 60,
        automaticallyImplyLeading: false, // 移除默认的返回按�?
        titleSpacing: 14,
        title: Row(
          children: [
            // 搜索框容�?
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.onSecondaryContainer.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search_outlined,
                      color: colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(
                        () => TextField(
                          autofocus: true,
                          focusNode: _searchController.searchFocusNode,
                          controller: _searchController.controller.value,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) =>
                              _searchController.onChange(value),
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: _searchController.hintText,
                            hintStyle: TextStyle(color: colorScheme.outline),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (String value) =>
                              _searchController.submit(),
                        ),
                      ),
                    ),
                    // 清空按钮（仅在有内容时显示）
                    Obx(
                      () => _searchController.controller.value.text.isNotEmpty
                          ? IconButton(
                              tooltip: '清空',
                              icon: Icon(
                                Icons.clear,
                                size: 20,
                                color: colorScheme.outline,
                              ),
                              onPressed: () => _searchController.onClear(),
                            )
                          : const SizedBox(width: 8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 取消按钮
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // 搜索建议
            _searchSuggest(),
            // 搜索历史和热搜只在展开动画接近完成后才显示
            if (_showContent) ...[
              _history(),
              Visibility(
                visible: _searchController.enableHotKey,
                child: hotSearch(_searchController, isTrending: true),
              ),
              Visibility(
                visible: _searchController.enableSearchRcmd,
                child: hotSearch(_searchController, isTrending: false),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom + 50),
          ],
        ),
      ),
    );
  }

  Widget _searchSuggest() {
    SSearchController ssCtr = _searchController;
    return Obx(
      () => ssCtr.searchSuggestList.isNotEmpty &&
              ssCtr.searchSuggestList.first.term != null &&
              ssCtr.controller.value.text != ''
          ? AnimationLimiter(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: ssCtr.searchSuggestList.length,
                itemBuilder: (context, index) {
                  final suggestionItem = InkWell(
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onTap: () => ssCtr
                        .onClickKeyword(ssCtr.searchSuggestList[index].term!),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 20, top: 9, bottom: 9),
                      child: ssCtr.searchSuggestList[index].textRich,
                    ),
                  );

                  // 只在展开动画接近完成后才显示动画
                  return _showContent
                      ? AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 300),
                          child: SlideAnimation(
                            verticalOffset: 20.0,
                            child: FadeInAnimation(
                              child: suggestionItem,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(); // 完全不渲染，避免性能问题
                },
              ),
            )
          : const SizedBox(),
    );
  }

  Widget hotSearch(ctr, {bool isTrending = true}) {
    final String title = isTrending ? '大家都在�? : '搜索发现';
    final Future Function() refreshFn =
        isTrending ? ctr.queryHotSearchList : ctr.queryRecommendList;

    return AnimationLimiter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            10, !isTrending && _searchController.enableHotKey ? 4 : 14, 4, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 350),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isTrending)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            height: 34,
                            child: TextButton(
                              onPressed: () => Get.toNamed('/searchTrending'),
                              child: Row(
                                children: [
                                  Text(
                                    '完整榜单',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  Icon(
                                    size: 18,
                                    Icons.keyboard_arrow_right,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    SizedBox(
                      height: 34,
                      child: TextButton.icon(
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                              const EdgeInsets.only(
                                  left: 10, top: 6, bottom: 6, right: 10)),
                        ),
                        onPressed: refreshFn,
                        icon: const Icon(Icons.refresh_outlined, size: 18),
                        label: const Text('刷新'),
                      ),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, boxConstraints) {
                  final double width = boxConstraints.maxWidth;
                  print(
                      '🎨 [视图] LayoutBuilder: isTrending=$isTrending, width=$width');
                  if (isTrending) {
                    print('🎨 [视图] 构建热搜列表');
                    return FutureBuilder(
                      future: _futureBuilderFuture,
                      builder: (context, snapshot) {
                        print(
                            '🎨 [视图] FutureBuilder状�? ${snapshot.connectionState}, hasData: ${snapshot.hasData}');
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.data == null) {
                            print('🎨 [视图] 热搜数据为null');
                            return const SizedBox();
                          }
                          Map data = snapshot.data as Map;
                          print(
                              '🎨 [视图] 热搜数据: status=${data['status']}, msg=${data['msg']}');
                          if (data['status']) {
                            return Obx(
                              () {
                                print(
                                    '🎨 [视图] 热搜列表长度: ${_searchController.hotSearchList.length}');
                                print(
                                    '🎨 [视图] 热搜列表类型: ${_searchController.hotSearchList.runtimeType}');
                                if (_searchController.hotSearchList.isEmpty) {
                                  print('🎨 [视图] 热搜列表为空');
                                  return const SizedBox();
                                }
                                return HotKeyword(
                                  width: width,
                                  hotSearchList:
                                      _searchController.hotSearchList.toList(),
                                  onClick: (keyword) async {
                                    _searchController.searchFocusNode.unfocus();
                                    await Future.delayed(
                                        const Duration(milliseconds: 150));
                                    _searchController.onClickKeyword(keyword);
                                  },
                                );
                              },
                            );
                          } else {
                            print('🎨 [视图] 热搜请求失败');
                            return CustomScrollView(
                              shrinkWrap: true,
                              slivers: [
                                HttpError(
                                  errMsg: data['msg'],
                                  fn: () => setState(() {
                                    _futureBuilderFuture =
                                        _searchController.queryHotSearchList();
                                  }),
                                ),
                              ],
                            );
                          }
                        } else {
                          // 缓存数据
                          print(
                              '🎨 [视图] 使用缓存数据: ${_searchController.hotSearchList.length}');
                          if (_searchController.hotSearchList.isNotEmpty) {
                            return HotKeyword(
                              width: width,
                              hotSearchList:
                                  _searchController.hotSearchList.toList(),
                            );
                          } else {
                            return const SizedBox();
                          }
                        }
                      },
                    );
                  } else {
                    // 搜索发现
                    print('🎨 [视图] 构建搜索发现列表');
                    return Obx(
                      () {
                        print(
                            '🎨 [视图] 搜索发现列表长度: ${_searchController.recommendList.length}');
                        print(
                            '🎨 [视图] 搜索发现列表类型: ${_searchController.recommendList.runtimeType}');
                        if (_searchController.recommendList.isEmpty) {
                          print('🎨 [视图] 搜索发现列表为空');
                          return const SizedBox();
                        }
                        return HotKeyword(
                          width: width,
                          hotSearchList:
                              _searchController.recommendList.toList(),
                          showRecommendReason: true,
                          onClick: (keyword) async {
                            _searchController.searchFocusNode.unfocus();
                            await Future.delayed(
                                const Duration(milliseconds: 150));
                            _searchController.onClickKeyword(keyword);
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _history() {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 0, 6, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchController.historyList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 0, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '搜索历史',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => _searchController.onClearHis(),
                      child: const Text('清空'),
                    )
                  ],
                ),
              ),
            Obx(
              () => AnimationLimiter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  direction: Axis.horizontal,
                  textDirection: TextDirection.ltr,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 300),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 20.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [
                      for (int i = 0;
                          i < _searchController.historyList.length;
                          i++)
                        SearchText(
                          searchText: _searchController.historyList[i],
                          searchTextIdx: i,
                          onSelect: (value) =>
                              _searchController.onSelect(value),
                          onLongSelect: (value) =>
                              _searchController.onLongSelect(value),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
