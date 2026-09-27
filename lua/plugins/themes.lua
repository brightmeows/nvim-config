-- 主题插件清单：基线 all-themes.lua 的镜像（全部预装、lazy=true + priority，
-- 零安装切换；触发形态见 e6b27cf 的 lua/plugins/all-themes.lua）。
-- name/branch 特例必须与 Omarchy 生成的 theme spec 一致
-- （default/themed/neovim.lua.tpl：aether 用 branch v3 + name aether，
-- rose-pine 的 URL 尾段是 neovim 需显式 name）。
return {
  { "https://github.com/ribru17/bamboo.nvim", lazy = true, priority = 1000 },
  { "https://github.com/bjarneo/aether.nvim", name = "aether", branch = "v3", lazy = true, priority = 1000 },
  { "https://github.com/bjarneo/ethereal.nvim", lazy = true, priority = 1000 },
  { "https://github.com/bjarneo/hackerman.nvim", lazy = true, priority = 1000 },
  { "https://github.com/bjarneo/vantablack.nvim", lazy = true, priority = 1000 },
  { "https://github.com/bjarneo/white.nvim", lazy = true, priority = 1000 },
  { "https://github.com/ellisonleao/gruvbox.nvim", lazy = true, priority = 1000 },
  { "https://github.com/rebelot/kanagawa.nvim", lazy = true, priority = 1000 },
  { "https://github.com/tahayvr/matteblack.nvim", lazy = true, priority = 1000 },
  -- 上游 gthelding/monokai-pro.nvim 已删（基线 URL 现 404），
  -- 同 commit 存在于原仓库 loctvl842/monokai-pro.nvim
  { "https://github.com/loctvl842/monokai-pro.nvim", lazy = true, priority = 1000 },
  { "https://github.com/EdenEast/nightfox.nvim", lazy = true, priority = 1000 },
  { "https://github.com/rose-pine/neovim", name = "rose-pine", lazy = true, priority = 1000 },
  { "https://github.com/ficcdaf/ashen.nvim", lazy = true, priority = 1000 },
  { "https://github.com/OldJobobo/miasma.nvim", lazy = true, priority = 1000 },
  { "https://github.com/OldJobobo/retro-82.nvim", lazy = true, priority = 1000 },
  { "https://github.com/omacom-io/lumon.nvim", lazy = true, priority = 1000 },
  { "https://github.com/neanias/everforest-nvim", lazy = true, priority = 1000 },
  { "https://github.com/kepano/flexoki-neovim", lazy = true, priority = 1000 },
}
