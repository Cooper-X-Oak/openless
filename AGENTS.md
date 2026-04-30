# OpenLess Agent 规则

Scope: 本仓库。

## Windows 工作流职责边界

当前 Agent 工作流负责 `openless -all/app/` 下 Tauri 应用的 Windows 交付。

Windows-only 修复可以在 Windows 专属边界内推进，例如：

- `#[cfg(target_os = "windows")]` Rust 分支。
- `openless -all/app/scripts/` 下的 Windows 脚本。
- Windows CI、打包、运行时 smoke、Windows 文档。

修 Windows 问题时，不能静默改变 macOS 或 Linux 行为。

## 跨端变更护栏

除非已经证明不是共享面，否则以下内容都视为跨端共享面：

- `coordinator.rs` 会话状态机和快捷键边沿解释。
- `types.rs`、`commands.rs`、`lib.rs`、IPC 契约、React UI 行为。
- preferences、history、credentials、dictionary schema 和迁移逻辑。
- `package.json`、`Cargo.toml`、`tauri.conf.json`、发布 workflow、共享文档。

如果 Windows issue 必须修改共享代码，交付前必须做到：

1. 行为确实 Windows 专属时，优先使用平台门控。
2. 如果不能平台门控，必须说明为什么需要共享变更。
3. 在 issue 和 PR 里写清楚对 Windows、macOS、Linux 的预期影响。
4. 添加或明确点名保护非 Windows 行为的验证；无法验证时必须标出缺口。
5. 如果改动改变共享产品语义，合并前必须请求评审。

## Issue 和 PR 要求

Windows 工作流触碰的每个 issue 都必须包含“跨端影响评估”：

- 范围：`Windows-only`、`共享代码` 或 `不确定`。
- 影响端：Windows / macOS / Linux。
- 涉及的共享文件或契约。
- 验证计划和剩余缺口。

每个 PR 必须重复这份评估。如果判断不确定，不能把改动描述成 Windows-only。

## GitHub 网络策略

涉及 GitHub 的 git 网络操作（`push`、`pull`、`fetch`、`clone`、`ls-remote`）时，网络 workaround 必须临时、可逆：

1. 优先使用 command-scoped proxy。
2. 代理优先级：
   - `http://127.0.0.1:7897`
   - `http://127.0.0.1:7890`
   - `socks5://127.0.0.1:7891`
3. 除非用户明确要求，不要设置全局 git proxy。
4. 如果 GitHub remote 的 proxy 重试失败，再使用临时 SSH-over-443 fallback。
