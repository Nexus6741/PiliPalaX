# 视频标签搜索历史污染问题修复

## 问题描述

**症状**:
- 点击视频标签后,打开搜索页时会自动搜索该标签
- 搜索历史被标签名称污染,只显示最后点击的标签
- 用户的真实搜索历史被覆盖

**根本原因**:
1. 点击标签时跳转到`/searchResult`页面,传递`keyword`参数
2. 搜索页面控制器在`onInit`中检测到`keyword`参数
3. 自动调用`onClickKeyword()`方法
4. 该方法触发`submit()`,将标签名添加到搜索历史
5. 导致搜索历史被标签名称污染

## 解决方案

添加一个`searchType`参数来区分搜索来源:
- 用户主动搜索: 正常添加到搜索历史
- 从标签跳转: 不添加到搜索历史

### 实现细节

#### 1. TagsWidget更新 ✅

在跳转到搜索结果时添加`searchType`参数:

```dart
// 普通标签: 直接跳转到搜索结果页,不经过搜索页以避免污染搜索历史
if (tag.tagName != null && tag.tagName!.isNotEmpty) {
  Get.toNamed('/searchResult', 
    parameters: {
      'keyword': tag.tagName!,
      'searchType': 'tag' // 标记这是从标签跳转的
    }
  );
}
```

#### 2. SearchController更新 ✅

在`onInit`中检查`searchType`参数:

```dart
@override
void onInit() {
  super.onInit();
  // 其他页面跳转过来
  if (Get.parameters.keys.isNotEmpty) {
    // 检查是否是从标签跳转的,如果是则不触发搜索(避免污染搜索历史)
    if (Get.parameters['keyword'] != null && 
        Get.parameters['searchType'] != 'tag') {
      onClickKeyword(Get.parameters['keyword']!);
    } else if (Get.parameters['keyword'] != null) {
      // 从标签跳转的,只设置关键词但不触发搜索
      searchKeyWord.value = Get.parameters['keyword']!;
      controller.value.text = Get.parameters['keyword']!;
    }
    // ... 其他代码
  }
  // ... 其他代码
}
```

## 修改的文件

1. `lib/pages/video/introduction/widgets/tags_widget.dart` - 添加searchType参数
2. `lib/pages/search/controller.dart` - 检查searchType参数

## 行为变化

### 修复前
1. 用户点击视频标签"情侣"
2. 跳转到搜索结果页
3. 如果用户打开搜索页,会看到"情侣"被自动搜索
4. 搜索历史中添加"情侣"
5. 用户的真实搜索历史被覆盖

### 修复后
1. 用户点击视频标签"情侣"
2. 跳转到搜索结果页(带searchType=tag参数)
3. 如果用户打开搜索页,只会看到关键词填充,不会自动搜索
4. 搜索历史不会被污染
5. 用户的真实搜索历史保持完整

## 测试验证

### 基本功能测试
- [x] 点击普通标签,跳转到搜索结果页
- [x] 搜索结果正确显示标签相关内容
- [x] 打开搜索页,搜索历史不包含标签名称
- [x] 用户主动搜索,正常添加到搜索历史

### 边界测试
- [x] 点击多个不同标签,搜索历史不被污染
- [x] 从标签跳转后,用户可以正常进行新的搜索
- [x] 搜索历史只包含用户主动搜索的关键词

### 兼容性测试
- [x] 话题标签(#)跳转不受影响
- [x] BGM标签(🎵)跳转不受影响
- [x] 从其他页面跳转到搜索页的功能不受影响

## 技术细节

### 参数传递
- 使用GetX的路由参数传递`searchType`
- 参数值: `'tag'` 表示从标签跳转
- 其他来源不传递此参数,默认为用户主动搜索

### 向后兼容
- 不传递`searchType`参数时,保持原有行为
- 只有明确标记为`'tag'`时才跳过历史记录
- 不影响其他页面跳转到搜索页的功能

## 代码质量

- ✅ 无编译错误
- ✅ 无警告信息
- ✅ 清晰的代码注释
- ✅ 向后兼容
- ✅ 最小化修改范围

## 相关文档

- 标签功能设计: `.kiro/specs/video-tag-display/design.md`
- 标签功能需求: `.kiro/specs/video-tag-display/requirements.md`
- 标签功能实现: `.kiro/specs/video-tag-display/IMPLEMENTATION_COMPLETE.md`
- 标签修复总结: `.kiro/specs/video-tag-display/TAG_FIXES_COMPLETE.md`

## 完成时间

2024年12月9日

---

**状态**: ✅ 搜索历史污染问题已修复
