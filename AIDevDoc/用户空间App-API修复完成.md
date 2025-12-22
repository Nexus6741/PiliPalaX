# 用户空间 App API 修复完成

## 修复时间
2025-12-22

## 问题描述
1. **主页Tab显示"暂无内容"** - 因为使用了 Web API (`/x/space/wbi/acc/info`)，该 API 不返回 `archive`、`favourite2`、`coinArchive`、`likeArchive` 等主页数据
2. **追番Tab报错** - `bangumiFollow` API 的查询参数配置有问题

## 解决方案

### 1. 切换到 App API（与 PiliPlus 一致）

参考 PiliPlus 的实现，将用户空间 API 从 Web API 切换回 App API：

**API 端点**：`/x/v2/space`

**关键参数**：
```dart
{
  'build': 8430300,
  'version': '8.43.0',
  'c_locale': 'zh_CN',
  'channel': 'master',
  'mobi_app': 'android',
  'platform': 'android',
  's_locale': 'zh_CN',
  'statistics': '{"appId":1,"platform":3,"version":"8.43.0","abtest":""}',
  'vmid': mid,
}
```

**关键 Headers**：
```dart
{
  'bili-http-engine': 'cronet',
  'user-agent': 'Mozilla/5.0 BiliDroid/8.43.0 (bbcallen@gmail.com) os/android model/android mobi_app/android build/8430300 channel/master innerVer/8430300 osVer/15 network/2',
}
```

### 2. 修复追番 API

修复 `bangumiFollow` API 的查询参数：

**修改前**：
```dart
// API 端点包含硬编码参数，导致冲突
static const String bangumiFollow = 
  '/x/space/bangumi/follow/list?type=1&follow_status=0&pn=1&ps=15&ts=1691544359969';

// 调用时只传 vmid
var res = await Request().get(Api.bangumiFollow, data: {'vmid': mid});
```

**修改后**：
```dart
// API 端点不包含参数
static const String bangumiFollow = '/x/space/bangumi/follow/list';

// 调用时传完整参数
var res = await Request().get(Api.bangumiFollow, data: {
  'vmid': mid,
  'type': 1,
  'follow_status': 0,
  'pn': 1,
  'ps': 50,
});
```

## 修改的文件

### 1. `lib/http/member.dart`
- 修改 `space()` 方法，使用 App API 而不是 Web API
- 移除 WbiSign 签名（App API 不需要）
- 移除数据转换逻辑（App API 直接返回正确格式）
- 添加 App API 所需的参数和 Headers
- 添加更详细的调试日志

### 2. `lib/http/api.dart`
- 修改 `bangumiFollow` 常量，移除硬编码的查询参数

### 3. `lib/http/bangumi.dart`
- 修改 `bangumiFollow()` 方法，添加完整的查询参数

## App API vs Web API 对比

| 特性     | App API                                           | Web API                 |
| -------- | ------------------------------------------------- | ----------------------- |
| 端点     | `/x/v2/space`                                     | `/x/space/wbi/acc/info` |
| 签名     | 不需要                                            | 需要 WbiSign            |
| 数据结构 | 嵌套结构（card/images）                           | 扁平结构                |
| 主页数据 | ✅ 包含 archive/favourite2/coinArchive/likeArchive | ❌ 不包含                |
| Tab配置  | ✅ 包含 tab2                                       | ❌ 不包含                |
| 用户代理 | Android App                                       | PC Web                  |

## 预期效果

修复后，用户空间功能应该完全正常：

1. ✅ **主页Tab** - 显示投稿、收藏、投币、点赞视频
2. ✅ **追番Tab** - 显示用户追番列表
3. ✅ **用户信息卡片** - 显示头像、背景、粉丝/关注/获赞数据
4. ✅ **Tab配置** - 根据 API 返回的 tab2 动态配置

## 调试日志

修改后的代码会输出详细的调试日志：

```
========== memberSpace API Response ==========
Response code: 0
Message: 0
Raw data keys: [card, images, archive, favourite2, coin_archive, like_archive, tab2, ...]
✅ Parsed successfully
Card parsed: true
Card fans: 12345
Card attention: 678
Card likes: 9012
Images parsed: true
Archive count: 100
Favourite2 count: 5
CoinArchive count: 20
LikeArchive count: 30
Tab2 count: 5
==============================================
```

## 参考

- PiliPlus 项目：`PiliPlus/lib/http/member.dart` 的 `space()` 方法
- PiliPlus 常量：`PiliPlus/lib/common/constants.dart`
- bilibili-API-collect：用户空间相关 API 文档

## 注意事项

1. App API 需要正确的 User-Agent 和 Headers，否则可能返回 -400 错误
2. `statistics` 参数必须是 JSON 字符串格式
3. 如果遇到 -400 错误，检查：
   - User-Agent 是否正确
   - Headers 是否包含 `bili-http-engine: cronet`
   - 参数格式是否正确
