import 'dart:math';

import 'package:flutter/material.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/models/live_new/live_emote/datum.dart';
import 'package:PiliPalaX/models/live_new/live_emote/emoticon.dart';

typedef LiveEmoteInsertCallback = void Function(Emoticon emote);

class LiveEmotePanel extends StatefulWidget {
  final int roomId;
  final LiveEmoteInsertCallback onInsert;
  final LiveEmoteInsertCallback onSendDirectly;

  const LiveEmotePanel({
    super.key,
    required this.roomId,
    required this.onInsert,
    required this.onSendDirectly,
  });

  @override
  State<LiveEmotePanel> createState() => _LiveEmotePanelState();
}

class _LiveEmotePanelState extends State<LiveEmotePanel>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Future<List<LiveEmoteDatum>>? _future;
  TabController? _tabController;
  List<LiveEmoteDatum> _packages = const [];

  @override
  void initState() {
    super.initState();
    _future = _loadEmotes();
  }

  Future<List<LiveEmoteDatum>> _loadEmotes() async {
    final res = await LiveHttp.liveEmoteList(roomId: widget.roomId);
    if (res['status'] == true) {
      final list =
          (res['data'] as List<dynamic>? ?? const []).cast<LiveEmoteDatum>();
      return list;
    }
    throw Exception(res['msg'] ?? '获取直播表情失败');
  }

  void _initTabController(int length) {
    if (length <= 0) return;
    if (_tabController == null || _tabController!.length != length) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<LiveEmoteDatum>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error?.toString(),
            onRetry: () {
              setState(() {
                _future = _loadEmotes();
              });
            },
          );
        }
        final list = snapshot.data ?? const [];
        if (list.isEmpty) {
          return _ErrorView(
            message: '暂无表情',
            onRetry: () {
              setState(() {
                _future = _loadEmotes();
              });
            },
          );
        }
        _packages = list;
        _initTabController(list.length);
        if (_tabController == null) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: list.map(_buildPackageGrid).toList(),
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: list
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: NetworkImgLayer(
                        width: 32,
                        height: 32,
                        type: 'emote',
                        src: item.currentCover,
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        );
      },
    );
  }

  Widget _buildPackageGrid(LiveEmoteDatum pkg) {
    final emotes = pkg.emoticons ?? const <Emoticon>[];
    if (emotes.isEmpty) {
      return const Center(child: Text('暂无表情'));
    }
    final first = emotes.first;
    final widthFactor = _calcFactor(first.width);
    final heightFactor = _calcFactor(first.height);
    final maxExtent = widthFactor * 48;
    final mainExtent = heightFactor * 48;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        mainAxisExtent: mainExtent,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: emotes.length,
      itemBuilder: (context, index) {
        final emote = emotes[index];
        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              final type = pkg.pkgType;
              if (type == null || type == 3) {
                widget.onInsert(emote);
              } else if (emote.emoticonUnique != null) {
                widget.onSendDirectly(emote);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: NetworkImgLayer(
                src: emote.url ?? '',
                width: max(32.0, (emote.width ?? 32).toDouble()),
                height: max(32.0, (emote.height ?? 32).toDouble()),
                type: 'emote',
                semanticsLabel: emote.emoji,
              ),
            ),
          ),
        );
      },
    );
  }

  double _calcFactor(int? size) {
    if (size == null) return 1;
    return max(1.0, size / 80.0);
  }

  @override
  bool get wantKeepAlive => true;
}

class _ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(message ?? '加载失败'),
      ),
    );
  }
}
