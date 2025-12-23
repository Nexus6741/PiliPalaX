import 'dart:ui';
import 'package:PiliPalaX/common/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/feed_back.dart';
import './controller.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final RankController _rankController = Get.put(RankController());
  late int _selectedTabIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rankController.tabController =
        TabController(vsync: this, length: _rankController.tabs.length);
    _selectedTabIndex = _rankController.initialIndex.value;
    _rankController.tabController.addListener(() {
      if (!_rankController.tabController.indexIsChanging) {
        // _rankController.onRefresh();
        setState(() {
          _selectedTabIndex = _rankController.tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _rankController.tabController.removeListener(() {});
    _rankController.tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        const SizedBox(
          width: StyleString.cardSpace,
        ),
        LayoutBuilder(builder: (context, constraint) {
          return SingleChildScrollView(
              child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraint.maxHeight),
                  child: IntrinsicHeight(
                      child: MediaQuery.removePadding(
                          context: context,
                          removeLeft: true,
                          removeRight: true,
                          removeTop: true,
                          child: ClipRRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: 64,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface
                                      .withOpacity(0.3),
                                ),
                                child: ListView(
                                  padding: const EdgeInsets.only(bottom: 100),
                                  children: List.generate(
                                    _rankController.tabs.length,
                                    (index) => IntrinsicHeight(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            feedBack();
                                            if (_selectedTabIndex == index) {
                                              _rankController.tabsCtrList[index]
                                                      ()
                                                  .animateToTop();
                                            } else {
                                              setState(() {
                                                _rankController.tabController
                                                    .index = index;
                                                _selectedTabIndex = index;
                                              });
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _selectedTabIndex == index
                                                  ? theme.colorScheme.primary
                                                      .withOpacity(0.15)
                                                  : Colors.transparent,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_selectedTabIndex == index)
                                                  Container(
                                                    height: double.infinity,
                                                    width: 3,
                                                    color: theme
                                                        .colorScheme.primary,
                                                  )
                                                else
                                                  const SizedBox(width: 3),
                                                Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 7,
                                                    ),
                                                    child: Text(
                                                      _rankController
                                                          .tabs[index]['label'],
                                                      style: TextStyle(
                                                        color:
                                                            _selectedTabIndex ==
                                                                    index
                                                                ? theme
                                                                    .colorScheme
                                                                    .primary
                                                                : theme
                                                                    .colorScheme
                                                                    .onSurface,
                                                        fontSize: 15,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )))));
        }),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _rankController.tabController,
            children: _rankController.tabsPageList,
          ),
        ),
      ],
    );
  }
}
