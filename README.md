# nvim-config

我的 Neovim 配置：`lazy.nvim` 驱动的自研配置（无 LazyVim 发行版），
行为上对 LazyVim 16.0 全量复刻（复刻范围与验收方式见
[`docs/acceptance.md`](docs/acceptance.md)）。

## 安装

前置：Neovim 0.12+、git、`rg`（`:grep` 与文件检索的硬依赖）；（可选）
`tree-sitter-cli` 0.26+ 与 C 编译器（treesitter parser 用）、`fd`（snacks
explorer 检索依赖）、`lazygit`（缺则相关键位自动隐藏）。

Linux / macOS：

```bash
git clone https://github.com/brightmeows/nvim-config.git ~/.config/nvim
nvim  # 首次启动克隆 lazy.nvim，按 lazy-lock.json 安装全部插件
```

Windows（PowerShell）：

```powershell
git clone https://github.com/brightmeows/nvim-config.git "$env:LOCALAPPDATA\nvim"
nvim  # 首次启动克隆 lazy.nvim，按 lazy-lock.json 安装全部插件
```

平台支持：三平台适配——Linux 实测日常使用；macOS / Windows 由 CI 的 headless
强测覆盖启动路径，欢迎反馈使用差异。

## 多机同步

插件版本锁在仓库内的 `lazy-lock.json`：

```bash
git -C ~/.config/nvim pull   # 他机拉取配置与锁文件
nvim                          # 新机首启按锁装齐；已装件由对齐守卫查错位
```

版本对齐：启动 30 秒后守卫比对锁与盘上各插件 HEAD，不一致时提示执行
`:Lazy restore`（lazy 启动只补缺失件、不回修错位件，守卫负责让错位可见）。

更新插件：在 nvim 内执行 `:Lazy update`（或 dashboard 的 `l`、`<leader>l`），
确认后将变更的 `lazy-lock.json` 提交回仓库。

## 本地检查

提交前钩子由 [pre-commit](https://pre-commit.com) 管理，定义在
`.pre-commit-config.yaml`（`repo: local` 全本地脚本，与 CI lint 同源）。
每台设备安装一次：

```bash
sudo pacman -S pre-commit stylua selene   # Arch；其它平台用上游发布包 / pip
cd ~/.config/nvim && pre-commit install   # 在配置目录内启用钩子
```

CI（GitHub Actions）以 `pre-commit run --all-files` 跑同一组 lint，另含
三平台 headless 强测 smoke 与 lockfile 全新安装测试。

## 结构

```
init.lua            入口：bootstrap lazy.nvim 并装载 lua/plugins/ 的 spec
                    （加载时序镜像 LazyVim 16.0）
lua/config/         全局选项、autocmd、keymaps、自定义件
lua/plugins/        每插件一个文件，返回 lazy spec + config
lua/meow/           自研工具层（行为源 LazyVim 16.0 util）
plugin/after/       启动期直接生效的钩子（透明主题）
scripts/            锁文件逐 rev 校验与强测 smoke（本地与 CI 共用）
docs/acceptance.md  行为验收清单
```

## Omarchy 主题耦合

Omarchy 切主题时重写 `~/.local/state/omarchy/current/theme/neovim.lua`（上游生成的
lazy.nvim spec 格式）。本配置用兼容解析器读取该文件提取 colorscheme 与主题插件
（缺字段断言报错，未预装插件报错跳过），并用 watch 父目录的 fs_event watcher
检测目录级替换（Omarchy 为 `rm -rf` + `mv` 原子切换），实现 running nvim 内的
即时热重载。

## License

[Apache-2.0](LICENSE)
