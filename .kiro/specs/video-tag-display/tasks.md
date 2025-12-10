# Implementation Plan

- [x] 1. 创建VideoTag数据模型


  - 在lib/models/video目录下创建video_tag.dart文件
  - 定义VideoTag类,包含tagId、tagName、tagType、musicId、jumpUrl字段
  - 实现fromJson工厂方法用于JSON解析
  - 实现toJson方法用于序列化
  - 所有字段定义为可空类型
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ]* 1.1 为VideoTag模型编写属性测试
  - **Property 8: JSON解析往返一致性**
  - **Validates: Requirements 4.2**



- [ ] 2. 添加视频标签API接口
  - 在lib/http/api.dart中添加videoTags常量定义
  - API端点为'/x/web-interface/view/detail/tag'
  - 在lib/http/video.dart中实现VideoHttp.videoTags静态方法
  - 方法接收bvid和cid作为必需参数
  - 使用GET请求获取标签数据
  - 解析响应并返回VideoTag对象列表
  - 实现错误处理,返回统一的响应格式
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x]* 2.1 为API接口编写属性测试


  - **Property 1: API响应结构验证**
  - **Validates: Requirements 5.1, 5.2**

- [ ] 3. 扩展VideoIntroController支持标签
  - 在lib/pages/video/introduction/detail/controller.dart中添加videoTags响应式变量
  - 初始化videoTags为Rx<List<VideoTag>?>(null)
  - 实现queryVideoTags方法
  - 在queryVideoIntro方法中调用queryVideoTags
  - 处理API响应并更新videoTags变量
  - 确保异步加载不阻塞其他操作
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 8.1_



- [ ]* 3.1 为控制器编写属性测试
  - **Property 10: 响应式更新触发**
  - **Validates: Requirements 6.5**

- [ ] 4. 创建TagsWidget UI组件
  - 在lib/pages/video/introduction/widgets目录下创建tags_widget.dart
  - 实现TagsWidget StatelessWidget
  - 接收List<VideoTag>作为参数
  - 使用Wrap布局显示标签,spacing和runSpacing设为8
  - 实现_buildTagItem方法创建单个标签
  - 标签使用Container包裹,添加圆角和背景色
  - 标签文本字体大小设为13
  - 空列表时返回SizedBox.shrink()
  - _Requirements: 1.2, 1.3, 1.4, 1.5, 2.4, 2.5_

- [ ]* 4.1 为TagsWidget编写属性测试
  - **Property 2: 非空列表显示验证**
  - **Validates: Requirements 1.2**

- [x]* 4.2 为TagsWidget编写属性测试

  - **Property 3: 空列表隐藏验证**
  - **Validates: Requirements 1.3**

- [ ]* 4.3 为TagsWidget编写属性测试
  - **Property 4: 标签间距一致性**
  - **Validates: Requirements 1.5**

- [ ] 5. 实现标签显示文本转换逻辑
  - 在TagsWidget中实现_getDisplayText方法
  - 根据tagType转换显示文本
  - 普通标签(tag)直接返回tagName
  - 话题标签(topic)在tagName前添加"#"

  - BGM标签(bgm)将"发现"替换为"🎵BGM："
  - 处理tagName为null的情况
  - _Requirements: 2.1, 2.2, 2.3_

- [ ]* 5.1 为文本转换编写属性测试
  - **Property 5: 标签类型显示转换**
  - **Validates: Requirements 2.1, 2.2, 2.3**

- [ ] 6. 实现标签点击和长按交互
  - 在TagsWidget中实现_handleTagTap方法
  - 根据tagType执行不同的跳转逻辑
  - 普通标签跳转到/searchResult,传递keyword参数
  - 话题标签跳转到/dynTopic,传递id参数
  - BGM标签跳转到/musicDetail,传递musicId参数
  - 实现_handleTagLongPress方法
  - 长按时复制标签文本到剪贴板
  - 显示Toast提示"已复制: {text}"
  - 处理参数为null的情况,不执行跳转
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_



- [ ]* 6.1 为标签交互编写属性测试
  - **Property 6: 标签点击路由正确性**
  - **Validates: Requirements 3.1, 3.2, 3.3**

- [ ]* 6.2 为标签交互编写属性测试
  - **Property 7: 标签长按复制**

  - **Validates: Requirements 3.4**

- [ ] 7. 集成标签显示到视频简介面板
  - 在lib/pages/video/introduction/detail/view.dart中导入TagsWidget
  - 在IntroDetail widget的children列表中添加标签显示
  - 使用Obx包裹TagsWidget以响应videoTags变化
  - 将标签放置在视频描述下方
  - 添加适当的间距(上方10像素)
  - 确保在UGC视频页面正确显示
  - _Requirements: 7.1, 7.4, 7.5_



- [ ] 8. 测试和验证
  - 在真实设备或模拟器上测试功能
  - 验证标签正确显示
  - 验证不同类型标签的显示样式
  - 验证点击跳转功能
  - 验证长按复制功能
  - 验证空标签列表时的隐藏
  - 验证标签加载不影响其他内容
  - 测试深色模式和浅色模式
  - 测试不同屏幕尺寸
  - _Requirements: 8.2, 8.3, 8.4_

- [ ] 9. 代码优化和文档
  - 添加必要的代码注释
  - 确保代码符合项目规范
  - 移除调试日志
  - 检查并修复任何lint警告
  - 更新相关文档(如有需要)
