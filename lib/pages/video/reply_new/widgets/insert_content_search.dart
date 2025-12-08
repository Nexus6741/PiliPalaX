import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/models/user/history.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:easy_debounce/easy_throttle.dart';

/// 插入内容搜索页面
/// 显示用户的 bilibili 观看历史记录，支持搜索
/// 选择后返回视频/专栏的 URL
class InsertContentSearchPage extends StatefulWidget {
  const InsertContentSearchPage({super.key});

  @override
  State<InsertContentSearchPage> createState() =>
      _InsertContentSearchPageState();
}

class _InsertContentSearchPageState extends State<InsertContentSearchPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController = TextEditingController();
  late final FocusNode _focusNode = FocusNode();
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  late final ScrollController _scrollController = ScrollController();

  final RxList<HisListItem> _historyList = <HisListItem>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _loadingText = '加载中...'.obs;
  int _pn = 1;

  @override
  void initState() {
    super.initState();
    // 初始化时加载历史记录
    _loadHistory();
    // 添加滚动监听，实现加载更多
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      EasyThrottle.throttle('loadMore', const Duration(seconds: 1), () {
        _loadMore();
      });
    }
  }

  /// 加载历史记录（初始加载或搜索）
  Future<void> _loadHistory({bool isSearch = false}) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _pn = 1;
    _loadingText.value = '加载中...';

    try {
      final keyword = _searchController.text.trim();
      Map res;

      if (keyword.isEmpty) {
        // 无搜索关键词，获取全部历史记录
        res = await UserHttp.historyList(null, null);
      } else {
        // 有搜索关键词，搜索历史记录
        res = await UserHttp.searchHistory(pn: _pn, keyword: keyword);
      }

      if (res['status']) {
        final data = res['data'] as HistoryData;
        _historyList.value = data.list ?? [];

        if (data.hasMore == false || (_historyList.isEmpty)) {
          _loadingText.value = '没有更多了';
        }
      } else {
        SmartDialog.showToast(res['msg'] ?? '加载失败');
      }
    } catch (e) {
      SmartDialog.showToast('加载出错: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_isLoading.value || _loadingText.value == '没有更多了') return;

    _isLoading.value = true;
    _pn++;

    try {
      final keyword = _searchController.text.trim();
      Map res;

      if (keyword.isEmpty) {
        // 无搜索关键词，获取更多历史记录
        final lastItem = _historyList.isNotEmpty ? _historyList.last : null;
        res = await UserHttp.historyList(
          lastItem?.kid,
          lastItem?.viewAt,
        );
      } else {
        // 有搜索关键词，搜索更多历史记录
        res = await UserHttp.searchHistory(pn: _pn, keyword: keyword);
      }

      if (res['status']) {
        final data = res['data'] as HistoryData;
        _historyList.addAll(data.list ?? []);

        if (data.hasMore == false) {
          _loadingText.value = '没有更多了';
        }
      }
    } catch (e) {
      _pn--;
    } finally {
      _isLoading.value = false;
    }
  }

  /// 搜索
  void _search() {
    _loadHistory(isSearch: true);
  }

  /// 清空搜索
  void _onClear() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _loadHistory();
    } else {
      Get.back();
    }
  }

  /// 选择历史记录项
  void _selectItem(HisListItem item) {
    String title = item.title ?? '';
    String url = '';

    final business = item.history?.business ?? '';
    final bvid = item.history?.bvid;
    final oid = item.history?.oid;

    // 根据业务类型生成短链接 URL (b23.tv 格式)
    if (business == 'archive' && bvid != null && bvid.isNotEmpty) {
      // 视频 - 使用 b23.tv 短链接格式
      url = 'https://b23.tv/$bvid';
    } else if (business == 'pgc' && item.uri != null) {
      // 番剧/电影 - 使用原始 uri
      url = item.uri!;
    } else if (business.contains('article') && oid != null) {
      // 专栏
      url = 'https://www.bilibili.com/read/cv$oid';
    } else if (business == 'live' && oid != null) {
      // 直播
      url = 'https://live.bilibili.com/$oid';
    } else if (item.uri != null && item.uri!.isNotEmpty) {
      // 其他类型，使用 uri
      url = item.uri!;
    }

    if (title.isNotEmpty && url.isNotEmpty) {
      Get.back(result: {
        'title': title,
        'url': url,
      });
    } else {
      SmartDialog.showToast('无法获取链接');
    }
  }

  /// 获取当前 Tab 对应的历史记录列表
  List<HisListItem> _getFilteredList() {
    final currentTab = _tabController.index;
    return _historyList.where((item) {
      final business = item.history?.business ?? '';
      if (currentTab == 0) {
        // 视频 Tab：包括普通视频和番剧
        return business == 'archive' || business == 'pgc';
      } else {
        // 专栏 Tab
        return business.contains('article');
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: TextField(
          autofocus: false,
          focusNode: _focusNode,
          controller: _searchController,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: '搜索',
            border: InputBorder.none,
            suffixIcon: IconButton(
              tooltip: '清空',
              icon: const Icon(Icons.clear, size: 22),
              onPressed: _onClear,
            ),
          ),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(
            tooltip: '搜索',
            onPressed: _search,
            icon: const Icon(Icons.search, size: 22),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '视频'),
              Tab(text: '专栏'),
            ],
            onTap: (_) {
              setState(() {});
            },
          ),
          Expanded(
            child: Obx(() {
              if (_isLoading.value && _historyList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryList(isVideo: true),
                  _buildHistoryList(isVideo: false),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList({required bool isVideo}) {
    return Obx(() {
      final filteredList = _historyList.where((item) {
        final business = item.history?.business ?? '';
        if (isVideo) {
          return business == 'archive' || business == 'pgc';
        } else {
          return business.contains('article');
        }
      }).toList();

      if (filteredList.isEmpty) {
        return Center(
          child: Text(
            _searchController.text.isEmpty ? '暂无历史记录' : '未找到相关内容',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        itemCount: filteredList.length + 1,
        itemBuilder: (context, index) {
          if (index == filteredList.length) {
            // 底部加载更多指示器
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  _loadingText.value,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          }

          final item = filteredList[index];
          return _buildHistoryItem(item);
        },
      );
    });
  }

  Widget _buildHistoryItem(HisListItem item) {
    final String cover = item.cover ?? item.pic ?? '';
    final String title = item.title ?? '';
    final String authorName = item.authorName ?? '';
    final String badge = item.badge ?? '';
    final int? duration = item.duration;

    return ListTile(
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: NetworkImgLayer(
              width: 120,
              height: 75,
              src: cover,
            ),
          ),
          if (duration != null && duration > 0)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          if (badge.isNotEmpty)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'UP: $authorName',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _selectItem(item),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}
