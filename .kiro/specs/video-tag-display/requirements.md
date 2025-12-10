# Requirements Document

## Introduction

本需求文档定义了在视频播放页面简介区域显示视频相关标签(tag)的功能。该功能将允许用户查看视频的分类标签、话题标签和BGM标签,并支持点击标签进行搜索或跳转到相关页面。此功能参考PiliPlus项目的实现,提供与其一致的用户体验。

## Glossary

- **VideoTag**: 视频标签,包含标签ID、名称、类型等信息
- **UGC视频**: User Generated Content,用户生成内容视频
- **PGC视频**: Professional Generated Content,专业生成内容视频(番剧、影视等)
- **简介区域**: 视频播放页面中显示视频标题、描述、UP主信息等内容的区域
- **标签类型**: 包括普通标签(tag)、话题标签(topic)、BGM标签(bgm)
- **SearchText组件**: 可点击的文本组件,用于显示可搜索的标签

## Requirements

### Requirement 1

**User Story:** 作为用户,我希望在视频简介区域看到视频的相关标签,以便了解视频的分类和主题

#### Acceptance Criteria

1. WHEN 用户打开视频详情页面 THEN 系统应当从API获取视频标签数据
2. WHEN 视频标签数据加载成功 THEN 系统应当在简介区域显示所有标签
3. WHEN 视频没有标签数据 THEN 系统应当隐藏标签显示区域
4. WHEN 标签数据包含多个标签 THEN 系统应当使用Wrap布局自动换行显示
5. WHEN 标签显示区域渲染完成 THEN 标签之间应当有8像素的水平和垂直间距

### Requirement 2

**User Story:** 作为用户,我希望看到不同类型的标签有不同的显示样式,以便快速识别标签类型

#### Acceptance Criteria

1. WHEN 标签类型为普通标签(tag) THEN 系统应当直接显示标签名称
2. WHEN 标签类型为话题标签(topic) THEN 系统应当在标签名称前添加"#"符号
3. WHEN 标签类型为BGM标签(bgm) THEN 系统应当将"发现"替换为"🎵BGM："前缀
4. WHEN 标签文本渲染 THEN 系统应当使用13号字体大小
5. WHEN 标签显示 THEN 系统应当使用SearchText组件以保持UI一致性

### Requirement 3

**User Story:** 作为用户,我希望点击标签能够跳转到相关页面,以便查看更多相关内容

#### Acceptance Criteria

1. WHEN 用户点击普通标签 THEN 系统应当跳转到搜索结果页面并使用标签名称作为搜索关键词
2. WHEN 用户点击话题标签 THEN 系统应当跳转到动态话题页面并传递标签ID
3. WHEN 用户点击BGM标签 THEN 系统应当跳转到音乐详情页面并传递音乐ID
4. WHEN 用户长按标签 THEN 系统应当复制标签文本到剪贴板
5. WHEN 标签点击事件触发 THEN 系统应当正确传递对应的参数(标签名称、ID或音乐ID)

### Requirement 4

**User Story:** 作为开发者,我希望创建标准的数据模型来存储标签信息,以便在应用中统一处理标签数据

#### Acceptance Criteria

1. WHEN 系统定义VideoTag模型 THEN 模型应当包含tagId、tagName、tagType、musicId和jumpUrl字段
2. WHEN 系统接收API响应 THEN 系统应当使用fromJson工厂方法将JSON数据转换为VideoTag对象
3. WHEN tagId字段存在 THEN 系统应当将其解析为整数类型
4. WHEN tagName字段存在 THEN 系统应当将其解析为字符串类型
5. WHEN 所有字段 THEN 系统应当定义为可空类型以处理缺失数据

### Requirement 5

**User Story:** 作为开发者,我希望在HTTP层添加获取视频标签的API接口,以便从服务器获取标签数据

#### Acceptance Criteria

1. WHEN 系统调用videoTags接口 THEN 系统应当使用GET方法请求'/x/web-interface/view/detail/tag'端点
2. WHEN 发起API请求 THEN 系统应当传递bvid和cid作为查询参数
3. WHEN API响应成功 THEN 系统应当返回VideoTag对象列表
4. WHEN API响应失败 THEN 系统应当返回null或空列表
5. WHEN 解析响应数据 THEN 系统应当遍历data数组并将每个元素转换为VideoTag对象

### Requirement 6

**User Story:** 作为开发者,我希望在视频简介控制器中管理标签数据状态,以便响应式更新UI

#### Acceptance Criteria

1. WHEN 控制器初始化 THEN 系统应当创建videoTags响应式变量并初始化为null
2. WHEN queryVideoIntro方法执行 THEN 系统应当调用queryVideoTags方法获取标签数据
3. WHEN queryVideoTags方法执行 THEN 系统应当调用UserHttp.videoTags接口
4. WHEN 标签数据获取成功 THEN 系统应当更新videoTags响应式变量
5. WHEN videoTags变量更新 THEN 系统应当触发UI重新渲染

### Requirement 7

**User Story:** 作为用户,我希望在UGC视频和PGC视频页面都能看到标签,以便在不同类型视频中获得一致的体验

#### Acceptance Criteria

1. WHEN 用户查看UGC视频 THEN 系统应当在简介面板中显示标签
2. WHEN 用户查看PGC视频 THEN 系统应当在简介详情面板中显示标签
3. WHEN 标签数据为空或null THEN 系统应当在两种视频类型中都隐藏标签区域
4. WHEN 标签显示位置 THEN 系统应当将标签放置在视频描述下方
5. WHEN 标签区域渲染 THEN 系统应当在标签上方添加10像素的间距

### Requirement 8

**User Story:** 作为用户,我希望标签加载过程不影响页面其他内容的显示,以便获得流畅的浏览体验

#### Acceptance Criteria

1. WHEN 视频详情页面加载 THEN 系统应当异步获取标签数据
2. WHEN 标签数据加载中 THEN 系统应当不显示加载指示器
3. WHEN 标签数据加载失败 THEN 系统应当静默失败不显示错误提示
4. WHEN 标签数据加载完成 THEN 系统应当平滑显示标签区域
5. WHEN 页面其他内容加载 THEN 系统应当不等待标签数据加载完成
