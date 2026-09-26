# nvim-config

我的 Neovim 配置：纯 `vim.pack`（Neovim 0.12 原生包管理）驱动，无 lazy.nvim、无 LazyVim，
行为上对 LazyVim 16.0 全量复刻（复刻范围与验收方式见 [`docs/acceptance.md`](docs/acceptance.md)）。

## 安装

前置：Neovim 0.12+、git、`rg`（`:grep` 与文件检索的硬依赖）；（可选）
`tree-sitter-cli` 0.26+ 与 C 编译器（treesitter parser 用）、`fd`（snacks
explorer 检索依赖）、`lazygit`（缺则相关键位自动隐藏）。

Linux / macOS：

```bash
git clone https://github.com/brightmeows/nvim-config.git ~/.config/nvim
nvim  # 首次启动按锁文件安装全部插件
```

Windows（PowerShell）：

```powershell
git clone https://github.com/brightmeows/nvim-config.git "$env:LOCALAPPDATA\nvim"
nvim  # 首次启动按锁文件安装全部插件
```

平台支持：三平台适配——Linux 实测日常使用；macOS / Windows 由 CI 的 headless
smoke 覆盖启动路径，欢迎反馈使用差异。

## 多机同步

插件版本锁在仓库内的 `nvim-pack-lock.json`：

```bash
git -C ~/.config/nvim pull   # 他机拉取配置与锁文件
nvim                          # 重启即按锁文件装齐对应版本
```

更新插件：在 nvim 内执行 `vim.pack.update()`，审阅确认缓冲后 `:write` 应用，
再将变更的锁文件提交回仓库。

## 本地检查

提交前 hook 跑 `stylua --check` 与 `selene`（安装一次即可）：

```bash
git -C ~/.config/nvim config core.hooksPath .githooks
```

CI（GitHub Actions）另跑 lint（与 hook 同命令）、三平台 headless 启动 smoke
与 lockfile 全新安装测试。

## 结构

```
init.lua            入口：vim.pack.add 装载 lua/plugins/ 下的全部插件 spec
lua/config/         全局选项、autocmd、keymaps、自定义件
lua/plugins/        每插件一个文件，返回 vim.pack spec + setup
plugin/after/       启动期直接生效的钩子（透明主题）
scripts/            锁文件与盘上 git HEAD 一致性校验（本地与 CI 共用）
docs/acceptance.md  行为验收清单
```

## Omarchy 主题耦合

Omarchy 切主题时重写 `~/.local/state/omarchy/current/theme/neovim.lua`（上游生成的
lazy.nvim spec 格式）。本配置用兼容解析器读取该文件提取 colorscheme 与主题插件
（缺字段断言报错），并用 watch 父目录的 fs_event watcher 检测目录级替换
（Omarchy 为 `rm -rf` + `mv` 原子切换），实现 running nvim 内的即时热重载。

## License

[Apache-2.0](LICENSE)
