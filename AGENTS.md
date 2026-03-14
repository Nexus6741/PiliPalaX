# AGENTS.md

这个仓库主要是一个 Flutter 应用，根目录位于 `/Users/apple/Documents/PiliPalaX`。
请将此文件作为在此仓库中工作的编码代理的操作指南。

## 范围与仓库结构

- 除非任务明确指向某个子包，否则将仓库根目录的 `pubspec.yaml` 视为主应用。
- 仓库中还有一个位于 `pilipalax/` 的次级 Flutter 项目；除非任务明确指向它，否则不要修改。
- 本地插件与平台代码位于 `packages/`、`android/`、`ios/`、`linux/`、`macos/`、`windows/`、`ohos/` 和 `src/` 下。
- 应用大量使用 GetX 做状态管理和导航。
- 持久化使用 Hive 模型及其生成的适配器。

## Cursor / Copilot 规则

- 未发现 `.cursorrules` 文件。
- 未发现 `.cursor/rules/` 目录。
- 未发现 `.github/copilot-instructions.md` 文件。
- 如果之后新增了这些文件，请更新本文档，并将它们作为更高优先级的仓库指引来遵循。

## 工具链

- 首选 Flutter 入口命令：`fvm flutter`。
- `.fvmrc` 指向 `custom_3.32.4`。
- 已验证的本地 SDK：Flutter `3.32.4-ohos-0.0.1`，Dart `3.8.1`。
- 本项目当前以 HarmonyOS / OHOS 为主要目标平台，命令说明应优先使用鸿蒙版 Flutter 工作流。
- 当前环境中不可直接使用裸 `flutter` 命令，因此通常应写成 `fvm flutter`。
- 鸿蒙工具链通常还依赖 DevEco Studio 提供的 `ohpm`、`hvigor` 与 `node`；涉及 `ohos/` 构建链路时要考虑这些前置依赖。
- 根级分析器配置通过 `analysis_options.yaml` 引入了 `package:flutter_lints/flutter.yaml`。

## 安装 / 初始化

- 为主应用拉取依赖：
  - `fvm flutter pub get`
- 如涉及 HarmonyOS 原生依赖或 `ohos/` 构建链路，按需在对应目录执行：
  - `ohpm install`
- 为你修改的子包拉取依赖：
  - `cd packages/media_kit_video && fvm flutter pub get`
  - `cd packages/flutter_volume_controller_oh && fvm flutter pub get`
- `ohos/package.json` 中存在 OHOS 专用的 JS 依赖；只有在处理 OHOS 工具链相关工作时才修改它。

## 核心命令

- 检查 Flutter 与 OpenHarmony 环境：
  - `fvm flutter doctor -v`
- 查看已连接真机 / 设备：
  - `fvm flutter devices`
- 分析主应用：
  - `fvm flutter analyze`
- 格式化 Dart 文件：
  - `dart format lib test packages`
- 运行根目录全部测试：
  - `fvm flutter test`
- 以 debug 模式运行到真机：
  - `fvm flutter run --debug -d <deviceId>`
- 运行单个测试文件：
  - `fvm flutter test test/widget_test.dart`
- 运行单个文件中的指定测试：
  - `fvm flutter test test/widget_test.dart --plain-name "Counter increments smoke test"`
- 运行某个子包中的测试：
  - `cd packages/media_kit_video && fvm flutter test`
- 分析某个子包：
  - `cd packages/media_kit_video && fvm flutter analyze`

## 构建命令

- 构建 HarmonyOS debug HAP：
  - `fvm flutter build hap --debug`
- 构建 HarmonyOS release HAP：
  - `fvm flutter build hap --release`
- 按目标架构构建 HarmonyOS release HAP：
  - `fvm flutter build hap --release --target-platform ohos-arm64`
- 构建 HarmonyOS app 包：
  - `fvm flutter build app --release`
- 安装 HAP 到指定真机：
  - `fvm flutter install -t <deviceId> <hapFilePath>`
- 如当前自定义 OHOS SDK 保留兼容封装命令，某些场景下也可能使用：
  - `fvm flutter build ohos`
- 默认 HAP 构建产物通常位于：
  - `ohos/entry/build/default/outputs/default/`
- CI 工作流也会在注入版本后重命名构建产物；参见 `.github/workflows/CI.yml` 与 `.github/workflows/main.yml`。
- 如果任务涉及发布自动化，在修改构建行为前先检查这些工作流文件。

## 生成代码 / Build Runner

- 仓库中存在 Hive 适配器和其他代码生成产物。
- 当模型发生变化并影响到生成文件时，运行：
  - `dart run build_runner build --delete-conflicting-outputs`
- 除非任务明确要求，否则不要手动编辑生成的 `*.g.dart` 文件。

## 测试指引

- 当前根目录下唯一纳入版本控制的测试是 `test/widget_test.dart`，而且看起来仍然是 Flutter 默认的计数器烟雾测试。
- 不要假设现有测试对真实应用提供了有意义的覆盖率。
- 在新增或修复行为时，如可行，应补充有针对性的测试，而不是依赖默认烟雾测试。
- 迭代时优先运行文件级或名称级的精确测试，再视情况扩大到更广的相关测试集。
- 对于 widget 测试，保持初始化尽可能小；若存在更小的切入点，避免拉起无关服务。

## 架构约定

- UI 页面通常位于 `lib/pages/<feature>/`。
- 每个功能常见的文件三件套是 `controller.dart`、`view.dart`，有时还会有 `index.dart`。
- Controller 通常继承自 `GetxController`；在需要时会加上 ticker mixin。
- 导航集中定义在 `lib/router/app_pages.dart` 中，使用 `GetPage` / 自定义路由包装。
- 共享服务位于 `lib/services/`。
- 共享工具位于 `lib/utils/`。
- 数据模型位于 `lib/models/`，有时也在 `lib/models_new/`。

## 导入

- 遵循周围文件的写法，而不是强行把新的导入风格带进旧代码。
- 常见的导入分组模式是：
  - 先 Dart SDK 导入。
  - 再 package 导入。
  - 最后 relative 导入。
- 如果文件本来就在导入分组之间留空行，请继续保持。
- 应用中同时使用 `package:PiliPalaX/...` 和相对导入；请匹配你所修改文件的本地惯例。
- 除非本次修改确有需要，否则尽量不要重排大型已有 import 块。

## 格式化

- 对修改过的 Dart 文件使用 `dart format`。
- 保持代码兼容标准 Dart 格式化，不要做会被格式化器撤销的手工对齐。
- 在能改善 Flutter widget 排版和多行 diff 可读性时，优先使用尾随逗号。
- 保持行长度对格式化器友好，而不是与格式化器对抗。
- 如果文件存在现有编码上的特殊情况，请保留；部分文件包含 BOM。

## 类型

- 对字段、controller 依赖和不明显的局部变量优先使用显式类型。
- 对于从初始化值就能明显看出类型的短生命周期局部变量，`var` 是可以接受的。
- 默认使用 `final`；只有在生命周期初始化确有需要时才使用 `late`。
- 模型解析中常见可空类型；请保持空安全语义显式明确。
- 许多 API 响应仍使用 `Map<String, dynamic>` 或宽松的 `Map` 表示；不要顺手过度重构无关区域。
- 在新增解析逻辑时，如可行，优先使用类型化模型，至少也应使用 `Map<String, dynamic>` 而不是原始 `Map`。

## 命名

- 文件和目录使用 `snake_case`。
- Widget、controller、service 和 model 使用 `PascalCase`。
- 私有成员使用前导下划线。
- GetX 响应式状态通常使用具描述性的名词加 `.obs`，例如 `statusQRCode`、`smsSendCooldown`、`videoList`。
- 路由名使用诸如 `'/video'`、`'/searchResult'` 和 `'/setting'` 这样的字符串字面量；新增路由请保持同类命名风格。

## 状态管理

- GetX 是这里的默认模式。
- Controller 常通过 `Get.put(...)` 创建，并通过 `Get.find<...>()` 获取。
- 响应式值通常使用 `Rx<Type>`、`RxBool`、`RxInt`、`RxList<T>` 和 `Obx`。
- 在同一功能中，优先扩展现有 controller 模式，而不是再引入第二套状态管理方案。

## 错误处理

- 对网络、存储和平台调用，在预期可能失败时使用 `try/catch` 包裹。
- 当代码中已有更具体的异常类型时，优先使用它们，例如 `on DioException catch (e)`。
- 面向用户的失败通常通过 `SmartDialog.showToast(...)` 或 `SmartDialog.showNotify(...)` 呈现。
- 代码库中已经存在用于尽力清理路径的静默 `catch (_) {}`；除非失败确实无关紧要，否则不要继续扩散这种模式。
- 在 controller 或 widget 生命周期代码中，务必在 `onClose` / `dispose` 中清理定时器、监听器和控制器。

## Flutter / UI 风格

- 在可行时使用 `const` 构造函数；代码库中已经较为常见。
- 当某个代码块变得难以阅读时，保持 widget 小而清晰，但不要无谓地拆分文件。
- 在发明新抽象之前，先匹配现有的 GetX + Flutter 页面结构。
- 如果 `lib/common/` 下已经有相似模式的通用 widget，优先复用。
- 除非该功能本身已经使用固定品牌色，否则优先使用感知主题和配色方案的 UI，而不是硬编码颜色。

## 模型与持久化

- 基于 Hive 的模型使用诸如 `@HiveType` 和 `@HiveField` 的注解，并带有 `part '<name>.g.dart';`。
- JSON 解析大多通过 `fromJson` 构造函数或 factory 完成。
- 必须精确保留现有 JSON 键映射，包括 snake_case 的 API 字段名。
- 不要修改现有模型的 Hive `typeId` 值。

## 完成前需要验证的内容

- 如果只修改了主应用中的 Dart 代码：运行 `dart format <edited files>` 和 `fvm flutter analyze`。
- 如果是测试相关工作：先运行最精确相关的 `fvm flutter test ...` 命令，再在合适时扩大范围。
- 如果修改了某个子包：在该子包目录下运行 analyze/test，并同时运行受影响的根级检查。
- 如果涉及发布 / 构建变更：使用相关的 `fvm flutter build ...` 命令验证，或说明为何未运行完整构建。
- 每次代码修改任务结束后，默认还应执行 `fvm flutter run --release` 将当前版本部署到真机；如果当下无法连接真机或环境不允许部署，需要在最终说明里明确写出原因。

## 代理备注

- 工作树中可能已经存在与当前任务无关的用户修改；不要回退它们。
- 优先做与周边代码风格一致的小而精确的改动。
- 除非属于任务范围，否则不要“顺手修复”大范围的风格不一致问题。
- 如果修改 `ohos/` 或 `src/` 下生成的插件 / 平台文件，先确认它们究竟是源码真源还是构建产物。

<!-- OCR:START -->
# Open Code Review 说明

以下说明适用于在本项目中处理代码审查的 AI 助手。

当请求满足以下任一情况时，始终打开 `.ocr/skills/SKILL.md`：
- 请求代码审查、PR 审查，或对改动提供反馈
- 提到 “review my code” 或类似表述
- 希望对代码质量进行多视角分析
- 请求对大型变更集进行映射、整理或导航

使用 `.ocr/skills/SKILL.md` 来了解：
- 如何运行 8 阶段审查流程
- 如何为大型变更集生成 Code Review Map
- 可用的 reviewer persona 及其关注点
- 会话管理与输出格式

请保留这个受管区块，以便 `ocr init` 之后可以刷新这些说明。

<!-- OCR:END -->
