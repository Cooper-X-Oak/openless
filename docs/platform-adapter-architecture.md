# OpenLess 桌面端平台适配架构

更新日期：2026-04-29

## 背景

Windows 真机回归暴露出一个架构问题：当前实现不是“一个清晰的 desktop core + 多个 native adapter”，而是把产品主链路、OS hook、平台能力判断和 UI 文案揉在一起。这样会导致两个后果：

- Windows 热键无响应时，只能看到 `Coordinator` 有没有收到事件，无法判断是 OS hook 没装上、按键映射不匹配、权限/前台限制，还是产品状态机吞掉了事件。
- 为了修 Windows 容易误删或替换 macOS 端已经工作的 CGEventTap 代码，形成跨平台回归风险。

后续方向不是做三个客户端，而是保留一套 Tauri + Rust native layer + TypeScript/React UI，并把平台差异限制在 adapter 层。

## 目标架构

```text
Layer 5  Extensions
         providers / app rules / dictionaries / templates

Layer 4  UI
         tray menu / recording indicator / review popover / settings / history / onboarding

Layer 3  Product core
         dictation session state machine / audio pipeline / ASR orchestration
         rewrite orchestration / text operation planner

Layer 2  Platform adapter layer
         Rust traits / TS IPC contracts / unified errors / capability matrix

Layer 1  Native system layer
         hotkey / audio / tray / clipboard / accessibility / UIA / X11 / Wayland / autostart
```

依赖方向必须单向：UI 调 product core，product core 调 adapter trait，adapter trait 再落到具体 OS 实现。平台实现不能反向影响 session 状态机和 provider 编排。

## Adapter 边界

第一批需要抽出来的 adapter：

| Adapter | 负责内容 | 不负责内容 |
|---|---|---|
| `HotkeyAdapter` | 安装/卸载全局监听，报告 pressed/released/cancelled，暴露安装状态和最后错误 | 决定录音状态、toggle/hold 语义 |
| `AudioAdapter` | 输入设备枚举、权限探测、短生命周期采集探测、stream 生命周期 | ASR 协议、会话保存 |
| `InsertionAdapter` | 当前光标插入、剪贴板 fallback、插入结果分类 | 润色、历史记录 |
| `AppContextAdapter` | 前台 app / window / text field 能力探测 | per-app 规则决策 |
| `TrayAdapter` | 托盘、菜单、打开窗口、退出 | 产品状态机 |
| `AutostartAdapter` | 开机启动读写、平台错误转换 | 设置页文案 |

共同约束：

- 所有 adapter 返回统一错误：`code`、`platform`、`operation`、`recoverable`、`user_message`、`debug_message`。
- 所有 adapter 暴露 capability：`supported`、`requires_permission`、`permission_name`、`fallback_available`。
- UI 只读 capability 和 status，不硬编码 macOS/Windows 权限文案。

## 热键专题

热键不能简单从 `rdev` 换成 `global-hotkey`，因为这两个模型不等价：

- 当前产品语义是“modifier-only trigger”：例如按住右 Option / 右 Control 开始，说完松开结束。
- 注册式全局快捷键通常是“modifier + 普通键”的 accelerator：例如 `Ctrl+Alt+Space`。它可以稳定注册，但不能自然表达“单独按住右 Control”。

因此 Windows 修复应拆成两个 adapter 策略，而不是删除 OS 端实现：

| 策略 | 适用语义 | Windows 路线 |
|---|---|---|
| `LowLevelKeyboardHookAdapter` | 右 Ctrl / 右 Alt 这种单 modifier 按住说话 | Win32 `SetWindowsHookExW(WH_KEYBOARD_LL)`，区分左右键，发 pressed/released 边沿 |
| `RegisteredShortcutAdapter` | 用户选择组合快捷键 | `global-hotkey` 或 Tauri shortcut 插件，作为显式 fallback |

UI 必须把两种能力分开显示：

- “按住右 Control 说话”：依赖 low-level hook，失败时显示 hook 状态和错误。
- “使用组合快捷键”：依赖 registered shortcut，作为 Windows 兼容 fallback，不应静默替代右 Control。

## 平台能力矩阵

| 能力 | macOS | Windows | Linux X11 | Linux Wayland |
|---|---|---|---|---|
| modifier-only hotkey | CGEventTap | Win32 low-level keyboard hook | XInput/XRecord 或等价 hook | best-effort，可能需要 portal/桌面环境支持 |
| registered shortcut | 可选 fallback | 可选 fallback | 可选 fallback | 依赖环境 |
| audio capture | CoreAudio/cpal | WASAPI/cpal + 真实 stream probe | ALSA/Pulse/cpal | PipeWire/Portal 依赖 |
| accessibility insertion | AX/CGEvent | UIA 优先，剪贴板 fallback | X11 automation + clipboard | clipboard fallback 优先 |
| app context | NSWorkspace/AX | Win32/UIA | X11 window metadata | portal/有限支持 |

## 测试分层

后续 CI 和真机回归要按层拆开，避免把“人工按快捷键”当作唯一证明。

| 层 | 自动化方式 | 验证目标 |
|---|---|---|
| Product core | Rust 单测或 debug IPC 注入 | `Coordinator` 收到 pressed/released 后状态机正确 |
| Hotkey adapter | Windows adapter smoke test | OS hook 安装成功，能接收合成/真实边沿事件，错误可观测 |
| UI/IPC | WebDriver / Playwright / Tauri driver | 设置项、状态 pill、凭据读写、错误文案正确 |
| End-to-end | Windows 真机脚本 + 少量人工验收 | 物理热键录音、真实 ASR、Notepad/浏览器插入 |

当前已有的 `OPENLESS_DEBUG_HOTKEY_ON_START` 只能证明 product core 链路，不证明 Windows OS hook。它应保留为 core test，但不能被当作 Windows 物理热键通过。

## 迁移顺序

1. 保留现有 macOS CGEventTap，不删除已工作的 OS 端代码。
2. 在 Rust 层定义 `HotkeyAdapter` trait 和 `HotkeyCapability` / `HotkeyInstallStatus`。
3. 把现有 macOS CGEventTap 包成 `MacHotkeyAdapter`。
4. 把现有 Windows/Linux `rdev` 包成 `LegacyRdevHotkeyAdapter`，只作为过渡实现。
5. 新增 Windows `LowLevelKeyboardHookAdapter`，优先解决右 Control 无响应。
6. 可选新增 `RegisteredShortcutAdapter`，作为用户可选 fallback。
7. UI 从 capability/status 渲染文案和选项，不再硬编码平台说明。
8. 再抽 `AudioAdapter`、`InsertionAdapter`、`AppContextAdapter`。

## 决策

Windows 热键修复主线要从“替换库”改成“adapter 化 + Win32 原生 hook”。`global-hotkey` 可以作为组合快捷键 fallback，但不能作为右 Control 按住说话的直接替代。
