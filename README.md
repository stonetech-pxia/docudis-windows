# Docudis Desktop

Docudis 的 Windows 版（Flutter Desktop，同一份代码也能在 macOS 上运行）。在本机识别并匿名化文本、PDF、Word 文档和图片，不上传任何内容。功能基准是 [docudis-android](https://github.com/stonetech-pxia/docudis-android)，架构和待定事项见 [HANDOFF-windows-2026-10-01.md](HANDOFF-windows-2026-10-01.md)。

- 技术栈：Flutter 3.47 / Dart 3.13、Riverpod 3
- 界面语言：English、Español、Français、中文（默认跟随系统）
- 引擎：检测、合并、匿名化、还原、语言识别全部走 docudis-core，NER 走 docudis-ner（都是 Rust，经 C ABI 调用）。版本锁定在 [tool/native.lock.json](tool/native.lock.json)，Dart 绑定在 `pubspec.yaml` 里按同一个 commit 引用。

## 不联网、不上传

所有处理都在本机完成，没有账户、统计或崩溃上报。macOS 版运行在没有联网权限的 App 沙盒里，并有一个审计脚本记录 App 的全部网络活动。Windows 版由测试检查代码、依赖和打包的文件里没有联网的部分，并在运行中确认 App 没开任何网络连接；ONNX Runtime 从源码编译，不带遥测。具体承诺、数据存放位置、验证方法和审计结果见 [docs/network-audit.md](docs/network-audit.md)。

## Code signing policy

Windows 版由 GitHub Actions 从打了 tag 的源码构建，附 SHA-256 和构建来源证明；签名计划、会签哪些文件、团队角色和隐私声明见 [Code signing policy](docs/code-signing-policy.md)。

## 目前能做的

桌面式的界面，颜色沿用 Android 的 Clay：

- **工作区**（保护）：工具栏（新建 ⌘N、打开 ⌘O、粘贴 ⌘V、匿名化 ⌘↩、复制 ⌘⇧C、另存为 ⌘S、还原回复 ⌘R；Windows 上是 Ctrl），左栏原文、右栏匿名化结果、最右是检测结果列表，底部状态栏显示语言和模型。没打开记录时左栏就是编辑器，可以直接输入、粘贴，或把文件拖进窗口。
- 改遮盖：在检测结果里勾选或取消，或者直接点原文（点检测到的内容切换遮盖，点普通文字把那一段遮住），改动即时保存。
- 文件：txt、md、csv、docx、有文字层的 PDF；docx 和 PDF 会另外生成匿名化后的副本，用"另存为"保存。
- **还原回复**：单独一页，左边贴 AI 回复，右边是还原结果，并检查回复是否属于这份文档。
- **历史记录**：可排序的表格，点一行就在工作区里打开；侧边栏下方列出最近的文档。
- **词典**："总是遮住"和"从不遮住"两个列表并排，可以输入添加，也可以从"最近手动遮住 / 恢复显示的"推荐里一键加入；"只遮住这个列表"打开后只查列表里的词。在工作区的检测结果上点右键，也能直接加入两个列表。改动从下一份文档开始生效。
- **设置**：界面语言、记录保存位置（可在文件夹中打开）、清除本机数据、隐私政策、联系方式、版本号。没有账户的概念。
- 还没有：图片和扫描版 PDF（等 OCR 方案）、"发送到"AI 应用。PDF 里只要有一页没有文字层，就不生成 PDF 副本，只输出文字，避免扫描页未经遮盖就流出去。

## 目录结构

```text
lib/
  theme/              Clay 主题和组件（从 docudis-android 复制，尺寸改成桌面的；desk_widgets 是桌面新增的工具栏和面板）
  l10n/               ARB 文案（从 docudis-android 复制，加了桌面用的几条）
  home/               外层布局：宽窗口用侧边栏，窄于 720 px 时改用底部导航栏；每个标签页有自己的页面栈
  anonymize/
    engine/           原生库的位置、NER 模型加载
    input/ output/    文本提取，docx / PDF 匿名化副本
    storage/          历史记录（<app support>/records，和 Android 同样的格式，明文）
    ui/               工作区（原文、匿名化结果、检测结果）、还原、历史页面
packages/docudis_pdf/ PDF 匿名化（从 docudis-android 复制）
tool/                 原生库构建、模型安装、版本锁定、联网审计
docs/                 不联网、不上传的说明和审计结果，code signing policy
.github/workflows/    Windows 版的发布构建（GitHub Actions）
windows/  macos/      Flutter runner
```

界面代码是从 docudis-android 复制过来的，不和它共享包，桌面版可以自由改动。

## 开发（macOS，Apple 芯片）

第一次需要准备原生库和模型：

```bash
tool/prepare_native.sh
```

```bash
tool/fetch_models.sh
```

- `prepare_native.sh` 按锁定版本拉取并编译 docudis-core（带语言识别）和 docudis-ner，下载并校验 ONNX Runtime，产物放在 `build/native/macos/`，Xcode 构建时会复制进 `Docudis.app/Contents/Frameworks`。有本地 checkout 时可以用 `DOCUDIS_CORE_SOURCE=../docudis-core` / `DOCUDIS_NER_SOURCE=../docudis-ner` 省掉克隆（必须在锁定的 commit 上）。
- `fetch_models.sh` 把 NER 模型装到 App 沙盒容器里的 `~/Library/Containers/com.stonetech.docudis/Data/Library/Application Support/com.stonetech.docudis/models/`。容器由 macOS 在 App 第一次启动时创建，所以先 `flutter run -d macos` 打开一次再运行它。模型在公开的 Hugging Face 仓库，下载需要 `pip install huggingface_hub`；已经有模型文件时，先复制到这个目录，脚本校验 SHA-256 通过就不会重新下载。
- 可选模型 OpenAI Privacy Filter：`tool/fetch_models.sh openai_privacy_filter`（约 950 MB，加载后约 1.6 GB 内存，每 1000 字符约多 0.3 秒）。App 会加载 `models/` 下所有已安装的模型（目前是 `xlmr_ner_docudis` 和 `openai_privacy_filter`），把它们的结果一起交给 core 合并；没装就不加载。
- 没有模型时 App 照样能用，只是只跑规则和名单，并在页面上提示。

```bash
flutter test
```

```bash
flutter test integration_test/flow_test.dart -d macos
```

```bash
flutter run -d macos
```

集成测试用真实的原生库和模型跑完整流程（粘贴 → 匿名化 → 审阅 → 还原、词典、PDF、docx），记录和词典都写到临时文件夹，不碰本机真实数据。

说明：

- macOS 开着 App 沙盒。Release 版没有任何联网权限（Debug 版多一个 `network.server`，让 flutter 工具从本机连进来调试）；App 只能读写用户打开、拖进来或另存为的文件，以及自己的容器。本地运行不需要 Apple 开发者账号；正式对外发布 Mac 版才需要 Developer ID 签名和公证。
- ONNX Runtime 1.30 没有 Intel Mac 版本，目前只支持 Apple 芯片。

## 开发（Windows x64）

需要 Visual Studio 的"使用 C++ 的桌面开发"组件（含 CMake）、Rust 的 MSVC 工具链、Python 3，并在系统设置里打开**开发者模式**（Flutter 构建带插件的 App 需要创建符号链接）。第一次需要准备原生库：

```powershell
powershell -ExecutionPolicy Bypass -File tool\prepare_native.ps1
```

- 按锁定版本编译 docudis-core、docudis-ner 和 ONNX Runtime，产物放在 `build\native\windows\`（`docudis_capi.dll`、`docudis_ner_capi.dll`、`onnxruntime.dll`）。`windows\CMakeLists.txt` 在构建时把它们装到 `docudis.exe` 旁边；缺了就直接报错。App 按完整路径加载，避免拿到系统自带的旧版 `C:\Windows\System32\onnxruntime.dll`。
- ONNX Runtime 在 Windows 上从官方源码编译，加 `--no_telemetry`：官方发布的 Windows 版把事件登记在微软的遥测组里，创建环境时（在 ort 能关掉遥测之前）就会写下 CPU、内存、显卡驱动等信息，Windows 可能按用户的诊断数据设置上传。第一次编译要较长时间，之后复用 `build\native-cache\ort\` 里的结果；升级时改 `tool/native.lock.json` 里的 commit。`test/offline_test.dart` 会检查打包的文件都不在微软的遥测组里。
- 模型放在 `%APPDATA%\stonetech\Docudis\models\`。`tool/fetch_models.sh` 还不支持 Windows，可以直接调用锁定版本的 docudis-ner 里的脚本（`prepare_native.ps1` 跑过之后源码在 `build\native-cache\src\docudis-ner-<commit>\`）：`python <源码>\tool\fetch_models.py --dest $env:APPDATA\stonetech\Docudis\models`。

```powershell
flutter run -d windows
```

```powershell
flutter test integration_test/flow_test.dart -d windows
```

打包成解压即用的 zip（`build\package\docudis-<版本>-windows-x64.zip` 和它的 `.sha256`）：

```powershell
powershell -ExecutionPolicy Bypass -File tool\package_windows.ps1 -ModelsDir "$env:APPDATA\stonetech\Docudis\models"
```

- zip 里是 Release 版、三个原生库、Visual C++ 运行库（`windows\CMakeLists.txt` 一起装到 exe 旁边，没装过运行库的电脑也能打开）、LICENSE 和 NOTICE。
- `-ModelsDir` 把那个目录下的模型放进 zip 的 `models\`，App 在 `<app support>\models` 找不到时会读这里；不加就不带模型，App 只跑规则和名单。

## 在 Windows 上使用

1. 下载 `docudis-<版本>-windows-x64.zip`，核对 SHA-256 和发布页写的一致：`Get-FileHash docudis-<版本>-windows-x64.zip`。
2. 解压到任意位置，运行里面的 `docudis.exe`。不用安装，也不需要管理员权限，程序不改系统设置。
3. 程序没有代码签名，第一次打开时 Windows 可能提示"Windows 已保护你的电脑"：点"更多信息"，再点"仍要运行"。发布方式、签名计划和团队角色见 [Code signing policy](docs/code-signing-policy.md)。
4. 想让 Windows 防火墙也拦住它，可以选做一条规则，见 [docs/network-audit.md](docs/network-audit.md#用防火墙再加一道保险可选)。

### 卸载

1. 退出 Docudis，删掉解压出来的文件夹。
2. 删掉 `%APPDATA%\stonetech\Docudis\`：这里是记录（明文）、词典、设置和另外安装的模型。只想清掉记录，也可以先在设置里点"清除本机数据"。
3. 加过防火墙规则的，在管理员 PowerShell 里删掉它：`Remove-NetFirewallRule -DisplayName "Docudis - block outbound"`。

## 许可证

[GNU AGPL-3.0](LICENSE)，版权归 stonetech 所有，见 [NOTICE](NOTICE)。打包进 App 的 docudis-core 和 docudis-ner 原生库是 Apache-2.0。设置页的「开源许可」列出 App 所用第三方软件的许可证，由 `tool/generate_licenses.py` 生成。

## 参与

欢迎提 issue，但目前不接受代码 PR，见 [CONTRIBUTING.md](CONTRIBUTING.md)。
