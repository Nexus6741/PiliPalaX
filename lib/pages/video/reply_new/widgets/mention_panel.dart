import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/video.dart';

/// 用户搜索和@功能面板
class MentionPanel extends StatefulWidget {
  final Function(String uid, String username) onMention;
  final VoidCallback onClose;

  const MentionPanel({
    super.key,
    required this.onMention,
    required this.onClose,
  });

  @override
  State<MentionPanel> createState() => _MentionPanelState();
}

class _MentionPanelState extends State<MentionPanel> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // 初始化时加载关注列表
    _loadFollowingUsers();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadFollowingUsers();
      return;
    }
    _searchUsers(query);
  }

  Future<void> _loadFollowingUsers() async {
    await _searchUsers('');
  }

  Future<void> _searchUsers(String keyword) async {
    setState(() {
      isLoading = true;
    });

    try {
      var result = await VideoHttp.searchUsers(keyword: keyword);
      if (result['status']) {
        final data = result['data'];
        final groups = data['groups'] as List;

        // 合并所有用户，优先显示关注的用户
        List<Map<String, dynamic>> allUsers = [];

        for (var group in groups) {
          final items = group['items'] as List;
          for (var item in items) {
            allUsers.add({
              'uid': item['uid'].toString(),
              'name': item['name'],
              'face': item['face'],
              'fans': item['fans'],
              'official_verify_type': item['official_verify_type'],
              'group_type': group['group_type'],
              'group_name': group['group_name'],
            });
          }
        }

        searchResults.value = allUsers;
      } else {
        searchResults.clear();
      }
    } catch (e) {
      searchResults.clear();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getVerifyBadge(int verifyType) {
    switch (verifyType) {
      case 0:
        return '个人认证';
      case 1:
        return '机构认证';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索用户',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 搜索结果列表
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Obx(
                    () => searchResults.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? '加载用户中...'
                                  : '未找到用户',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final user = searchResults[index];
                              final verifyBadge = _getVerifyBadge(
                                  user['official_verify_type'] ?? -1);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(user['face'] ?? ''),
                                  onBackgroundImageError:
                                      (exception, stackTrace) {},
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(user['name'] ?? ''),
                                    ),
                                    if (verifyBadge.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          verifyBadge,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text('粉丝: ${user['fans'] ?? 0}'),
                                onTap: () {
                                  widget.onMention(
                                    user['uid'] ?? '',
                                    user['name'] ?? '',
                                  );
                                  widget.onClose();
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
