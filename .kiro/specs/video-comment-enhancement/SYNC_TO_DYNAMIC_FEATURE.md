# 转发到动态功能实现

## 功能概述

实现了"转发到动态"复选框功能，用户可以在发送视频评论时，同时将评论转发到个人动态。

## 实现原理

### 网络请求差异

**不转发到动态的请求参数**:
```
plat: 1
oid: 114934398586133
type: 1
message: 好
at_name_to_mid: {}
sync_to_dynamic: 1  ← 不包含此参数
gaia_source: main_web
csrf: 8e50f9daf701cfc71da442e148f86599
statistics: {"appId":100,"platform":5}
```

**转发到动态的请求参数**:
```
plat: 1
oid: 114934398586133
type: 1
message: 还是可以的
at_name_to_mid: {}
sync_to_dynamic: 1  ← 包含此参数，值为 1
gaia_source: main_web
csrf: 8e50f9daf701cfc71da442e148f86599
statistics: {"appId":100,"platform":5}
```

**关键差异**: 当需要转发到动态时，添加 `sync_to_dynamic: 1` 参数

## 代码实现

### 1. 状态管理

在 `view_enhanced.dart` 中添加状态变量：

```dart
late final RxBool syncToDynamic = false.obs;
```

### 2. UI 组件

使用复选框图标显示状态：

```dart
Obx(
  () => ToolbarIconButton(
    tooltip: syncToDynamic.value ? '取消转发到动态' : '转发到动态',
    onPressed: onGoToDynamics,
    icon: syncToDynamic.value
        ? const Icon(Icons.check_box, size: 22)
        : const Icon(Icons.check_box_outline_blank, size: 22),
    toolbarType: toolbarType,
    selected: syncToDynamic.value,
  ),
)
```

### 3. 点击处理

```dart
void onGoToDynamics() {
  syncToDynamic.value = !syncToDynamic.value;
  final status = syncToDynamic.value ? '已启用' : '已禁用';
  SmartDialog.showToast('转发到动态: $status');
}
```

### 4. API 修改

修改 `lib/http/video.dart` 中的 `replyAdd` 方法：

```dart
static Future replyAdd({
  required ReplyType type,
  required int oid,
  required String message,
  int? root,
  int? parent,
  List<Map<String, dynamic>>? pictures,
  bool syncToDynamic = false,  // 新增参数
}) async {
  // ...
  final data = {
    'type': type.index,
    'oid': oid,
    'root': root == null || root == 0 ? '' : root,
    'parent': parent == null || parent == 0 ? '' : parent,
    'message': message,
    if (pictures != null && pictures.isNotEmpty)
      'pictures': jsonEncode(pictures),
    if (syncToDynamic) 'sync_to_dynamic': 1,  // 条件添加参数
    'csrf': await Request.getCsrf(),
  };
  // ...
}
```

### 5. 发送评论时传递参数

在 `submitReplyAdd()` 方法中：

```dart
var result = await VideoHttp.replyAdd(
  type: widget.replyType ?? ReplyType.video,
  oid: widget.oid!,
  root: widget.root!,
  parent: widget.parent!,
  message: message,
  pictures: pictures,
  syncToDynamic: syncToDynamic.value,  // 传递复选框状态
);
```

## 用户交互流程

1. **初始状态**: 复选框为未选中状态（空心方框图标）
2. **点击复选框**: 
   - 状态切换为已选中（实心方框图标）
   - 显示 Toast 提示："转发到动态: 已启用"
3. **再次点击**: 
   - 状态切换为未选中
   - 显示 Toast 提示："转发到动态: 已禁用"
4. **发送评论**:
   - 如果复选框已选中，API 请求会包含 `sync_to_dynamic: 1` 参数
   - 评论会同时发送到视频评论区和个人动态

## 工具栏布局

```
[😊表情] [🖼️图片] [@提及] [➕更多] [☑️转发到动态] [取消] [发送]
```

- 未选中: ☐ (check_box_outline_blank)
- 已选中: ☑️ (check_box)

## 修改的文件

1. `lib/pages/video/reply_new/view_enhanced.dart`
   - 添加 `syncToDynamic` 状态变量
   - 修改 `onGoToDynamics()` 方法
   - 修改工具栏按钮为 Obx 包装的复选框
   - 修改 `submitReplyAdd()` 方法传递参数

2. `lib/http/video.dart`
   - 修改 `replyAdd()` 方法添加 `syncToDynamic` 参数
   - 条件添加 `sync_to_dynamic: 1` 到请求数据

## 测试清单

- [ ] 复选框初始状态为未选中
- [ ] 点击复选框能切换状态
- [ ] 显示正确的 Toast 提示
- [ ] 图标正确显示（空心/实心）
- [ ] 未选中时发送评论不包含 `sync_to_dynamic` 参数
- [ ] 已选中时发送评论包含 `sync_to_dynamic: 1` 参数
- [ ] 评论成功发送到视频评论区
- [ ] 评论成功转发到个人动态（需在动态页面验证）

## 完成时间

- 实现时间: 2024-12-08
- 文档完成: 2024-12-08
