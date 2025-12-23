# 排行Tab分区修复完成

## 问题描述
排行tab中除了"全站"选项外，其他分区标签的视频都是今年3-5月份的旧视频，不是最新的视频。同时左侧分区标签选择时没有视觉反馈提示。

## 问题原因
1. **API请求缺少WbiSign签名**：原代码直接拼接URL参数，没有使用WbiSign签名，导致B站返回旧数据
2. **分区rid值错误**：使用了错误的分区ID（如动画使用1而不是1005）
3. **缺少选中状态视觉反馈**：左侧分区标签没有选中状态的背景色和指示条

## 修复内容

### 1. 修复API请求（lib/http/video.dart）
**修改前：**
```dart
// 视频排行
static Future getRankVideoList(int rid) async {
  try {
    var rankApi = "${Api.getRankApi}?rid=$rid&type=all";
    var res = await Request().get(rankApi);
    // ...
  }
}
```

**修改后：**
```dart
// 视频排行
static Future getRankVideoList(int rid) async {
  try {
    final wbiSign = WbiSign();
    final params = await wbiSign.makSign({
      'rid': rid,
      'type': 'all',
    });
    var res = await Request().get(Api.getRankApi, data: params);
    // ...
  }
}
```

### 2. 更新分区rid值（lib/models/common/rank_type.dart）
**修改前的rid值：**
- 动画: 1 → **1005**
- 音乐: 3 → **1003**
- 舞蹈: 129 → **1004**
- 游戏: 4 → **1008**
- 知识: 36 → **1010**
- 科技: 188 → **1012**
- 运动: 234 → **1018**
- 汽车: 223 → **1013**
- 美食: 211 → **1020**
- 动物: 217 → **1024**
- 鬼畜: 119 → **1007**
- 时尚: 155 → **1014**
- 娱乐: 5 → **1002**
- 影视: 181 → **1001**

**移除的分区：**
- 国创 (168)
- 生活 (160)
- 纪录 (177)
- 电影 (23)
- 剧集 (11)

这些分区在PiliPlus中使用seasonType而不是rid，暂不支持。

### 3. 添加选中状态视觉反馈（lib/pages/rank/view.dart）
**修改前：** 使用NavigationRail组件，没有明显的选中状态

**修改后：** 使用自定义ListView + Material + InkWell实现
- 选中时显示左侧蓝色指示条（3px宽）
- 选中时背景色变为`theme.colorScheme.onInverseSurface`
- 选中时文字颜色变为主题色`theme.colorScheme.primary`
- 未选中时文字颜色为`theme.colorScheme.onSurface`

```dart
Material(
  color: _selectedTabIndex == index
      ? theme.colorScheme.onInverseSurface
      : theme.colorScheme.surface,
  child: InkWell(
    onTap: () { /* ... */ },
    child: Row(
      children: [
        if (_selectedTabIndex == index)
          Container(
            height: double.infinity,
            width: 3,
            color: theme.colorScheme.primary,
          )
        else
          const SizedBox(width: 3),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              _rankController.tabs[index]['label'],
              style: TextStyle(
                color: _selectedTabIndex == index
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
)
```

### 4. 代码清理
- 移除`lib/pages/rank/zone/controller.dart`中的调试日志
- 移除`lib/pages/rank/zone/view.dart`中未使用的导入和方法

## 测试验证
1. 打开排行Tab
2. 点击不同的分区标签（动画、音乐、舞蹈等）
3. 验证：
   - ✅ 显示的是最新视频（非3-5月份的旧视频）
   - ✅ 左侧标签有明显的选中状态（蓝色条和背景色）
   - ✅ 点击已选中的标签会滚动到顶部
   - ✅ 下拉刷新正常工作

## 参考实现
- PiliPlus项目的排行页面实现
- PiliPlus使用的分区rid值
- PiliPlus的选中状态视觉设计

## 技术要点
1. **WbiSign签名**：B站API需要WbiSign签名才能返回最新数据
2. **正确的rid值**：不同分区有特定的rid值，需要使用正确的值
3. **Material Design**：使用Material + InkWell实现符合Material Design的交互效果
4. **主题适配**：使用Theme.of(context)获取主题色，支持深色/浅色模式

## 修改文件
- `lib/http/video.dart` - 添加WbiSign签名
- `lib/models/common/rank_type.dart` - 更新rid值和移除不支持的分区
- `lib/pages/rank/view.dart` - 添加选中状态视觉反馈
- `lib/pages/rank/zone/controller.dart` - 移除调试日志
- `lib/pages/rank/zone/view.dart` - 清理未使用的代码
