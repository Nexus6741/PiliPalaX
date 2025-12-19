# 专栏JSON格式支持

## 问题描述
部分新版专栏使用JSON格式存储内容（`type=3`），直接显示会看到原始JSON字符串，无法正常阅读。

## 解决方案
添加JSON到HTML的转换功能，将JSON格式的专栏内容转换为可读的HTML格式。

## 实现细节

### JSON格式说明
新版专栏的content字段是一个JSON字符串，格式如下：
```json
{
  "ops": [
    {
      "insert": "文本内容",
      "attributes": {
        "bold": true,
        "header": 2
      }
    },
    {
      "insert": "\n"
    }
  ]
}
```

### 支持的格式

#### 1. 文本样式
- **粗体**: `{"bold": true}` → `<strong>文本</strong>`
- **斜体**: `{"italic": true}` → `<em>文本</em>`
- **删除线**: `{"strike": true}` → `<s>文本</s>`
- **链接**: `{"link": "url"}` → `<a href="url">文本</a>`

#### 2. 标题
- `{"header": 1}` → `<h1>标题</h1>`
- `{"header": 2}` → `<h2>标题</h2>`
- `{"header": 3}` → `<h3>标题</h3>`

#### 3. 列表
- `{"list": "bullet"}` → `<li>列表项</li>` (无序列表)
- `{"list": "ordered"}` → `<li>列表项</li>` (有序列表)

#### 4. 特殊内容
- **图片**: `{"native-image": {...}}` → `<img src="..." />`
- **分割线**: `{"cut-off": {...}}` → `<hr/>`
- **视频卡片**: `{"video-card": {...}}` → `[视频: aid]`
- **专栏卡片**: `{"article-card": {...}}` → `[专栏: cvid]`

### 代码实现

```dart
static String _convertJsonToHtml(String jsonContent) {
  final jsonData = json.decode(jsonContent);
  final ops = jsonData['ops'] as List;
  
  StringBuffer html = StringBuffer();
  
  for (var op in ops) {
    final insert = op['insert'];
    final attributes = op['attributes'];
    
    if (insert is String) {
      // 处理文本内容
      String styledText = insert;
      
      // 应用样式
      if (attributes != null) {
        if (attributes['bold'] == true) {
          styledText = '<strong>$styledText</strong>';
        }
        // ... 其他样式
      }
      
      html.write(styledText);
    } else if (insert is Map) {
      // 处理特殊内容（图片、卡片等）
      if (insert.containsKey('native-image')) {
        final img = insert['native-image'];
        html.write('<img src="${img['url']}" />');
      }
      // ... 其他特殊内容
    }
  }
  
  return html.toString();
}
```

### 使用方式

在`reqReadHtml`方法中自动检测并转换：

```dart
if (data['type'] == 3 && content.isNotEmpty) {
  try {
    content = _convertJsonToHtml(content);
  } catch (e) {
    print('JSON转换失败: $e');
    // 如果转换失败，保持原样
  }
}
```

## 测试建议

### 测试步骤
1. 搜索新版专栏（通常是最近发布的专栏）
2. 打开专栏查看内容是否正常显示
3. 检查以下元素是否正确渲染：
   - 标题层级
   - 粗体、斜体文本
   - 图片
   - 列表
   - 链接

### 预期结果
- ✅ 文本内容正常显示，不再是JSON字符串
- ✅ 标题、粗体等样式正确应用
- ✅ 图片正常加载
- ✅ 列表格式正确
- ✅ 链接可点击

### 已知限制
1. 视频卡片和专栏卡片暂时显示为文本标识
2. 复杂的嵌套样式可能不完全支持
3. 某些特殊格式可能需要进一步完善

## 后续优化

### 可能的改进
1. **视频卡片渲染**：将视频卡片渲染为可点击的预览
2. **专栏卡片渲染**：将专栏卡片渲染为可点击的链接
3. **列表嵌套**：支持多级列表
4. **代码块**：支持代码块的语法高亮
5. **表格**：如果JSON中包含表格数据，添加表格渲染支持

### 性能优化
- 对于超长专栏，可以考虑分段渲染
- 缓存转换结果，避免重复转换

## 参考
- B站API文档：`bilibili-API-collect/docs/article/view.md`
- JSON格式示例：API响应中的`content`字段（当`type=3`时）
