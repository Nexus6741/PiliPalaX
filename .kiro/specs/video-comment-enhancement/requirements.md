# Requirements Document

## Introduction

本规范旨在完善 pilipalax 项目的视频评论发布功能，参考 piliplus 项目的完整实现，添加富文本评论支持，包括：发带图评论、@用户、插入视频/专栏内容、插入视频进度、插入视频截图等高级功能。目标是提供与 piliplus 项目相同的用户体验和功能完整性。

## Glossary

- **System**: pilipalax 视频评论系统
- **Rich Text Comment**: 富文本评论，支持文本、表情、图片、@用户、视频链接等多种内容类型的评论
- **RichTextItem**: 富文本项，表示评论中的一个内容片段（文本、表情、@用户等）
- **Emote**: 表情，包括文本表情和图片表情
- **Mention**: @用户功能，在评论中提及其他用户
- **Image Upload**: 图片上传功能，支持上传本地图片到评论中
- **Video Progress**: 视频进度，在评论中插入当前视频的播放时间点
- **Video Screenshot**: 视频截图，在评论中插入当前视频画面的截图
- **Toolbar**: 工具栏，评论输入框下方的功能按钮区域
- **Panel**: 面板，工具栏按钮触发显示的功能区域（如表情面板、更多功能面板）

## Requirements

### Requirement 1

**User Story:** 作为用户，我想要在评论中添加图片，以便更直观地表达我的想法和分享内容。

#### Acceptance Criteria

1. WHEN 用户点击图片按钮 THEN System SHALL 打开系统图片选择器
2. WHEN 用户选择图片后 THEN System SHALL 在评论输入区域上方显示已选择的图片缩略图
3. WHEN 用户点击图片缩略图 THEN System SHALL 显示图片预览
4. WHEN 用户长按或右键点击图片缩略图 THEN System SHALL 提供删除图片的选项
5. WHEN 用户在移动端点击编辑按钮 THEN System SHALL 提供裁剪图片的功能
6. WHEN 用户选择的图片数量达到上限（9张）THEN System SHALL 显示提示信息并阻止继续选择
7. WHEN 用户发送评论 THEN System SHALL 先上传所有图片到 BFS 服务器，然后提交评论内容

### Requirement 2

**User Story:** 作为用户，我想要在评论中 @其他用户，以便通知他们查看我的评论或与他们互动。

#### Acceptance Criteria

1. WHEN 用户点击 @ 按钮 THEN System SHALL 显示用户搜索面板
2. WHEN 用户在搜索面板中输入关键词 THEN System SHALL 实时搜索匹配的用户
3. WHEN 用户选择一个用户 THEN System SHALL 在光标位置插入 @用户名 格式的文本
4. WHEN 用户在输入框中输入 @ 符号 THEN System SHALL 自动触发用户搜索面板
5. WHEN 评论提交时 THEN System SHALL 将 @用户 转换为富文本格式，包含用户 ID 信息
6. WHEN 用户可以选择多个用户进行 @ THEN System SHALL 支持批量插入多个 @用户

### Requirement 3

**User Story:** 作为用户，我想要在评论中插入视频进度，以便指出视频中的特定时间点。

#### Acceptance Criteria

1. WHEN 用户点击插入视频进度按钮 THEN System SHALL 获取当前视频播放位置
2. WHEN 获取到播放位置后 THEN System SHALL 在光标位置插入格式化的时间戳文本（如 "01:23"）
3. WHEN 评论提交时 THEN System SHALL 将时间戳转换为富文本格式，包含视频链接信息
4. WHEN 其他用户点击评论中的时间戳 THEN System SHALL 跳转到对应的视频时间点

### Requirement 4

**User Story:** 作为用户，我想要在评论中插入视频截图，以便分享视频中的精彩画面。

#### Acceptance Criteria

1. WHEN 用户点击插入截图按钮 THEN System SHALL 捕获当前视频画面
2. WHEN 截图捕获成功后 THEN System SHALL 将截图添加到图片列表中
3. WHEN 截图添加后 THEN System SHALL 在评论输入区域上方显示截图缩略图
4. WHEN 用户发送评论 THEN System SHALL 将截图作为普通图片上传并提交

### Requirement 5

**User Story:** 作为用户，我想要在评论中插入视频或专栏链接，以便分享相关内容。

#### Acceptance Criteria

1. WHEN 用户点击插入视频/专栏按钮 THEN System SHALL 显示内容搜索面板
2. WHEN 用户在搜索面板中输入关键词 THEN System SHALL 搜索匹配的视频或专栏
3. WHEN 用户选择一个内容 THEN System SHALL 在光标位置插入内容链接的富文本格式
4. WHEN 评论提交时 THEN System SHALL 将内容链接转换为富文本格式，包含内容 ID 和类型信息
5. WHEN 其他用户点击评论中的内容链接 THEN System SHALL 跳转到对应的视频或专栏页面

### Requirement 6

**User Story:** 作为用户，我想要使用表情来丰富我的评论内容，以便更生动地表达情感。

#### Acceptance Criteria

1. WHEN 用户点击表情按钮 THEN System SHALL 显示表情选择面板
2. WHEN 用户选择文本表情 THEN System SHALL 在光标位置插入表情文本（如 "[doge]"）
3. WHEN 用户选择图片表情 THEN System SHALL 在光标位置插入表情占位符，并记录表情信息
4. WHEN 评论提交时 THEN System SHALL 将表情转换为富文本格式
5. WHEN 表情面板显示时 THEN System SHALL 隐藏系统键盘
6. WHEN 用户点击键盘按钮 THEN System SHALL 隐藏表情面板并显示系统键盘

### Requirement 7

**User Story:** 作为用户，我想要通过工具栏快速访问各种评论功能，以便高效地编辑评论。

#### Acceptance Criteria

1. WHEN 评论输入框获得焦点 THEN System SHALL 在底部显示工具栏
2. WHEN 工具栏显示时 THEN System SHALL 包含键盘、表情、@、更多等按钮
3. WHEN 用户点击更多按钮 THEN System SHALL 显示更多功能面板，包含图片、视频进度、截图等功能
4. WHEN 用户在不同面板间切换 THEN System SHALL 平滑过渡，保持面板高度一致
5. WHEN 用户点击键盘按钮 THEN System SHALL 关闭当前面板并显示系统键盘
6. WHEN 系统键盘显示时 THEN System SHALL 自动调整面板高度以匹配键盘高度

### Requirement 8

**User Story:** 作为用户，我想要实时预览我的富文本评论内容，以便确认评论的最终效果。

#### Acceptance Criteria

1. WHEN 用户输入文本 THEN System SHALL 实时更新评论预览
2. WHEN 用户插入表情 THEN System SHALL 在输入框中显示表情占位符或文本
3. WHEN 用户插入 @用户 THEN System SHALL 在输入框中高亮显示 @用户名
4. WHEN 用户添加图片 THEN System SHALL 在输入框上方显示图片缩略图列表
5. WHEN 评论内容为空且无图片 THEN System SHALL 禁用发送按钮
6. WHEN 评论内容不为空或有图片 THEN System SHALL 启用发送按钮

### Requirement 9

**User Story:** 作为用户，我想要评论提交过程有清晰的反馈，以便了解提交状态。

#### Acceptance Criteria

1. WHEN 用户点击发送按钮 THEN System SHALL 显示加载提示
2. WHEN 图片上传中 THEN System SHALL 显示 "正在上传图片..." 提示
3. WHEN 图片上传失败 THEN System SHALL 显示错误信息并停止提交
4. WHEN 评论提交成功 THEN System SHALL 显示成功提示并关闭评论面板
5. WHEN 评论提交失败 THEN System SHALL 显示错误信息并保留评论内容
6. WHEN 评论提交成功后 THEN System SHALL 将新评论添加到评论列表顶部

### Requirement 10

**User Story:** 作为开发者，我想要评论系统使用统一的富文本数据结构，以便于维护和扩展。

#### Acceptance Criteria

1. WHEN System 处理评论内容 THEN System SHALL 使用 RichTextItem 列表表示评论内容
2. WHEN RichTextItem 表示文本 THEN System SHALL 包含 type、text、range 字段
3. WHEN RichTextItem 表示表情 THEN System SHALL 包含 type、text、rawText、emote、range 字段
4. WHEN RichTextItem 表示 @用户 THEN System SHALL 包含 type、text、rawText、id、range 字段
5. WHEN RichTextItem 表示投票或其他特殊内容 THEN System SHALL 包含 type、text、rawText、id、range 字段
6. WHEN 评论提交时 THEN System SHALL 将 RichTextItem 列表转换为 API 要求的 JSON 格式

### Requirement 11

**User Story:** 作为用户，我想要评论输入框支持多行文本，以便编写较长的评论。

#### Acceptance Criteria

1. WHEN 用户输入文本 THEN System SHALL 自动扩展输入框高度以适应内容
2. WHEN 输入框高度超过最大限制 THEN System SHALL 显示滚动条
3. WHEN 输入框高度小于最小限制 THEN System SHALL 保持最小高度
4. WHEN 用户按下回车键 THEN System SHALL 插入换行符而不是提交评论
5. WHEN 用户点击发送按钮 THEN System SHALL 提交评论

### Requirement 12

**User Story:** 作为鸿蒙手机用户，我想要流畅使用评论功能，以便获得优质的移动端体验。

#### Acceptance Criteria

1. WHEN 用户使用触摸操作 THEN System SHALL 提供触摸友好的界面和反馈
2. WHEN 用户裁剪图片 THEN System SHALL 使用原生图片裁剪工具
3. WHEN 用户删除图片 THEN System SHALL 支持长按删除操作
4. WHEN 用户点击图片 THEN System SHALL 提供清晰的触摸反馈
5. WHEN 键盘弹出或收起 THEN System SHALL 平滑调整界面布局
6. WHEN 用户进行手势操作 THEN System SHALL 响应流畅无延迟
