# AGENTS.md

面向编码代理的仓库约定。权威源：[`README.md`](README.md)（架构、安装与平台口径）、
[`docs/acceptance.md`](docs/acceptance.md)（行为验收清单）——本文只指路，不复制其内容。

## 核心判据

- **零感知**：对 LazyVim 16.0 的行为复刻不得被破坏；任何可见行为差异都必须显式
  记录进 acceptance 清单并经确认。
- **行为源**：`lua/meow/`、`lua/plugins/` 中标注“行为源”的实现以 LazyVim 16.0
  对应代码为基准，改动保持语义等价；无法等价修复的（含仅在失败分支可见的差异）
  停手上报、由维护者裁决，不擅自偏离——规范层面的豁免优先于改写（定点内联
  `-- selene: allow(...)`，不扩规则级豁免）。
- **平台口径**：README 的支持声明是刻意的分级表述（Linux 实测、macOS/Windows
  由 CI smoke 覆盖启动路径），不得改写为“全平台支持”；无实机验证的承诺不写。
- **验收**：行为相关改动对照 `docs/acceptance.md` 逐项核对；依赖 CI 的条目以流水线
  首绿为准，不提前勾选。

## 验证命令

仓库根执行，命令串与 `.githooks/pre-commit`、`.github/workflows/ci.yml` 同源：

```bash
stylua --check .                    # 格式（工具安装见 README“本地检查”节）
selene lua init.lua plugin scripts  # 静态检查（std 配置：selene.toml / vim.yml）
nvim -l scripts/verify-lockfile.lua # 锁文件与盘上插件 git HEAD 一致性
```

headless 启动 smoke，判据为退出码 0 且输出不含 `Error`（允许 warning）：

```bash
nvim --headless -c 'lua vim.wait(2000, function() return false end, 50)' -c 'qa!'
```

提交 hook 启用一次即可（`git config core.hooksPath .githooks`）；未启用时提交前
显式跑上述检查。

## 提交规范

Conventional Commits：`type(scope): 中文主题`，type/scope 小写 kebab-case；
一个提交一个逻辑变更、每个提交可独立 revert；style / fix / docs / ci 与
chore 不同 type 分开提交。

## 结构

文件地图见 README“结构”节。插件版本锁在 `nvim-pack-lock.json`：更新走
`vim.pack.update()`，锁文件变更随插件变更一并提交。
