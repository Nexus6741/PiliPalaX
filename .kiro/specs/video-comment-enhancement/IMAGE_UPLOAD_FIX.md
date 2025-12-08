# 图片上传完整修复

## 问题描述

用户在测试图片上传功能时遇到错误：
```
图片上传失败: Exception: type 'String' is not a subtype of type 'int' of 'index'
```

## 根本原因分析

通过详细对比 PiliPlus 项目和 bilibili-API-collect 文档，发现了三个关键问题：

### 1. API URL 错误
**错误的 URL：**
```dart
static const String uploadBfs = 'https://api.bilibili.com/x/upload/bfs';
```

**正确的 URL（参考 PiliPlus）：**
```dart
static const String uploadBfs = 'https://api.bilibili.com/x/dynamic/feed/draw/upload_bfs';
```

### 2. FormData 字段名错误
**错误的字段名：**
```dart
'file': await MultipartFile.fromFile(path, filename: path.split('/').last)
```

**正确的字段名（参考 PiliPlus）：**
```dart
'file_up': await MultipartFile.fromFile(path, filename: path.split('/').last)
```

### 3. 缺少 CSRF Token
上传图片需要 CSRF token 进行身份验证：
```dart
'csrf': await Request.getCsrf()
```

## 完整修复方案

### 修复 1: API URL（lib/http/api.dart）

```dart
/// 上传图片到 BFS 服务器
static const String uploadBfs = 'https://api.bilibili.com/x/dynamic/feed/draw/upload_bfs';
```

### 修复 2: uploadBfs 方法（lib/http/msg.dart）

**修改前：**
```dart
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(
    path,
    filename: path.split('/').last,
  ),
  'category': category,
  'biz': biz,
});
```

**修改后：**
```dart
// 获取 CSRF token
String csrf = await Request.getCsrf();

// 创建 FormData
final formData = FormData.fromMap({
  'file_up': await MultipartFile.fromFile(
    path,
    filename: path.split('/').last,
  ),
  'category': category,
  'biz': biz,
  'csrf': csrf,
});
```

### 修复 3: 数据类型处理（lib/pages/video/reply_new/view_enhanced.dart）

```dart
return {
  'img_src': data['image_url'],
  'img_width': data['image_width'],
  'img_height': data['image_height'],
  'img_size': (data['img_size'] as num?)?.toDouble() ?? 0.0,
};
```

## BFS API 详细说明

### 请求参数
根据 PiliPlus 实现和测试：

| 参数名 | 类型 | 说明 | 必需 |
|--------|------|------|------|
| file_up | File | 图片文件 | ✅ |
| category | String | 分类（如 'daily'） | ✅ |
| biz | String | 业务类型（如 'reply', 'new_dyn'） | ✅ |
| csrf | String | CSRF Token | ✅ |

### 响应数据结构
根据 bilibili-API-collect 文档和 PiliPlus 的 `UploadBfsResData` 模型：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "image_url": "https://i0.hdslb.com/bfs/...",
    "image_width": 1920,
    "image_height": 1080,
    "img_size": 245.6  // 单位：KB，类型为 num
  }
}
```

### 评论 API 图片参数格式
根据 bilibili-API-collect 文档，发送评论时的 pictures 参数格式：

```json
[
  {
    "img_src": "https://i0.hdslb.com/bfs/...",
    "img_width": 1920,
    "img_height": 1080,
    "img_size": 245.6
  }
]
```

## 参考资料

### PiliPlus 实现
- **文件：** `PiliPlus/lib/http/msg.dart`
- **API URL：** `/x/dynamic/feed/draw/upload_bfs`
- **字段名：** `file_up`
- **数据模型：** `PiliPlus/lib/models_new/upload_bfs/data.dart`

### bilibili-API-collect 文档
- **评论发表：** `bilibili-API-collect/docs/comment/action.md`
- **评论结构：** `bilibili-API-collect/docs/comment/readme.md`
- **图片字段：** pictures 数组包含 img_src, img_width, img_height, img_size

## 测试验证

修复后，用户应该能够：
1. ✅ 选择图片（最多9张）
2. ✅ 预览选中的图片
3. ✅ 上传图片到 BFS 服务器（使用正确的 API）
4. ✅ 成功发送带图片的评论

## 修改的文件

1. **lib/http/api.dart** - 修复 uploadBfs API URL
2. **lib/http/msg.dart** - 修复 uploadBfs 方法（字段名和 CSRF）
3. **lib/pages/video/reply_new/view_enhanced.dart** - 修复数据类型处理

## 技术要点

### 1. API 端点差异
B站有多个图片上传 API：
- `/x/upload/bfs` - 通用上传（可能已废弃）
- `/x/dynamic/feed/draw/upload_bfs` - 动态/评论图片上传（当前使用）
- `/x/upload/web/image` - Web 图片上传

### 2. 字段名规范
不同 API 可能使用不同的字段名：
- `file` - 某些旧 API
- `file_up` - 动态/评论图片上传 API

### 3. 类型安全
`img_size` 返回的是 KB 单位的数值，可能是整数或小数，需要安全转换：
```dart
(data['img_size'] as num?)?.toDouble() ?? 0.0
```

## 下一步

图片上传功能现已完全可用。后续可以实现的功能：
1. 图片裁剪（需要 image_cropper 依赖）
2. 图片预览（全屏查看）
3. 视频截图功能
4. 视频进度插入功能
5. @提及功能
6. 插入链接功能
