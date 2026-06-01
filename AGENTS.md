# openless-pr497-evidence-upload Rules

## 分支约定
- 前缀：feat/ fix/ docs/ refactor/ chore/ test/
- 命名：<type>/<topic> 或 <type>/<issue>-<topic>
- 当前归档分支：codex/pr497-evidence-20260519-083148

## 权威来源（冲突时以此为准）
- README.md（根目录）与 pr497-capsule-hitl/README.md
- pr497-capsule-hitl/meta.json（像素采样测量数据）

## 临时产物（永不提交）
- .scratch/ .temp/ .draft/ → 已 gitignore
- 凭证文件 *.env / cookies.txt / *.pem / *.key → 已 gitignore

## 验证 / 测试
- 无构建/运行步骤；这是证据归档，非可运行代码。
- 验证方式：直接打开 PNG 并核对 meta.json 中的像素采样。

## 代码约定
- pr497-capsule-hitl/ 为只读证据目录，内容对应 PR #497 的 HITL 视觉门禁。
