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

仓库根执行，命令串与 `.pre-commit-config.yaml`、`.github/workflows/ci.yml` 同源：

```bash
stylua --check .                    # 格式（工具安装见 README“本地检查”节）
selene lua init.lua plugin scripts  # 静态检查（std 配置：selene.toml / vim.yml）
nvim -l scripts/verify-lockfile.lua # 锁与盘上 HEAD 一致，spec 图与锁双向覆盖
nvim -l scripts/test-meow.lua       # meow 纯函数单元测试
nvim -l scripts/check-docs-sync.lua # 文档与配置的命令串同源
```

headless 强测 smoke：事件触发加程序化补载拉起全部插件，错误消息、未载入与
fire 失败都由脚本 `cquit 1` 自判：

```bash
nvim --headless -c 'luafile scripts/strong-smoke.lua' -c 'qa!'
```

启动耗时闸门只在本机跑，判据为五次中位不超基线 1.5 倍加 20ms；换机或 Neovim
大版本升级后重定基线：

```bash
nvim -l scripts/startup-gate.lua           # 判定并打印各次耗时
nvim -l scripts/startup-gate.lua --update  # 重写 scripts/startup-baseline.json
```

钩子分三段：提交跑格式与静态检查，`commit-msg` 校验提交信息骨架，推送前跑
smoke、单元与锁校验。启用命令见 README“本地检查”节。

## 提交规范

Conventional Commits：`type(scope): 中文主题`，type/scope 小写 kebab-case；
一个提交一个逻辑变更、每个提交可独立 revert；style / fix / docs / ci 与
chore 不同 type 分开提交。骨架由 `commit-msg` 钩子校验，Merge、Revert、
fixup、squash、amend 豁免。

## 结构

文件地图见 README“结构”节。插件版本锁在 `lazy-lock.json`：更新走
`:Lazy update`（或 dashboard `l`、`<leader>l`），锁文件变更随插件变更一并提交；
他机拉取后的版本错位由启动对齐守卫提示 `:Lazy restore`。
