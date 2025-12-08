# 插入内容功能重写

## 问题描述
用户反馈：插入内容功能应该显示 bilibili 的观看历史记录，而不是本地保存的选择历史。

## 功能说明
这个功能是：
1. **默认显示用户的 bilibili 观看历史记录**（通过 API 获取）
2. **搜索功能是搜索历史记录中的内容**（调用 bilibili 搜索历史 API）
3. **选择后插入视频/专栏的 URL 到评论输入框**

## 实现方案
完全重写了 `insert_content_search.dart`，使用 bilibili 的历史记录 API：
- `UserHttp.historyList()` - 获取观看历史列表
- `UserHttp.searchHistory()` - 搜索历史记录

## 核心实现

### API 调用
```dart
// 获取历史记录列表
Map res = await UserHttp.historyList(null, null);

// 搜索历史记录
Map res = await UserHttp.searchHistory(pn: _pn, keyword: keyword);
```

### 数据模型
使用现有的 `HisListItem` 模型（`lib/models/user/history.dart`）：
- `title` - 标题
- `cover` - 封面图
- `authorName` - UP主名称
- `duration` - 时长
- `badge` - 标签（如"番剧"）
- `history.business` - 业务类型（archive/pgc/article/live）
- `history.bvid` - 视频 BV 号
- `history.oid` - 对象 ID

### URL 生成规则
```dart
if (business == 'archive' && bvid != null) {
  // 视频
  url = 'https://www.bilibili.com/video/$bvid';
} else if (business == 'pgc') {
  // 番剧/电影
  url = item.uri;
} else if (business.contains('article')) {
  // 专栏
  url = 'https://www.bilibili.com/read/cv$oid';
} else if (business == 'live') {
  // 直播
  url = 'https://live.bilibili.com/$oid';
}
```

## 功能特性

1. **默认显示历史记录** - 打开页面立即加载用户的观看历史
2. **Tab 分类** - 视频和专栏分开显示
3. **搜索功能** - 搜索历史记录中的内容
4. **无限滚动** - 支持加载更多历史记录
5. **封面预览** - 显示视频封面、时长、UP主信息
6. **一键插入** - 点击即可将 URL 插入到评论输入框

## 测试步骤

1. 打开评论面板
2. 点击"更多"按钮
3. 点击"插入内容"
4. **预期**：显示用户的 bilibili 观看历史记录
5. 可以切换"视频"和"专栏" Tab
6. 可以搜索历史记录
7. 点击某一项，URL 会被插入到评论输入框

## 相关文件
- `lib/pages/video/reply_new/widgets/insert_content_search.dart` - 插入内容搜索页面
- `lib/http/user.dart` - 历史记录 API
- `lib/models/user/history.dart` - 历史记录数据模型
