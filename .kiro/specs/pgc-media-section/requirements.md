# 影视分区功能需求文档

## 简介

本文档定义了在PiliPalaX应用中实现影视分区（电影、电视剧、纪录片、综艺）功能的需求。该功能将参照PiliPlus项目的实现，支持用户浏览和观看电影、电视剧等专业制作内容。番剧分区已单独实现，本文档专注于影视分区的实现。

## 术语表

- **PGC系统**: Professional Generated Content系统，指专业制作内容管理系统，包括番剧、电影、电视剧等
- **番剧**: 日本动画作品，通常按季度更新
- **影视**: 包括电影、电视剧、纪录片、综艺等专业制作的视频内容
- **追番/追剧**: 用户订阅并持续关注某个番剧或影视作品的行为
- **时间表**: 显示番剧更新时间和集数的日历视图
- **索引页**: 按分类浏览影视内容的页面
- **Season ID**: 番剧/影视作品的季度标识符
- **Episode ID**: 番剧/影视作品的集数标识符

## 需求

### 需求 1: PGC页面基础架构

**用户故事:** 作为用户，我想要访问独立的影视分区页面，以便浏览和观看专业制作的内容。

#### 验收标准

1. WHEN 用户导航到番剧或影视分区 THEN PGC系统 SHALL 显示包含追番/追剧、时间表和推荐内容的完整页面布局
2. WHEN 用户下拉刷新页面 THEN PGC系统 SHALL 重新加载所有内容区域并更新显示
3. WHEN 用户滚动到页面底部 THEN PGC系统 SHALL 自动加载更多推荐内容
4. WHEN 用户切换到其他页面后返回 THEN PGC系统 SHALL 保持之前的滚动位置和加载状态
5. WHEN 页面加载失败 THEN PGC系统 SHALL 显示错误信息和重试按钮

### 需求 2: 追番追剧功能

**用户故事:** 作为已登录用户，我想要查看我订阅的番剧和影视作品，以便快速访问正在追看的内容。

#### 验收标准

1. WHEN 用户已登录 THEN PGC系统 SHALL 在页面顶部显示"最近追番/追剧"区域
2. WHEN 用户未登录 THEN PGC系统 SHALL 隐藏追番追剧区域
3. WHEN 追番追剧区域加载完成 THEN PGC系统 SHALL 以横向滚动列表形式显示用户订阅的作品
4. WHEN 用户点击追番追剧区域的刷新按钮 THEN PGC系统 SHALL 重新加载订阅列表
5. WHEN 用户点击"查看全部"按钮 THEN PGC系统 SHALL 导航到收藏页面的对应分类
6. WHEN 用户订阅列表为空 THEN PGC系统 SHALL 显示"还没有追番/追剧"提示
7. WHEN 用户滚动到订阅列表末尾 THEN PGC系统 SHALL 自动加载下一页订阅内容

### 需求 3: 影视追剧功能

**用户故事:** 作为已登录用户，我想要查看我订阅的电影和电视剧，以便快速访问正在追看的影视作品。

#### 验收标准

1. WHEN 用户已登录 THEN PGC系统 SHALL 在页面顶部显示"最近追剧"区域
2. WHEN 用户未登录 THEN PGC系统 SHALL 隐藏追剧区域
3. WHEN 追剧区域加载完成 THEN PGC系统 SHALL 以横向滚动列表形式显示用户订阅的影视作品
4. WHEN 用户点击追剧区域的刷新按钮 THEN PGC系统 SHALL 重新加载订阅列表
5. WHEN 用户点击"查看全部"按钮 THEN PGC系统 SHALL 导航到收藏页面的影视分类
6. WHEN 用户订阅列表为空 THEN PGC系统 SHALL 显示"还没有追剧"提示
7. WHEN 用户滚动到订阅列表末尾 THEN PGC系统 SHALL 自动加载下一页订阅内容

### 需求 4: 推荐内容展示

**用户故事:** 作为用户，我想要浏览推荐的影视内容，以便发现感兴趣的新电影和电视剧。

#### 验收标准

1. WHEN 页面加载 THEN PGC系统 SHALL 在推荐区域显示网格布局的内容卡片
2. WHEN 用户滚动到推荐列表底部 THEN PGC系统 SHALL 自动加载下一页推荐内容
3. WHEN 推荐内容加载失败 THEN PGC系统 SHALL 显示错误信息和重新加载按钮
4. WHEN 用户点击推荐区域的"更多"按钮 THEN PGC系统 SHALL 导航到影视索引页面
5. WHEN 显示影视推荐 THEN PGC系统 SHALL 显示评分、播放量等统计信息

### 需求 5: 影视索引页面

**用户故事:** 作为用户，我想要按分类浏览影视内容，以便找到特定类型的作品。

#### 验收标准

1. WHEN 用户从影视页面点击"更多" THEN PGC系统 SHALL 显示包含"全部、电影、电视剧、纪录片、综艺"标签的索引页面
2. WHEN 索引页面加载 THEN PGC系统 SHALL 显示顶部标签栏和对应的内容列表
3. WHEN 用户点击标签 THEN PGC系统 SHALL 切换到对应分类的内容列表
4. WHEN 用户在标签间切换 THEN PGC系统 SHALL 保持每个标签的独立滚动状态
5. WHEN 用户滚动到索引列表底部 THEN PGC系统 SHALL 自动加载该分类的更多内容
6. WHEN 索引内容加载失败 THEN PGC系统 SHALL 显示错误信息和重试按钮
7. WHEN 索引页面显示筛选条件 THEN PGC系统 SHALL 支持按类型、地区、年份等条件筛选

### 需求 6: 影视内容卡片

**用户故事:** 作为用户，我想要看到清晰的内容卡片展示，以便了解作品的基本信息。

#### 验收标准

1. WHEN 显示影视内容卡片 THEN PGC系统 SHALL 展示封面图片、标题、评分和观看进度
2. WHEN 用户点击内容卡片 THEN PGC系统 SHALL 导航到对应的视频播放页面
3. WHEN 卡片显示追剧内容 THEN PGC系统 SHALL 显示用户的观看进度信息
4. WHEN 卡片显示推荐内容 THEN PGC系统 SHALL 显示评分、播放量等统计信息
5. WHEN 卡片显示索引内容 THEN PGC系统 SHALL 显示作品类型、地区、年份等信息
6. WHEN 封面图片加载失败 THEN PGC系统 SHALL 显示占位图

### 需求 7: HTTP API集成

**用户故事:** 作为系统，我需要与Bilibili API通信，以便获取PGC内容数据。

#### 验收标准

1. WHEN 请求追番追剧列表 THEN PGC系统 SHALL 调用收藏PGC接口并传递用户ID和类型参数
2. WHEN 请求番剧时间表 THEN PGC系统 SHALL 调用时间表接口并传递类型和日期范围参数
3. WHEN 请求推荐内容 THEN PGC系统 SHALL 调用PGC索引接口并传递页码和类型参数
4. WHEN 请求索引内容 THEN PGC系统 SHALL 调用PGC索引接口并传递分类类型参数
5. WHEN API请求失败 THEN PGC系统 SHALL 返回包含错误信息的结果对象
6. WHEN API返回数据 THEN PGC系统 SHALL 解析JSON并转换为对应的数据模型
7. WHEN 发起API请求 THEN PGC系统 SHALL 包含必要的认证信息和请求头

### 需求 8: 数据模型

**用户故事:** 作为开发者，我需要定义清晰的数据模型，以便正确处理影视内容数据。

#### 验收标准

1. WHEN 解析追剧数据 THEN PGC系统 SHALL 使用FavPgcItemModel模型
2. WHEN 解析推荐和索引数据 THEN PGC系统 SHALL 使用PgcIndexItem模型
3. WHEN 模型接收JSON数据 THEN PGC系统 SHALL 正确映射所有必需字段
4. WHEN 模型字段为空 THEN PGC系统 SHALL 使用合理的默认值或null
5. WHEN 模型包含嵌套对象 THEN PGC系统 SHALL 递归解析所有层级的数据
6. WHEN 影视类型为电影 THEN PGC系统 SHALL seasonType值为2
7. WHEN 影视类型为电视剧 THEN PGC系统 SHALL seasonType值为5

### 需求 9: 路由和导航

**用户故事:** 作为用户，我想要在不同页面间流畅导航，以便访问各种影视功能。

#### 验收标准

1. WHEN 用户点击影视内容卡片 THEN PGC系统 SHALL 导航到视频播放页面并传递season ID和episode ID
2. WHEN 导航到视频页面 THEN PGC系统 SHALL 传递videoType参数标识为PGC内容
3. WHEN 用户点击"查看全部" THEN PGC系统 SHALL 导航到收藏页面的影视分类
4. WHEN 用户点击"更多" THEN PGC系统 SHALL 导航到影视索引页面
5. WHEN 从外部链接打开影视内容 THEN PGC系统 SHALL 解析season ID或episode ID并导航到播放页面
6. WHEN 导航发生 THEN PGC系统 SHALL 保持页面状态以支持返回时恢复

### 需求 10: 状态管理

**用户故事:** 作为系统，我需要正确管理页面状态，以便提供流畅的用户体验。

#### 验收标准

1. WHEN 页面初始化 THEN PGC系统 SHALL 设置所有状态为加载中
2. WHEN 数据加载完成 THEN PGC系统 SHALL 更新状态为成功并存储数据
3. WHEN 数据加载失败 THEN PGC系统 SHALL 更新状态为错误并存储错误信息
4. WHEN 用户触发刷新 THEN PGC系统 SHALL 重置页码并清空现有数据
5. WHEN 用户触发加载更多 THEN PGC系统 SHALL 递增页码并追加新数据到现有列表
6. WHEN 页面销毁 THEN PGC系统 SHALL 释放所有控制器和监听器资源
7. WHEN 使用GetX状态管理 THEN PGC系统 SHALL 使用Rx变量实现响应式更新

### 需求 11: UI组件复用

**用户故事:** 作为开发者，我需要创建可复用的UI组件，以便在不同场景下展示PGC内容。

#### 验收标准

1. WHEN 创建PGC卡片组件 THEN PGC系统 SHALL 支持不同的显示模式（追番、时间表、索引）
2. WHEN 组件接收数据模型 THEN PGC系统 SHALL 根据模型类型自动适配显示内容
3. WHEN 组件需要显示图片 THEN PGC系统 SHALL 使用统一的图片加载组件
4. WHEN 组件需要显示加载状态 THEN PGC系统 SHALL 使用统一的加载指示器
5. WHEN 组件需要显示错误 THEN PGC系统 SHALL 使用统一的错误提示组件
6. WHEN 组件被点击 THEN PGC系统 SHALL 触发导航到详情页面

### 需求 12: 性能优化

**用户故事:** 作为用户，我期望页面加载流畅，以便获得良好的使用体验。

#### 验收标准

1. WHEN 页面包含长列表 THEN PGC系统 SHALL 使用ListView.builder实现懒加载
2. WHEN 页面包含网格布局 THEN PGC系统 SHALL 使用SliverGrid实现高效渲染
3. WHEN 页面需要保持状态 THEN PGC系统 SHALL 使用AutomaticKeepAliveClientMixin
4. WHEN 图片加载 THEN PGC系统 SHALL 使用缓存机制避免重复下载
5. WHEN 用户快速滚动 THEN PGC系统 SHALL 使用节流机制控制加载更多的触发频率
6. WHEN 页面切换 THEN PGC系统 SHALL 取消未完成的网络请求

### 需求 13: 错误处理

**用户故事:** 作为用户，当发生错误时，我想要看到清晰的提示信息，以便了解问题并采取行动。

#### 验收标准

1. WHEN 网络请求失败 THEN PGC系统 SHALL 显示包含错误原因的提示信息
2. WHEN 显示错误提示 THEN PGC系统 SHALL 提供重试按钮
3. WHEN 用户点击重试 THEN PGC系统 SHALL 重新发起失败的请求
4. WHEN 数据解析失败 THEN PGC系统 SHALL 记录错误日志并显示通用错误提示
5. WHEN 用户未登录但访问需要登录的功能 THEN PGC系统 SHALL 显示登录提示
6. WHEN 内容不存在 THEN PGC系统 SHALL 显示"内容不存在"提示

### 需求 14: 主页集成

**用户故事:** 作为用户，我想要从主页访问影视分区，以便快速进入影视内容浏览。

#### 验收标准

1. WHEN 主页加载 THEN PGC系统 SHALL 在底部导航栏或标签栏中显示影视入口
2. WHEN 用户点击影视标签 THEN PGC系统 SHALL 显示影视页面
3. WHEN 标签切换 THEN PGC系统 SHALL 使用独立的控制器实例管理影视页面状态
4. WHEN 用户双击影视标签 THEN PGC系统 SHALL 滚动到页面顶部并刷新内容
5. WHEN 影视页面显示 THEN PGC系统 SHALL 隐藏番剧时间表区域
