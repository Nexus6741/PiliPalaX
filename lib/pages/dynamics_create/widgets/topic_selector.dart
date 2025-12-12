import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../../http/dynamics.dart';
import '../../../models/dynamics/topic_item.dart';

class TopicSelectorPage extends StatefulWidget {
  const TopicSelectorPage({super.key});

  @override
  State<TopicSelectorPage> createState() => _TopicSelectorPageState();
}

class _TopicSelectorPageState extends State<TopicSelectorPage> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<TopicItem> topics = <TopicItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    isLoading.value = true;
    try {
      final result = await DynamicsHttp.getTopicRecommend();
      if (result['status'] == true) {
        topics.value = result['data'] ?? [];
      } else {
        SmartDialog.showToast(result['msg'] ?? '加载失败');
      }
    } catch (e) {
      SmartDialog.showToast('加载失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _searchTopics(String keywords) async {
    if (keywords.trim().isEmpty) {
      _loadTopics();
      return;
    }

    isSearching.value = true;
    try {
      final result = await DynamicsHttp.searchTopics(keywords: keywords.trim());
      if (result['status'] == true) {
        topics.value = result['data'] ?? [];
      } else {
        SmartDialog.showToast(result['msg'] ?? '搜索失败');
      }
    } catch (e) {
      SmartDialog.showToast('搜索失败: $e');
    } finally {
      isSearching.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择话题'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索话题',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                _searchTopics(value);
              },
              onSubmitted: (value) {
                _searchTopics(value);
              },
            ),
          ),
          // 话题列表
          Expanded(
            child: Obx(() {
              if (isLoading.value || isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (topics.isEmpty) {
                return const Center(
                  child: Text('暂无话题'),
                );
              }

              return ListView.builder(
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return ListTile(
                    leading: topic.cover != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(topic.cover!),
                          )
                        : CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            child: Icon(
                              Icons.tag,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                    title: Text(topic.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topic.description != null &&
                            topic.description!.isNotEmpty)
                          Text(
                            topic.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (topic.statDesc != null)
                          Text(
                            topic.statDesc!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                      ],
                    ),
                    isThreeLine:
                        topic.description != null && topic.statDesc != null,
                    onTap: () {
                      Get.back(result: topic);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
