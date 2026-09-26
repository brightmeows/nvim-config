-- mini.pairs：自动配对。行为源：LazyVim plugins/coding.lua 的 mini.pairs spec，
-- config 走 meow.mini.pairs（含 markdown 代码块与 skip 规则，以及 <leader>up toggle）。
return {
  src = "https://github.com/nvim-mini/mini.pairs",
  name = "mini.pairs",
  config = function()
    require("meow").mini.pairs({
      modes = { insert = true, command = true, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { "string" },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
    })
  end,
}
