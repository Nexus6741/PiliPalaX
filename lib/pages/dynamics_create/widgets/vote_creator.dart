import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../../models/dynamics/vote_model.dart';

class VoteCreatorPage extends StatefulWidget {
  final VoteInfo? existingVote;

  const VoteCreatorPage({super.key, this.existingVote});

  @override
  State<VoteCreatorPage> createState() => _VoteCreatorPageState();
}

class _VoteCreatorPageState extends State<VoteCreatorPage> {
  final TextEditingController _titleController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  final RxBool multiChoice = false.obs;
  final RxInt duration = 7.obs; // 默认7天

  @override
  void initState() {
    super.initState();

    if (widget.existingVote != null) {
      _titleController.text = widget.existingVote!.title;
      multiChoice.value = widget.existingVote!.multiChoice;

      for (final option in widget.existingVote!.options) {
        final controller = TextEditingController(text: option.text);
        _optionControllers.add(controller);
      }
    } else {
      // 默认添加两个选项
      _addOption();
      _addOption();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      _optionControllers.add(TextEditingController());
      setState(() {});
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      setState(() {});
    }
  }

  void _createVote() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      SmartDialog.showToast('请输入投票标题');
      return;
    }

    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .map((text) => VoteOption(text: text))
        .toList();

    if (options.length < 2) {
      SmartDialog.showToast('至少需要两个选项');
      return;
    }

    // 计算持续时间（秒）
    final durationInSeconds = duration.value * 24 * 60 * 60;
    final endTime = DateTime.now().add(Duration(seconds: durationInSeconds));

    final vote = VoteInfo(
      voteId: widget.existingVote?.voteId,
      title: title,
      options: options,
      endTime: endTime.millisecondsSinceEpoch ~/ 1000,
      duration: durationInSeconds,
      multiChoice: multiChoice.value,
      choiceCount: multiChoice.value ? options.length : 1,
    );

    Get.back(result: vote);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建投票'),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          TextButton(
            onPressed: _createVote,
            child: const Text('完成'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 投票标题
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '投票标题',
                hintText: '输入投票标题',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),

            // 投票选项
            const Text(
              '投票选项',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ..._optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: '选项 ${index + 1}',
                          hintText: '输入选项内容',
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 20,
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeOption(index),
                      ),
                  ],
                ),
              );
            }).toList(),

            // 添加选项按钮
            if (_optionControllers.length < 10)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('添加选项'),
              ),

            const SizedBox(height: 16),

            // 多选设置
            Obx(() => SwitchListTile(
                  title: const Text('允许多选'),
                  subtitle: const Text('用户可以选择多个选项'),
                  value: multiChoice.value,
                  onChanged: (value) => multiChoice.value = value,
                )),

            const SizedBox(height: 16),

            // 投票时长
            const Text(
              '投票时长',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Obx(() => Column(
                  children: [
                    RadioListTile<int>(
                      title: const Text('1天'),
                      value: 1,
                      groupValue: duration.value,
                      onChanged: (value) => duration.value = value!,
                    ),
                    RadioListTile<int>(
                      title: const Text('3天'),
                      value: 3,
                      groupValue: duration.value,
                      onChanged: (value) => duration.value = value!,
                    ),
                    RadioListTile<int>(
                      title: const Text('7天'),
                      value: 7,
                      groupValue: duration.value,
                      onChanged: (value) => duration.value = value!,
                    ),
                    RadioListTile<int>(
                      title: const Text('30天'),
                      value: 30,
                      groupValue: duration.value,
                      onChanged: (value) => duration.value = value!,
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
