# 迁移验收清单：LazyVim → 纯 vim.pack

逐项核对迁移前（基线 `e6b27cf`，LazyVim 16.0.0 + 51 锁定插件）与迁移后的行为差异。
每项须判定为“一致”方可打勾；无法一致的项须在此文档标注理由并经确认。

对照物（本机在档）：

- LazyVim 源码：`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/`
- 基线配置：`git -C ~/.config/nvim show e6b27cf`
- 基线启动数据：见“性能”节

## 一、启动与架构

- [ ] `nvim --headless -c qa` 退出码 0，无错误输出
- [ ] 启动无 lazy.nvim / LazyVim 相关报错、无 NEWS 提示
- [ ] `vim.pack` 插件清单与 `nvim-pack-lock.json` 一致（CI lockfile 测试覆盖）
- [ ] `:Lazy` 无此命令属预期；等效入口见 keymaps 节 `<leader>l` 项
- [ ] LazyFile 懒加载语义消失（原事件组 `BufReadPost/BufNewFile/BufWritePre`，vim.pack 全量加载）：
  验证打开新文件/新 buffer 时 gitsigns、trouble、todo-comments 等原 LazyFile 件行为不回归

## 二、全局选项

来源：LazyVim `config/options.lua`（118 行）+ 基线 `lua/config/options.lua` 覆盖项。

- [ ] `mapleader = " "`、`maplocalleader = "\"`
- [ ] `autoformat = false`（基线覆盖项，保存不自动格式化）
- [ ] `relativenumber = false`（基线覆盖项）
- [ ] remote_clipboard 在 options 加载早期生效（`vim.g.clipboard` 设定）
- [ ] 基线选项全表逐项一致：`autowrite`、`clipboard`（SSH 时空）、`completeopt`、
  `conceallevel=2`、`confirm`、`cursorline`、`expandtab`、`fillchars`、`foldlevel=99`、
  `foldmethod=indent`、`grepformat`/`grepprg=rg`、`ignorecase`、`inccommand`、
  `laststatus=3`、`linebreak`、`list`、`number`、`pumheight=10`、`scrolloff=4`、
  `sessionoptions`、`shiftwidth=2`、`showmode=false`、`sidescrolloff=8`、
  `signcolumn=yes`、`smartcase`、`smartindent`、`smoothscroll`、`splitbelow/right`、
  `tabstop=2`、`termguicolors`、`timeoutlen=300`、`undofile`、`undolevels=10000`、
  `updatetime=200`、`virtualedit=block`、`wrap=false` 等（完整清单以基线文件为准）
- [ ] `statuscolumn` 与 `formatexpr` 的 LazyVim 函数依赖已替换为等效实现或移除且无报错
- [ ] snacks scroll 动画关闭（基线覆盖件 `snacks-animated-scrolling-off.lua`：`opts.scroll.enabled = false`；仅禁滚动动画，非全局 animate 开关）

## 三、自动命令

来源：LazyVim `config/autocmds.lua`（131 行）。

- [ ] checktime（FocusGained/TermClose/TermLeave）
- [ ] highlight on yank（TextYankPost）
- [ ] VimResized 自动等分窗口
- [ ] BufReadPost 回到最后编辑位置（gitcommit 除外）
- [ ] 关闭类 filetype 用 `q` 退出（help、qf、notify、checkhealth 等清单）
- [ ] man 文件不入 buffer 列表
- [ ] text/markdown/gitcommit 自动 wrap + spell
- [ ] json/jsonc conceallevel=0
- [ ] BufWritePre 自动创建父目录

## 四、Keymaps

来源：LazyVim `config/keymaps.lua`（215 行）+ `plugins/extras/editor/snacks_picker.lua` + `plugins/editor.lua` + `plugins/extras/editor/neo-tree.lua`。
以下按域分组，组内逐键核对（键位、模式、行为、desc）。

- [ ] 方向键 `gj`/`gk` 修正、`<C-hjkl>` 窗口导航、`<C-Up/Down/Left/Right>` 调整窗口
- [ ] `<A-j/k>` 移动行（n/i/v 三模式）、`<S-h/l>` 与 `[b/]b` 切 buffer
- [ ] buffer 组：`<leader>bb`、`<leader>` + 反引号、`<leader>bd`、`<leader>bo`、`<leader>bi`、`<leader>bD`
- [ ] `<esc>` 智能退出（清除搜索高亮）、`<C-s>` 保存、`<leader>K`、visual `<`/`>` 重选
- [ ] toggle 组：`<leader>uf/uF/us/uw/uL/ud/ul/uc/uA/uT/ub/ud/ua/ug/uS/uh/uz/uZ`（snacks toggles）
- [ ] 调试组：`<leader>dpp/dph`（profiler）
- [ ] git 组：`<leader>gg/gG/gL/gb/gf/gl/gB/gY`
- [ ] picker 组：`<leader>, / / : <space> n`、`fb/fB/fc/ff/fF/fg/fr/fR/fp`、
  `gd/gD/gs/gS/gi/gI/gp/gP`、`sb/sB/sg/sG/sp/sw/sW`、`sa/sc/sC/sd/sD/sh/sH/si/sj/sk/sl/sM/sm/sr/sq/su`、`ss/sS/st/sT`、`uC`
- [ ] neo-tree 组：`<leader>fe/fE/e/E/ge/be`
- [ ] flash 组：`s/S/r/R`（n/x/o 模式）、`<C-s>`（命令模式 toggle）
- [ ] trouble 组：`<leader>xx/xX/cs/cS/xL/xQ/xt/xT`、`[q/]q`
- [ ] todo 组：`[t/]t`
- [ ] grug-far：`<leader>sr`（n/x 模式，打开搜索替换并预填当前扩展名）
- [ ] window 组：`<leader>-/|`、`<leader>wd`、`<leader>wm`、`<leader>uz`
- [ ] tab 组：`<leader><tab>l/o/f/<tab>/]/d/[`
- [ ] 杂项：`<leader>ur`、`<leader>K`、`<leader>fn`、`<leader>xl/xq`、`<leader>cf`（强制格式化）、
  `<leader>cd`（行内诊断浮动）、`[d/]d/[e/]e/[w/]w`（诊断跳转）、
  `<leader>qq`、`<leader>ui/uI`、`<leader>fT/ft`、`<c-/>` 终端
- [ ] `<leader>l`：原为 `:Lazy`——迁移后改为等效插件管理入口（`vim.pack.update()` 确认缓冲），desc 同步更新
- [ ] `<leader>L`：原为 LazyVim changelog——确认保留（打开 Neovim news）或标注移除理由
- [ ] `<localleader>r`（lua 文件运行）
- [ ] which-key 分组标签与基线一致（`<leader>f` = file/find、`<leader>g` = git、`<leader>s` = search、`<leader>x` = diagnostic、`<leader>u` = ui、`<leader><tab>` = tab）
- [ ] LazyVim 专有 keymap 引用（`LazyVim.root`、`LazyVim.pick`、`Snacks.lazygit` 等）已替换为直调且行为一致

## 五、LSP 与补全

- [ ] mason 管理 lua-language-server、shfmt、stylua（迁移不波及，验证 `:Mason` 可开、`lua-language-server` 可用）
- [ ] `nvim-lspconfig` + `mason-lspconfig` 自动 enable 已装 server（lua_ls 对 `*.lua` 生效）
- [ ] LSP keymaps（来源 `plugins/lsp/init.lua` 的 `keys` 表）：`gd/gr/gI/gy/gD`、`K/gK`、
  插入模式 `<C-k>`、`<leader>ca/cc/cC/cR/cr/cA/cl`、`]]/[[` 与 `<a-n>/<a-p>`（words 跳转，
  依赖 documentHighlight 能力检测）；含 `has` 条件的项在 lua_ls 下逐个确认生效
- [ ] LSP 行为默认项：inlay hints 开启（lua_ls 支持时可见）、codelens 关、
  folds（`vim.lsp.foldexpr`）按能力自动开、diagnostics（underline、virtual_text `●` 前缀、
  `source=if_many`、severity_sort、signs 图标）与基线一致
- [ ] LSP 根检测（`root_spec = { "lsp", { ".git", "lua" }, "cwd" }`）等效——snacks root 或自实现
- [ ] blink.cmp 补全：`<C-Space>` 手动触发、Enter/Tab 确认行为与基线一致
- [ ] friendly-snippets 片段源加载（输入 `for`/`if` 等有片段建议）
- [ ] lazydev 对 lua 配置文件的库补全（`vim.*`、snacks 库提示）
- [ ] 诊断显示（virtual_lines/signs 配置与基线一致，`<leader>cd` 行内诊断浮动）

## 六、格式化与 Lint

- [ ] conform：lua → stylua、sh → shfmt、`<leader>cF` 注入格式化
- [ ] `autoformat = false` 下保存不触发格式化；手动 `:lua vim.lsp.buf.format()` 或 `<leader>cf` 可用
- [ ] nvim-lint：事件（BufWritePost/BufReadPost/InsertLeave）触发机制保留（基线仅配 fish，低风险）
- [ ] `<leader>cf`（格式化入口，snacks/LazyVim format 注册等效替代）

## 七、Treesitter

- [ ] nvim-treesitter main 分支安装器独立工作（不依赖插件管理器）
- [ ] 已装 parser 列表与基线一致（迁移后 `:TSUpdate` 不报错）
- [ ] incremental selection（`<C-CR>` 起始键）、highlight、indent 生效
- [ ] nvim-treesitter-textobjects（mini.ai treesitter 对象依赖）、nvim-ts-autotag 生效

## 八、UI 组件

- [ ] lualine 状态栏（含 trouble 文档符号集成 `vim.g.trouble_lualine`；
  更新计数组件 `  N`——基线 lazy.status/checker 闭环的等效复刻，
  meow.packcheck 每小时后台检查、notify=false 仅经 lualine 呈现，
  实测 49 件 18s 查毕 count=15 与上游真实待更新数吻合，钉 tag 件不误报）
- [ ] bufferline tabline（`<S-h>/<S-l>` 切换、分隔符与主题适配；`<leader>bp/bP/br/bl/bj` pin 与分组操作）
- [x] 启动 dashboard（snacks dashboard）：预设头图与按键项 `f/n/g/r/c/s/p/l/q` 可用；
  逐项定案：`x`（`:LazyExtras`）移除（extras 概念随发行版消失，无等效物）、
  `l`（`:Lazy`）改为 `vim.pack.update()`、`p`（Projects，snacks_picker extra 原有项）保留。
  startup 页脚（"Neovim loaded X/Y plugins in Zms"）依赖 lazy.stats——以 init.lua
  顶部的兼容垫片提供等效数据（count/loaded 取 vim.pack 托管数、startuptime
  VimEnter 固化）。
  验证：伪 TUI（script 分配 PTY）两次实测 dashboard 打开、无 UIEnter/lazy.stats
  报错、页脚格式与基线一致（headless 无 UIEnter，此路径 CI smoke 不覆盖，
  以本机伪 TUI 实测为准）
- [ ] noice：`<leader>snl/snh/sna/snd/snt` 消息历史与清除、`<leader>un` 关闭全部通知
- [ ] which-key 弹窗与分组（timeoutlen=300 下触发正常）
- [ ] noice 消息/cmdline/命令行签名
- [ ] snacks：notify、terminal（`<leader>fT/ft`）、indent、输入框等 setup 项与基线一致
- [ ] gitsigns：行号栏 sign、`[h/]h/[H/]H` hunk 导航、`<leader>gb` blame 行
- [ ] todo-comments、trouble、persistence（`<leader>qs/qS/ql/qd` 会话恢复）、ts-comments（`gc` 注释）
- [ ] snacks 杂项：`<leader>.`（scratch 缓冲）、`<leader>S`（选 scratch）、`<leader>dps`；
  terminal 内 `<C-hjkl>` 窗口导航与 `<C-/>` 隐藏
- [ ] mini.pairs（自动配对）、mini.ai（`af/if` 等对象扩展）、mini.icons（图标）
- [ ] neo-tree 文件树：`<leader>e` 打开、git_status/buffers 源、`l/h` 导航、`Y/O/P` 映射
- [ ] snacks picker：`<leader>ff` 文件查找、`<leader>/` grep（root 感知基于 root 检测）
- [ ] flash 跳转：`s` 跳转、`S` treesitter 范围跳转

## 九、主题与 Omarchy 耦合

- [ ] 启动即应用当前主题（catppuccin，经解析器读取 `~/.local/state/omarchy/current/theme/neovim.lua`）
- [ ] 解析器断言兜底：故意破坏 spec 文件时报错不静默
- [ ] 热重载：`omarchy theme set <other>` 后 running nvim 即时跟随（切回原主题同验）
- [ ] 连续切换 10 次无漏事件（父目录 watch + rearm 时序验证）
- [ ] 热重载后透明度重应用（`transparency.lua` 重 source，Normal 等组背景透明）
- [ ] 25 个主题插件在切换时可加载（含 aether 系通用主题 opts 注入）
- [ ] `User LazyReload` 事件源已消失，确认无残留监听依赖

## 十、自定义件

- [ ] remote_clipboard：本地 Wayland 下 copy 走 wl-copy、paste 走 wl-paste
- [ ] remote_clipboard：tmux 会话内 copy 触发 OSC 52（tmux buffer 重播）
- [ ] remote_clipboard：SSH 会话下 OSC 52 生效（`echo $TMUX`/`$SSH_TTY` 场景按实际可达者测）
- [ ] 无 tmux/SSH/herdr 时 `vim.g.clipboard` 不被覆盖（系统默认 clipboard）
- [ ] `plugin/after/transparency.lua` 每次启动生效
- [ ] options 中 `vim.g.omarchy_remote_clipboard_osc52` 开关保留

## 十一、性能

- [x] 基线数据（记录于基线提交日）：`--startuptime` 连续 6 次 `NVIM STARTED`：
  59.5 / 56.7 / 55.3 / 59.1 / 55.7 / 53.3 ms，中位约 56ms
  （首次单次读数 33ms 为热缓存态，仅作参考，不作基线）
- [x] 迁移后同法 6 次：164.1 / 163.0 / 170.0 / 165.6 / 161.1 / 159.2 ms，中位约 164ms
- [x] **结论（已裁决接受）**：2.9 倍超 112ms（基线 2 倍）红线，但绝对值 164ms
  低于 200ms 通用无感线，判据取绝对值可感性，决策记录为“接受现状”。
  根因：插桩实测 config 循环 109ms（LSP 域 48 / lualine 18 / blink 12 /
  bufferline 8.5），系基线的事件懒加载（BufReadPre/cmd/VeryLazy）在 vim.pack
  全量加载下前移至启动。曾评估并放弃 config 级延迟调度与按需 packadd
  （前者有依赖返工风险，后者与纯 vim.pack 架构裁决冲突）；
  若日后体感迟滞，复启该项优化（插桩脚本方法见 git 历史本节提交）

## 十二、质量闸门（步骤 7 落地后核对）

- [ ] 本地 `stylua --check` 全过
- [ ] 本地 `selene` 全过（存量告警清零）
- [ ] `.githooks/pre-commit` 安装并拦截过一次故意错误
- [ ] CI 四 job 全绿：stylua、selene、headless smoke、lockfile 全新安装测试
- [ ] lockfile 测试若因 headless 确认提示阻塞而降级为 smoke，须在 PR/提交信息中如实记录

## 十三、清理与交付

- [ ] starter 残留已清：`example.lua`、`.neoconf.json`、`lazyvim.json`、`lazy-lock.json`、旧 README
- [ ] LICENSE 为 Apache-2.0 且已补署名
- [ ] README 中文完稿：安装、跨机同步（clone → 重启装齐 → `vim.pack.update`）、hook 安装、主题耦合机制
- [ ] 全项打勾后删除 `~/.local/share/nvim/lazy/`（mason 不动），删后 nvim 正常启动
- [ ] `nvim-pack-lock.json` 已入库并推送
- [ ] 仓库 https://github.com/brightmeows/nvim-config 为 PUBLIC
