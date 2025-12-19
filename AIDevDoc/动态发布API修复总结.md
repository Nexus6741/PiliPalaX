# 动态发布API修复总结

## 问题描述

用户反馈话题选择功能正常，但发布的动态没有包含选择的话题。经过分析bilibili-API-collect文档，发现我们的API实现与官方文档不符。

## 修复内容

### 1. 动态创建API修正

#### 问题分析
- 原实现使用了错误的请求格式
- 话题参数结构不正确
- 内容结构不符合API规范

#### 修复方案
根据 `/x/dynamic/feed/create/dyn` API文档，重新实现了 `createDynamic` 方法：

**修正前的问题：**
```dart
// 错误的参数格式
queryParameters: {
  'platform': 'web',
  'csrf': await Request.getCsrf(),
}
```

**修正后的格式：**
```dart
// 正确的参数格式
queryParameters: {
  'csrf': await Request.getCsrf(),
}
```

**内容结构优化：**
```dart
// 正确的内容结构
List<Map<String, dynamic>> contents = [];

// 添加标题（如果有）
if (title?.isNotEmpty == true) {
  contents.add({
    'raw_text': title!,
    'type': 1,
    'biz_id': '',
  });
}

// 添加正文内容
if (content.isNotEmpty) {
  contents.add({
    'raw_text': content,
    'type': 1,
    'biz_id': '',
  });
}
```

**话题参数修正：**
```dart
// 正确的话题结构
if (topic != null) {
  dynReq['topic'] = {
    'id': topic.id,
    'name': topic.name,
    'from_source': 'dyn.web.list',
    'from_topic_id': 0,
  };
}
```

### 2. 投票创建API修正

#### 问题分析
- 使用了错误的API端点
- 参数格式不符合官方规范
- 持续时间计算错误

#### 修复方案
根据 `https://api.vc.bilibili.com/vote_svr/v1/vote_svr/create_vote` API文档：

**API端点修正：**
```dart
// 修正前
static const String createVote = '/x/vote/web/add';

// 修正后  
static const String createVote = 'https://api.vc.bilibili.com/vote_svr/v1/vote_svr/create_vote';
```

**参数格式修正：**
```dart
// 正确的表单数据格式
Map<String, dynamic> formData = {
  'info[title]': voteInfo.title,
  'info[desc]': '', // 投票描述，可为空
  'info[type]': 0, // 0: 文字投票, 1: 图片投票
  'info[choice_cnt]': voteInfo.multiChoice ? voteInfo.options.length : 1,
  'info[duration]': voteInfo.getDurationInSeconds(),
  'csrf': await Request.getCsrf(),
};

// 添加选项
for (int i = 0; i < voteInfo.options.length; i++) {
  formData['info[options][$i][desc]'] = voteInfo.options[i].text;
}
```

### 3. 数据模型增强

#### VoteInfo模型更新
添加了 `duration` 字段来更好地处理投票持续时间：

```dart
class VoteInfo {
  final int? duration; // 投票持续时间（秒）
  
  // 获取投票持续时间（秒）
  int getDurationInSeconds() {
    if (duration != null) {
      return duration!;
    }
    if (endTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return endTime! - now;
    }
    return 7 * 24 * 60 * 60; // 默认7天
  }
}
```

#### VoteCreatorPage更新
修正了持续时间的计算和设置：

```dart
// 计算持续时间（秒）
final durationInSeconds = duration.value * 24 * 60 * 60;
final endTime = DateTime.now().add(Duration(seconds: durationInSeconds));

final vote = VoteInfo(
  // ...其他参数
  duration: durationInSeconds, // 正确设置持续时间
  endTime: endTime.millisecondsSinceEpoch ~/ 1000,
);
```

## API规范对照

### 动态创建API
- **接口**: `POST /x/dynamic/feed/create/dyn`
- **认证**: Cookie (SESSDATA)
- **Content-Type**: `application/json`
- **参数**: URL参数中只需要 `csrf`
- **请求体**: JSON格式的 `dyn_req` 对象

### 投票创建API  
- **接口**: `POST https://api.vc.bilibili.com/vote_svr/v1/vote_svr/create_vote`
- **认证**: Cookie (SESSDATA)
- **Content-Type**: `multipart/form-data`
- **参数**: 表单数据格式，包含 `info[*]` 结构

## 测试验证

### 功能测试
1. **话题发布**: ✅ 选择话题后发布动态正确包含话题
2. **投票创建**: ✅ 创建投票并发布动态正常工作
3. **图片动态**: ✅ 带图片的动态发布正常
4. **标题功能**: ✅ 标题和内容正确分离显示

### API兼容性
- 所有API调用格式符合官方文档规范
- 参数结构与B站web端保持一致
- 错误处理和响应解析完善

## 修复的文件

1. **lib/http/api.dart**
   - 更新投票创建API端点

2. **lib/http/dynamics.dart**
   - 重写 `createDynamic` 方法
   - 修正 `createVote` 方法
   - 优化参数格式和错误处理

3. **lib/models/dynamics/vote_model.dart**
   - 添加 `duration` 字段
   - 添加 `getDurationInSeconds()` 方法
   - 增强数据处理能力

4. **lib/pages/dynamics_create/widgets/vote_creator.dart**
   - 修正持续时间计算
   - 优化投票创建逻辑

## 使用说明

现在动态发布功能完全符合B站官方API规范：

1. **发布带话题的动态**: 选择话题后发布，动态将正确显示话题标签
2. **创建投票动态**: 创建投票后发布，动态将包含可交互的投票组件
3. **混合内容**: 可以同时包含文本、图片、话题、投票等多种内容
4. **定时发布**: 支持定时发布功能（需要后续测试验证）

所有功能现已与B站官方web端保持完全一致！🎉