# @用户功能实现计划

## 功能概述

实现视频评论中的 @用户 功能，允许用户在评论时搜索并 @提及其他用户。

## API 信息

### 搜索用户 API
- **URL**: `https://api.bilibili.com/x/polymer/web-dynamic/v1/mention/search`
- **方法**: GET
- **认证**: Cookie (SESSDATA)
- **参数**:
  - `keyword` (str, 非必要): 搜索关键字，若无此项则返回所有关注用户

### 响应结构
```json
{
  "code": 0,
  "message": "0",
  "ttl": 1,
  "data": {
    "groups": [
      {
        "group_name": "我的关注",
        "group_type": 2,
        "items": [
          {
            "face": "https://...",
            "fans": 425,
            "name": "用户名",
            "official_verify_type": -1,
            "uid": "123456"
          }
        ]
      },
      {
        "group_name": "其他",
        "group_type": 4,
        "items": [...]
      }
    ]
  }
}
```

## 实现步骤

### 1. 添加 API 方法
在 `lib/http/video.dart` 中添加搜索用户的方法

### 2. 改进 MentionPanel
- 实现真实的用户搜索 API 调用
- 显示用户头像、昵称、粉丝数
- 区分"我的关注"和"其他"用户

### 3. 集成到评论对话框
- 在 `view_enhanced.dart` 中实现 @用户 功能
- 点击 @提及按钮时显示搜索面板
- 选择用户后插入 @提及文本

### 4. 文本处理
- 在富文本控制器中处理 @用户 文本
- 格式: `@用户名` 或 `@uid`
- 发送时保持原始格式

## 关键实现细节

### 用户搜索
- 支持按用户名搜索
- 优先显示已关注用户
- 显示用户认证状态

### @提及格式
- 使用 `@用户名` 格式
- 在评论中可以有多个 @提及
- 发送时保持原始格式

### UI 交互
- 搜索框实时搜索
- 显示搜索结果列表
- 点击用户后自动插入 @提及

## 文件修改

1. `lib/http/video.dart` - 添加搜索用户 API
2. `lib/pages/video/reply_new/widgets/mention_panel.dart` - 改进搜索面板
3. `lib/pages/video/reply_new/view_enhanced.dart` - 集成 @用户 功能

## 测试场景

1. 搜索已关注用户
2. 搜索未关注用户
3. 多个 @提及
4. 发送评论验证 @提及是否正确

## 参考资源

- bilibili-API-collect: `docs/dynamic/atlist.md`
- PiliPlus 实现参考
