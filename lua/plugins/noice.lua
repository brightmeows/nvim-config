-- noice：消息/cmdline UI。行为源：LazyVim plugins/ui.lua 的 noice spec。
return {
  src = "https://github.com/folke/noice.nvim",
  name = "noice.nvim",
  config = function()
    require("noice").setup({
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    })

    -- LazyVim ui.lua 的 noice keymaps
    local function ncmd(name, desc)
      return function()
        require("noice").cmd(name)
      end
    end
    vim.keymap.set("n", "<leader>sn", "", { desc = "+noice" })
    vim.keymap.set("c", "<S-Enter>", function()
      require("noice").redirect(vim.fn.getcmdline())
    end, { desc = "Redirect Cmdline", silent = true })
    vim.keymap.set("n", "<leader>snl", ncmd("last"), { desc = "Noice Last Message", silent = true })
    vim.keymap.set("n", "<leader>snh", ncmd("history"), { desc = "Noice History", silent = true })
    vim.keymap.set("n", "<leader>sna", ncmd("all"), { desc = "Noice All", silent = true })
    vim.keymap.set("n", "<leader>snd", ncmd("dismiss"), { desc = "Dismiss All", silent = true })
    vim.keymap.set("n", "<leader>snt", ncmd("pick"), { desc = "Noice Picker (Telescope/FzfLua)", silent = true })
    vim.keymap.set({ "i", "n", "s" }, "<c-f>", function()
      if not require("noice.lsp").scroll(4) then
        return "<c-f>"
      end
    end, { silent = true, expr = true, desc = "Scroll Forward" })
    vim.keymap.set({ "i", "n", "s" }, "<c-b>", function()
      if not require("noice.lsp").scroll(-4) then
        return "<c-b>"
      end
    end, { silent = true, expr = true, desc = "Scroll Backward" })
  end,
}
