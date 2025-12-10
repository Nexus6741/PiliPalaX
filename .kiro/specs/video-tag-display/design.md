# Design Document

## Overview

本设计文档描述了在视频播放页面简介区域显示视频标签(tag)功能的技术实现方案。该功能将在现有的视频详情页面中添加标签显示和交互能力,参考PiliPlus项目的实现,为用户提供更丰富的视频信息和导航能力。

核心功能包括:
- 从API获取视频标签数据
- 在UI中显示不同类型的标签(普通/话题/BGM)
- 支持标签点击跳转和长按复制
- 在UGC和PGC视频页面中统一支持

## Architecture

### 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │ VideoIntroPanel  │         │  IntroDetail     │         │
│  │  (UGC视频)       │         │  (详情弹窗)      │         │
│  └────────┬─────────┘         └────────┬─────────┘         │
│           │                            │                    │
│           └────────────┬───────────────┘                    │
│                        │                                    │
│                  ┌─────▼──────┐                            │
│                  │ TagsWidget │                            │
│                  │ (标签组件)  │                            │
│                  └─────┬──────┘                            │
└────────────────────────┼────────────────────────────────────┘
                         │
┌────────────────────────┼────────────────────────────────────┐
│                 Controller Layer                            │
│                  ┌─────▼──────────┐                        │
│                  │ VideoIntro     │                        │
│                  │ Controller     │                        │
│                  │ - videoTags    │                        │
│                  │ - queryVideoTags()                      │
│                  └─────┬──────────┘                        │
└────────────────────────┼────────────────────────────────────┘
                         │
┌────────────────────────┼────────────────────────────────────┐
│                   HTTP Layer                                │
│                  ┌─────▼──────────┐                        │
│                  │   VideoHttp    │                        │
│                  │ - videoTags()  │                        │
│                  └─────┬──────────┘                        │
└────────────────────────┼────────────────────────────────────┘
                         │
┌────────────────────────┼────────────────────────────────────┐
│                   Model Layer                               │
│                  ┌─────▼──────────┐                        │
│                  │   VideoTag     │                        │
│                  │ - tagId        │                        │
│                  │ - tagName      │                        │
│                  │ - tagType      │                        │
│                  │ - musicId      │                        │
│                  │ - jumpUrl      │                        │
│                  └────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

### 数据流

1. **初始化流程**:
   - VideoIntroPanel初始化 → VideoIntroController.queryVideoIntro()
   - queryVideoIntro() → queryVideoTags()
   - queryVideoTags() → VideoHttp.videoTags()
   - API响应 → 更新videoTags响应式变量
   - UI自动重新渲染显示标签

2. **用户交互流程**:
   - 用户点击标签 → 根据tagType判断跳转类型
   - 普通标签 → 跳转搜索页面
   - 话题标签 → 跳转动态话题页面
   - BGM标签 → 跳转音乐详情页面
   - 长按标签 → 复制标签文本到剪贴板

## Components and Interfaces

### 1. 数据模型 (lib/models/video/video_tag.dart)

```dart
class VideoTag {
  int? tagId;
  String? tagName;
  String? tagType;  // 'tag', 'topic', 'bgm'
  String? musicId;
  String? jumpUrl;

  VideoTag({
    this.tagId,
    this.tagName,
    this.tagType,
    this.musicId,
    this.jumpUrl,
  });

  factory VideoTag.fromJson(Map<String, dynamic> json) => VideoTag(
    tagId: json["tag_id"],
    tagName: json["tag_name"],
    tagType: json["tag_type"],
    musicId: json["music_id"],
    jumpUrl: json["jump_url"],
  );

  Map<String, dynamic> toJson() => {
    "tag_id": tagId,
    "tag_name": tagName,
    "tag_type": tagType,
    "music_id": musicId,
    "jump_url": jumpUrl,
  };
}
```

### 2. HTTP接口 (lib/http/video.dart)

```dart
class VideoHttp {
  // 获取视频标签
  static Future<Map<String, dynamic>> videoTags({
    required String bvid,
    required int cid,
  }) async {
    try {
      var res = await Request().get(
        Api.videoTags,
        data: {
          'bvid': bvid,
          'cid': cid,
        },
      );
      
      if (res.data['code'] == 0) {
        List<VideoTag> tags = [];
        if (res.data['data'] != null) {
          for (var item in res.data['data']) {
            tags.add(VideoTag.fromJson(item));
          }
        }
        return {'status': true, 'data': tags};
      } else {
        return {'status': false, 'data': [], 'msg': res.data['message']};
      }
    } catch (err) {
      return {'status': false, 'data': [], 'msg': err.toString()};
    }
  }
}
```

### 3. API常量 (lib/http/api.dart)

```dart
class Api {
  // 视频标签
  static const String videoTags = '/x/web-interface/view/detail/tag';
}
```

### 4. 控制器扩展 (lib/pages/video/introduction/detail/controller.dart)

```dart
class VideoIntroController extends GetxController {
  // 添加标签响应式变量
  Rx<List<VideoTag>?> videoTags = Rx<List<VideoTag>?>(null);

  // 在queryVideoIntro方法中调用
  void queryVideoIntro() async {
    // ... 现有代码 ...
    
    // 获取标签数据
    queryVideoTags();
  }

  // 获取视频标签
  Future<void> queryVideoTags() async {
    var result = await VideoHttp.videoTags(
      bvid: bvid,
      cid: lastPlayCid.value,
    );
    if (result['status']) {
      videoTags.value = result['data'];
    }
  }
}
```

### 5. UI组件 (lib/pages/video/introduction/widgets/tags_widget.dart)

```dart
class TagsWidget extends StatelessWidget {
  final List<VideoTag> tags;

  const TagsWidget({
    Key? key,
    required this.tags,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) => _buildTagItem(context, tag)).toList(),
      ),
    );
  }

  Widget _buildTagItem(BuildContext context, VideoTag tag) {
    String displayText = _getDisplayText(tag);
    
    return GestureDetector(
      onTap: () => _handleTagTap(tag),
      onLongPress: () => _handleTagLongPress(displayText),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          displayText,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  String _getDisplayText(VideoTag tag) {
    switch (tag.tagType) {
      case 'bgm':
        return tag.tagName!.replaceFirst('发现', '\u{1f3b5}BGM：');
      case 'topic':
        return '#${tag.tagName}';
      default:
        return tag.tagName ?? '';
    }
  }

  void _handleTagTap(VideoTag tag) {
    switch (tag.tagType) {
      case 'bgm':
        if (tag.musicId != null) {
          Get.toNamed('/musicDetail', parameters: {'musicId': tag.musicId!});
        }
        break;
      case 'topic':
        if (tag.tagId != null) {
          Get.toNamed('/dynTopic', parameters: {'id': tag.tagId!.toString()});
        }
        break;
      default:
        Get.toNamed('/searchResult', parameters: {'keyword': tag.tagName ?? ''});
        break;
    }
  }

  void _handleTagLongPress(String text) {
    Clipboard.setData(ClipboardData(text: text));
    SmartDialog.showToast('已复制: $text');
  }
}
```

### 6. 视频简介面板集成 (lib/pages/video/introduction/detail/view.dart)

在IntroDetail widget的children列表中添加标签显示:

```dart
// 在视频描述下方添加
Obx(() {
  final tags = videoIntroController.videoTags.value;
  if (tags == null || tags.isEmpty) {
    return const SizedBox.shrink();
  }
  return TagsWidget(tags: tags);
}),
```

## Data Models

### VideoTag模型

| 字段 | 类型 | 说明 | 必需 |
|------|------|------|------|
| tagId | int? | 标签ID | 否 |
| tagName | String? | 标签名称 | 否 |
| tagType | String? | 标签类型: 'tag'(普通), 'topic'(话题), 'bgm'(音乐) | 否 |
| musicId | String? | 音乐ID(仅BGM标签) | 否 |
| jumpUrl | String? | 跳转链接 | 否 |

### API响应格式

```json
{
  "code": 0,
  "message": "0",
  "data": [
    {
      "tag_id": 123456,
      "tag_name": "编程",
      "tag_type": "tag",
      "music_id": null,
      "jump_url": ""
    },
    {
      "tag_id": 789012,
      "tag_name": "技术分享",
      "tag_type": "topic",
      "music_id": null,
      "jump_url": ""
    },
    {
      "tag_id": 345678,
      "tag_name": "发现好音乐",
      "tag_type": "bgm",
      "music_id": "MA123456",
      "jump_url": ""
    }
  ]
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: 标签数据获取完整性
*For any* 有效的bvid和cid组合, 调用videoTags API应当返回包含status字段的响应对象
**Validates: Requirements 1.1**

### Property 2: 标签列表非空时显示
*For any* 非空的标签列表, UI应当渲染Wrap组件并显示所有标签
**Validates: Requirements 1.2**

### Property 3: 空标签列表隐藏
*For any* 空或null的标签列表, UI应当渲染SizedBox.shrink()而不显示任何内容
**Validates: Requirements 1.3**

### Property 4: 标签间距一致性
*For any* 包含多个标签的Wrap组件, 所有标签之间的水平和垂直间距应当都为8像素
**Validates: Requirements 1.5**

### Property 5: 标签类型显示转换
*For any* 标签对象, 显示文本应当根据tagType正确转换: 普通标签保持原样, 话题标签添加"#"前缀, BGM标签替换"发现"为"🎵BGM："
**Validates: Requirements 2.1, 2.2, 2.3**

### Property 6: 标签点击路由正确性
*For any* 标签点击事件, 系统应当根据tagType跳转到正确的路由: 普通标签→/searchResult, 话题标签→/dynTopic, BGM标签→/musicDetail
**Validates: Requirements 3.1, 3.2, 3.3**

### Property 7: 标签长按复制
*For any* 标签长按事件, 系统应当将标签显示文本复制到剪贴板
**Validates: Requirements 3.4**

### Property 8: JSON解析正确性
*For any* 有效的JSON对象包含tag_id、tag_name、tag_type字段, VideoTag.fromJson应当成功创建对象并正确映射所有字段
**Validates: Requirements 4.2**

### Property 9: API请求参数完整性
*For any* videoTags API调用, 请求应当包含bvid和cid两个查询参数
**Validates: Requirements 5.2**

### Property 10: 响应式更新触发
*For any* videoTags响应式变量的值变化, 所有Obx包裹的UI组件应当重新渲染
**Validates: Requirements 6.5**

### Property 11: 异步加载不阻塞
*For any* 视频详情页面加载过程, 标签数据的获取应当不阻塞其他内容的显示
**Validates: Requirements 8.1, 8.5**

## Error Handling

### 1. API错误处理

- **网络错误**: 捕获异常并返回`{'status': false, 'msg': error}`
- **API返回错误码**: 检查`code != 0`并返回错误信息
- **数据为null**: 返回空列表而不是null

### 2. UI错误处理

- **标签数据为null**: 显示SizedBox.shrink()
- **标签列表为空**: 显示SizedBox.shrink()
- **标签字段缺失**: 使用空字符串作为默认值

### 3. 路由错误处理

- **musicId为null**: 不执行跳转
- **tagId为null**: 不执行跳转
- **tagName为null**: 使用空字符串作为搜索关键词

### 4. 静默失败策略

标签功能采用静默失败策略:
- API请求失败不显示错误提示
- 解析失败不影响页面其他功能
- 确保用户体验不受标签功能影响

## Testing Strategy

### Unit Tests

1. **VideoTag模型测试**
   - 测试fromJson正确解析所有字段
   - 测试fromJson处理缺失字段
   - 测试toJson正确序列化

2. **VideoHttp.videoTags测试**
   - 测试成功响应解析
   - 测试错误响应处理
   - 测试网络异常处理

3. **TagsWidget测试**
   - 测试空列表渲染
   - 测试非空列表渲染
   - 测试标签文本转换
   - 测试点击事件触发
   - 测试长按事件触发

### Property-Based Tests

使用Dart的test包和faker包进行属性测试:

1. **配置**: 每个属性测试运行100次迭代
2. **标记格式**: `// Feature: video-tag-display, Property X: [property description]`
3. **测试库**: 使用Dart的test包

#### 属性测试用例

**Property Test 1: API响应结构验证**
```dart
// Feature: video-tag-display, Property 1: 标签数据获取完整性
test('videoTags API always returns response with status field', () async {
  for (int i = 0; i < 100; i++) {
    final bvid = generateRandomBvid();
    final cid = generateRandomCid();
    final result = await VideoHttp.videoTags(bvid: bvid, cid: cid);
    expect(result.containsKey('status'), true);
  }
});
```

**Property Test 2: 非空列表显示验证**
```dart
// Feature: video-tag-display, Property 2: 标签列表非空时显示
testWidgets('non-empty tag list renders Wrap widget', (tester) async {
  for (int i = 0; i < 100; i++) {
    final tags = generateRandomTags(minCount: 1, maxCount: 10);
    await tester.pumpWidget(MaterialApp(home: TagsWidget(tags: tags)));
    expect(find.byType(Wrap), findsOneWidget);
  }
});
```

**Property Test 3: 空列表隐藏验证**
```dart
// Feature: video-tag-display, Property 3: 空标签列表隐藏
testWidgets('empty or null tag list renders nothing', (tester) async {
  for (int i = 0; i < 100; i++) {
    final tags = i % 2 == 0 ? <VideoTag>[] : null;
    await tester.pumpWidget(MaterialApp(home: TagsWidget(tags: tags ?? [])));
    expect(find.byType(Wrap), findsNothing);
  }
});
```

**Property Test 4: 标签类型转换验证**
```dart
// Feature: video-tag-display, Property 5: 标签类型显示转换
test('tag display text transforms correctly based on type', () {
  for (int i = 0; i < 100; i++) {
    final tagType = ['tag', 'topic', 'bgm'][i % 3];
    final tag = VideoTag(
      tagName: 'test${i}',
      tagType: tagType,
    );
    final displayText = getDisplayText(tag);
    
    switch (tagType) {
      case 'topic':
        expect(displayText.startsWith('#'), true);
        break;
      case 'bgm':
        expect(displayText.contains('🎵BGM：'), true);
        break;
      default:
        expect(displayText, tag.tagName);
    }
  }
});
```

**Property Test 5: JSON解析往返一致性**
```dart
// Feature: video-tag-display, Property 8: JSON解析正确性
test('VideoTag fromJson/toJson round trip preserves data', () {
  for (int i = 0; i < 100; i++) {
    final original = generateRandomVideoTag();
    final json = original.toJson();
    final parsed = VideoTag.fromJson(json);
    
    expect(parsed.tagId, original.tagId);
    expect(parsed.tagName, original.tagName);
    expect(parsed.tagType, original.tagType);
    expect(parsed.musicId, original.musicId);
    expect(parsed.jumpUrl, original.jumpUrl);
  }
});
```

### Integration Tests

1. **完整流程测试**
   - 打开视频详情页 → 验证标签显示
   - 点击普通标签 → 验证跳转到搜索页
   - 点击话题标签 → 验证跳转到话题页
   - 点击BGM标签 → 验证跳转到音乐页
   - 长按标签 → 验证复制成功

2. **边界情况测试**
   - 视频无标签时的显示
   - 标签数量很多时的布局
   - 标签名称很长时的显示

### 测试工具和依赖

```yaml
dev_dependencies:
  test: ^1.24.0
  faker: ^2.1.0
  mockito: ^5.4.0
```

## Implementation Notes

### 1. 代码复用

- 参考PiliPlus项目的SearchText组件实现
- 如果项目中已有类似的可点击标签组件,优先复用
- 标签样式应与项目整体设计保持一致

### 2. 性能考虑

- 标签数据异步加载,不阻塞主界面
- 使用Obx进行局部刷新,避免整页重建
- 标签列表使用Wrap自动布局,无需手动计算

### 3. 可访问性

- 为标签添加语义标签(semanticLabel)
- 确保标签可以通过键盘导航
- 提供足够的点击区域(最小44x44)

### 4. 国际化

- 标签文本直接使用API返回的内容
- Toast提示信息需要支持多语言
- "已复制"等提示文本应从语言包获取

### 5. 兼容性

- 确保在不同屏幕尺寸下正常显示
- 支持深色模式和浅色模式
- 兼容Android、iOS、Web平台

### 6. 扩展性

- VideoTag模型设计为可扩展,预留jumpUrl字段
- 标签点击处理使用switch语句,易于添加新类型
- UI组件独立封装,便于在其他页面复用
