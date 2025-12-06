import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class LiveDmBlockPage extends StatefulWidget {
  const LiveDmBlockPage({super.key});

  @override
  State<LiveDmBlockPage> createState() => _LiveDmBlockPageState();
}

class _LiveDmBlockPageState extends State<LiveDmBlockPage> {
  late final LiveDmBlockController _controller;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(LiveDmBlockController());
  }

  @override
  void dispose() {
    _inputController.dispose();
    Get.delete<LiveDmBlockController>();
    super.dispose();
  }

  void _showAddDialog(bool isKeyword) {
    _inputController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKeyword ? '添加屏蔽关键词' : '添加屏蔽用户'),
        content: TextField(
          controller: _inputController,
          decoration: InputDecoration(
            hintText: isKeyword ? '输入关键词' : '输入用户UID',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = _inputController.text.trim();
              if (value.isNotEmpty) {
                if (isKeyword) {
                  _controller.addKeyword(value);
                } else {
                  _controller.addShieldUser(value);
                }
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('弹幕屏蔽'),
        bottom: TabBar(
          controller: _controller.tabController,
          tabs: const [
            Tab(text: '关键词'),
            Tab(text: '用户'),
          ],
        ),
      ),
      body: Obx(
        () => _controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _controller.tabController,
                children: [
                  _buildKeywordList(theme),
                  _buildUserList(theme),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(_controller.tabController.index == 0);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildKeywordList(ThemeData theme) {
    return Obx(
      () => _controller.keywordList.isEmpty
          ? Center(
              child: Text(
                '暂无屏蔽关键词',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _controller.keywordList.length,
              itemBuilder: (context, index) {
                final keyword = _controller.keywordList[index];
                return ListTile(
                  title: Text(keyword),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _controller.removeKeyword(index, keyword),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildUserList(ThemeData theme) {
    return Obx(
      () => _controller.shieldUserList.isEmpty
          ? Center(
              child: Text(
                '暂无屏蔽用户',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _controller.shieldUserList.length,
              itemBuilder: (context, index) {
                final user = _controller.shieldUserList[index];
                return ListTile(
                  title: Text(user['uname'] ?? 'UID: ${user['uid']}'),
                  subtitle: Text('UID: ${user['uid']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _controller.removeShieldUser(index, user['uid']),
                  ),
                );
              },
            ),
    );
  }
}
