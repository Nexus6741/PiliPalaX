import 'dart:math';

import 'package:PiliPalaX/common/widgets/pair.dart';
import 'package:PiliPalaX/http/constants.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/sponsor_block.dart';
import 'package:PiliPalaX/models/common/sponsor_block/segment_type.dart';
import 'package:PiliPalaX/models/common/sponsor_block/skip_type.dart';
import 'package:PiliPalaX/pages/setting/widgets/slide_color_picker.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class SponsorBlockPage extends StatefulWidget {
  const SponsorBlockPage({super.key});

  @override
  State<SponsorBlockPage> createState() => _SponsorBlockPageState();
}

class _SponsorBlockPageState extends State<SponsorBlockPage> {
  final _url = 'https://github.com/hanydd/BilibiliSponsorBlock';
  final _textController = TextEditingController();
  late double _blockLimit;
  late List<Pair<SegmentType, SkipType>> _blockSettings;
  late List<Color> _blockColor;
  late String _userId;
  late bool _blockToast;
  late String _blockServer;
  late bool _blockTrack;
  final _serverStatus = Rxn<bool>();
  final _userInfo = Rx<LoadingState>(LoadingState.loading());

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkServerStatus();
    _getUserInfo();
  }

  void _loadSettings() {
    _blockLimit = GStorage.setting.get('blockLimit', defaultValue: 0.0);

    // 加载跳过设置
    List<dynamic>? savedSettings = GStorage.setting.get('blockSettings');
    if (savedSettings != null &&
        savedSettings.length == SegmentType.values.length) {
      _blockSettings = List.generate(
        SegmentType.values.length,
        (i) => Pair(
          first: SegmentType.values[i],
          second: SkipType.values[savedSettings[i] as int],
        ),
      );
    } else {
      _blockSettings = SegmentType.values
          .map((e) => Pair(first: e, second: SkipType.disable))
          .toList();
    }

    // 加载颜色设置
    List<dynamic>? savedColors = GStorage.setting.get('blockColor');
    if (savedColors != null &&
        savedColors.length == SegmentType.values.length) {
      _blockColor = savedColors
          .map((hex) => Color(int.parse('FF${hex as String}', radix: 16)))
          .toList();
    } else {
      _blockColor = SegmentType.values.map((e) => e.color).toList();
    }

    _userId = GStorage.setting.get('blockUserID',
        defaultValue: const Uuid().v4().replaceAll('-', ''));
    _blockToast = GStorage.setting.get('blockToast', defaultValue: true);
    _blockServer = GStorage.setting
        .get('blockServer', defaultValue: HttpString.sponsorBlockBaseUrl);
    _blockTrack = GStorage.setting.get('blockTrack', defaultValue: false);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkServerStatus() async {
    final result = await SponsorBlock.uptimeStatus();
    _serverStatus.value = result is Success;
  }

  Future<void> _getUserInfo() async {
    final result = await SponsorBlock.userInfo(const [
      'viewCount',
      'minutesSaved',
      'segmentCount',
    ], userId: _userId);
    _userInfo.value = result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const titleStyle = TextStyle(fontSize: 15);
    final subTitleStyle = TextStyle(
      fontSize: 13,
      color: theme.colorScheme.outline,
    );

    final divider = Divider(
      height: 1,
      color: theme.colorScheme.outline.withOpacity(0.1),
    );

    final sliverDivider = SliverToBoxAdapter(child: divider);

    final dividerL = SliverToBoxAdapter(
      child: Divider(
        thickness: 16,
        color: theme.colorScheme.outline.withOpacity(0.1),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('空降助手')),
      body: CustomScrollView(
        slivers: [
          dividerL,
          SliverToBoxAdapter(
            child: SwitchListTile(
              title: const Text('启用 SponsorBlock', style: titleStyle),
              subtitle: Text('自动跳过视频中的赞助商片段', style: subTitleStyle),
              value: GStorage.setting
                  .get(SettingBoxKey.enableSponsorBlock, defaultValue: false),
              onChanged: (value) {
                setState(() {
                  GStorage.setting.put(SettingBoxKey.enableSponsorBlock, value);
                });
              },
            ),
          ),
          sliverDivider,
          SliverToBoxAdapter(child: _serverStatusItem(theme, titleStyle)),
          dividerL,
          SliverToBoxAdapter(
            child: _blockLimitItem(theme, titleStyle, subTitleStyle),
          ),
          sliverDivider,
          SliverToBoxAdapter(child: _blockToastItem(titleStyle)),
          sliverDivider,
          SliverToBoxAdapter(child: _blockTrackItem(titleStyle, subTitleStyle)),
          sliverDivider,
          SliverToBoxAdapter(
            child: _blockUserInfo(theme, titleStyle, subTitleStyle),
          ),
          dividerL,
          SliverList.separated(
            itemCount: _blockSettings.length,
            itemBuilder: (context, index) =>
                _buildItem(theme, index, _blockSettings[index]),
            separatorBuilder: (context, index) => divider,
          ),
          dividerL,
          SliverToBoxAdapter(
            child: _userIdItem(theme, titleStyle, subTitleStyle),
          ),
          sliverDivider,
          SliverToBoxAdapter(
            child: _blockServerItem(theme, titleStyle, subTitleStyle),
          ),
          dividerL,
          SliverToBoxAdapter(child: _aboutItem(titleStyle, subTitleStyle)),
          dividerL,
          SliverToBoxAdapter(
            child: SizedBox(
              height: 55 + MediaQuery.of(context).padding.bottom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockLimitItem(
    ThemeData theme,
    TextStyle titleStyle,
    TextStyle subTitleStyle,
  ) =>
      Builder(
        builder: (context) {
          return ListTile(
            dense: true,
            onTap: () {
              _textController.text = _blockLimit.toString();
              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: Text('最短片段时长', style: titleStyle),
                    content: TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      controller: _textController,
                      autofocus: true,
                      decoration: const InputDecoration(suffixText: 's'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\.]+')),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: Get.back,
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          _blockLimit = max(
                            0.0,
                            double.tryParse(_textController.text) ?? 0.0,
                          );
                          GStorage.setting.put('blockLimit', _blockLimit);
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  );
                },
              );
            },
            title: Text('最短片段时长', style: titleStyle),
            subtitle: Text(
              '忽略短于此时长的片段',
              style: subTitleStyle,
            ),
            trailing: Text(
              '${_blockLimit}s',
              style: const TextStyle(fontSize: 13),
            ),
          );
        },
      );

  Widget _aboutItem(TextStyle titleStyle, TextStyle subTitleStyle) => ListTile(
        dense: true,
        title: Text('关于空降助手', style: titleStyle),
        subtitle: Text(_url, style: subTitleStyle),
        onTap: () async {
          final uri = Uri.parse(_url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      );

  Widget _userIdItem(
    ThemeData theme,
    TextStyle titleStyle,
    TextStyle subTitleStyle,
  ) =>
      Builder(
        builder: (context) {
          return ListTile(
            dense: true,
            title: Text('用户ID', style: titleStyle),
            subtitle: Text(_userId, style: subTitleStyle),
            onTap: () {
              final key = GlobalKey<FormFieldState<String>>();
              _textController.text = _userId;
              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: Text('用户ID', style: titleStyle),
                    content: TextFormField(
                      key: key,
                      minLines: 1,
                      maxLines: 4,
                      autofocus: true,
                      controller: _textController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\d]+')),
                      ],
                      decoration: const InputDecoration(errorMaxLines: 2),
                      validator: (value) {
                        if ((value?.length ?? -1) < 30) {
                          return '用户ID要求至少为30个字符长度的纯字符串';
                        }
                        return null;
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Get.back();
                          _userId = const Uuid().v4().replaceAll('-', '');
                          GStorage.setting.put('blockUserID', _userId);
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('随机'),
                      ),
                      TextButton(
                        onPressed: Get.back,
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (key.currentState?.validate() == true) {
                            Get.back();
                            _userId = _textController.text;
                            GStorage.setting.put('blockUserID', _userId);
                            (context as Element).markNeedsBuild();
                          }
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );

  Widget _blockToastItem(TextStyle titleStyle) => Builder(
        builder: (context) {
          void update() {
            _blockToast = !_blockToast;
            GStorage.setting.put('blockToast', _blockToast);
            (context as Element).markNeedsBuild();
          }

          return ListTile(
            dense: true,
            onTap: update,
            title: Text(
              '显示跳过Toast',
              style: titleStyle,
            ),
            trailing: Transform.scale(
              alignment: Alignment.centerRight,
              scale: 0.8,
              child: Switch(
                value: _blockToast,
                onChanged: (val) => update(),
              ),
            ),
          );
        },
      );

  Widget _blockTrackItem(
    TextStyle titleStyle,
    TextStyle subTitleStyle,
  ) =>
      Builder(
        builder: (context) {
          void update() {
            _blockTrack = !_blockTrack;
            GStorage.setting.put('blockTrack', _blockTrack);
            (context as Element).markNeedsBuild();
          }

          return ListTile(
            dense: true,
            onTap: update,
            title: Text(
              '跳过次数统计跟踪',
              style: titleStyle,
            ),
            subtitle: Text(
              '此功能追踪您跳过了哪些片段，让用户知道他们提交的片段帮助了多少人。同时点赞会作为依据，确保垃圾信息不会污染数据库。在您每次跳过片段时，我们都会向服务器发送一条消息。希望大家开启此项设置，以便得到更准确的统计数据。:)',
              style: subTitleStyle,
            ),
            trailing: Transform.scale(
              alignment: Alignment.centerRight,
              scale: 0.8,
              child: Switch(
                value: _blockTrack,
                onChanged: (val) => update(),
              ),
            ),
          );
        },
      );

  Widget _blockUserInfo(
    ThemeData theme,
    TextStyle titleStyle,
    TextStyle subTitleStyle,
  ) =>
      Obx(
        () {
          final userInfo = _userInfo.value;
          Widget subtitle;

          if (userInfo is Loading) {
            subtitle = const SizedBox.shrink();
          } else if (userInfo is Success) {
            subtitle = Text(
              userInfo.response.toString(),
              style: subTitleStyle,
            );
          } else if (userInfo is Error) {
            subtitle = Text(
              userInfo.errMsg ?? '服务器错误',
              style: subTitleStyle.copyWith(color: theme.colorScheme.error),
            );
          } else {
            subtitle = const SizedBox.shrink();
          }

          return ListTile(
            dense: true,
            onTap: () {
              _userInfo.value = const Loading();
              _getUserInfo();
            },
            title: Text(
              '您的信息',
              style: titleStyle,
            ),
            subtitle: subtitle,
          );
        },
      );

  Widget _blockServerItem(
    ThemeData theme,
    TextStyle titleStyle,
    TextStyle subTitleStyle,
  ) =>
      Builder(
        builder: (context) {
          return ListTile(
            dense: true,
            onTap: () {
              _textController.text = _blockServer;
              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: Text('服务器地址', style: titleStyle),
                    content: TextFormField(
                      keyboardType: TextInputType.url,
                      controller: _textController,
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Get.back();
                          _blockServer = HttpString.sponsorBlockBaseUrl;
                          GStorage.setting.put('blockServer', _blockServer);
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('重置'),
                      ),
                      TextButton(
                        onPressed: Get.back,
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          _blockServer = _textController.text;
                          GStorage.setting.put('blockServer', _blockServer);
                          _checkServerStatus();
                          _getUserInfo();
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  );
                },
              );
            },
            title: Text(
              '服务器地址',
              style: titleStyle,
            ),
            subtitle: Text(
              _blockServer,
              style: subTitleStyle,
            ),
          );
        },
      );

  Widget _serverStatusItem(ThemeData theme, TextStyle titleStyle) => Obx(
        () {
          String status;
          Color? color;
          final serverStatus = _serverStatus.value;
          if (serverStatus == null) {
            status = '——';
            color = null;
          } else if (serverStatus) {
            status = '正常';
            color = theme.colorScheme.primary;
          } else {
            status = '错误';
            color = theme.colorScheme.error;
          }
          return ListTile(
            dense: true,
            onTap: () {
              _serverStatus.value = null;
              _checkServerStatus();
            },
            title: Text('服务器状态', style: titleStyle),
            trailing: Text(
              status,
              style: TextStyle(fontSize: 13, color: color),
            ),
          );
        },
      );

  void onSelectColor(
    BuildContext context,
    int index,
    Color color,
    Pair<SegmentType, SkipType> item,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        clipBehavior: Clip.hardEdge,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Color Picker ',
                style: TextStyle(fontSize: 15),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                style: const TextStyle(fontSize: 13, height: 1),
              ),
              TextSpan(
                text: ' ${item.first.title}',
                style: const TextStyle(fontSize: 13, height: 1),
              ),
            ],
          ),
        ),
        content: SlideColorPicker(
          color: color,
          showResetBtn: true,
          callback: (Color? color) {
            _blockColor[index] = color ?? item.first.color;
            GStorage.setting.put(
              'blockColor',
              _blockColor
                  .map((item) => item.value.toRadixString(16).substring(2))
                  .toList(),
            );
            (context as Element).markNeedsBuild();
          },
        ),
      ),
    );
  }

  Widget _buildItem(
    ThemeData theme,
    int index,
    Pair<SegmentType, SkipType> item,
  ) {
    return Builder(
      builder: (context) {
        Color color = _blockColor[index];
        final isDisable = item.second == SkipType.disable;
        return ListTile(
          dense: true,
          enabled: item.second != SkipType.disable,
          onTap: () => onSelectColor(context, index, color, item),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14, height: 1),
                      ),
                      TextSpan(
                        text: ' ${item.first.title}',
                        style: const TextStyle(fontSize: 14, height: 1),
                      ),
                    ],
                  ),
                ),
              ),
              Builder(
                builder: (btnContext) {
                  return PopupMenuButton<SkipType>(
                    initialValue: item.second,
                    onSelected: (e) {
                      final updateItem = isDisable || e == SkipType.disable;
                      item.second = e;
                      GStorage.setting.put(
                        'blockSettings',
                        _blockSettings.map((e) => e.second.index).toList(),
                      );
                      if (updateItem) {
                        (context as Element).markNeedsBuild();
                      } else {
                        (btnContext as Element).markNeedsBuild();
                      }
                    },
                    itemBuilder: (context) => SkipType.values
                        .map(
                          (item) => PopupMenuItem<SkipType>(
                            value: item,
                            child: Text(item.title),
                          ),
                        )
                        .toList(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.second.title,
                            style: TextStyle(
                              height: 1,
                              fontSize: 14,
                              color: isDisable
                                  ? theme.colorScheme.outline.withOpacity(0.7)
                                  : theme.colorScheme.secondary,
                            ),
                            strutStyle: const StrutStyle(height: 1, leading: 0),
                          ),
                          Icon(
                            Icons.unfold_more,
                            size: 14,
                            color: isDisable
                                ? theme.colorScheme.outline.withOpacity(0.7)
                                : theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          subtitle: Text(
            item.first.description,
            style: TextStyle(
              fontSize: 12,
              color: isDisable ? null : theme.colorScheme.outline,
            ),
          ),
        );
      },
    );
  }
}
