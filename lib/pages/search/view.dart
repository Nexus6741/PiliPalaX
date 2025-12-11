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
  bool _showContent = false; // 控制内容动画的显示

  @override
  void initState() {
    super.initState();
    _futureBuilderFuture = _searchController.queryHotSearchList();

    // 延迟显示内容动画，等待展开动画接近完成
    // 展开动画 400ms，延迟 280ms 后开始内容动画
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _showContent = true;
        });
      }
    });
  }

  @override
  // 返回当前页面时
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
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 60,
        automaticallyImplyLeading: false, // 移除默认的返回按钮
        titleSpacing: 14,
        title: Row(
          children: [
            // 搜索框容器
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
                child: hotSearch(_searchController),
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

  Widget hotSearch(ctr) {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 4, 20),
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
                    Text(
                      '大家都在搜',
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
                        onPressed: () => ctr.queryHotSearchList(),
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
                  return FutureBuilder(
                    future: _futureBuilderFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.data == null) {
                          return const SizedBox();
                        }
                        Map data = snapshot.data as Map;
                        if (data['status']) {
                          return Obx(
                            () => HotKeyword(
                              width: width,
                              // ignore: invalid_use_of_protected_member
                              hotSearchList:
                                  _searchController.hotSearchList.value,
                              onClick: (keyword) async {
                                _searchController.searchFocusNode.unfocus();
                                await Future.delayed(
                                    const Duration(milliseconds: 150));
                                _searchController.onClickKeyword(keyword);
                              },
                            ),
                          );
                        } else {
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
                        if (_searchController.hotSearchList.isNotEmpty) {
                          return HotKeyword(
                            width: width,
                            hotSearchList: _searchController.hotSearchList,
                          );
                        } else {
                          return const SizedBox();
                        }
                      }
                    },
                  );
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
