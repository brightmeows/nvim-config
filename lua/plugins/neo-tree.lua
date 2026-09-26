-- neo-tree：文件树（启用的 explorer extra）。行为源：LazyVim extras/editor/neo-tree.lua。
-- 差异：Snacks.rename/LazyVim.root 保留；deactivate（lazy 卸载钩子）移除。
return {
  src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
  name = "neo-tree.nvim",
  config = function()
    local opts = {
      sources = { "filesystem", "buffers", "git_status" },
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      window = {
        mappings = {
          ["l"] = "open",
          ["h"] = "close_node",
          ["<space>"] = "none",
          ["Y"] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg("+", path, "c")
            end,
            desc = "Copy Path to Clipboard",
          },
          ["O"] = {
            function(state)
              vim.ui.open(state.tree:get_node().path)
            end,
            desc = "Open with System Application",
          },
          ["P"] = { "toggle_preview", config = { use_float = false } },
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
        git_status = {
          symbols = {
            unstaged = "󰄱",
            staged = "󰱒",
          },
        },
      },
    }

    local function on_move(data)
      Snacks.rename.on_rename_file(data.source, data.destination)
    end
    local events = require("neo-tree.events")
    opts.event_handlers = opts.event_handlers or {}
    vim.list_extend(opts.event_handlers, {
      { event = events.FILE_MOVED, handler = on_move },
      { event = events.FILE_RENAMED, handler = on_move },
    })
    require("neo-tree").setup(opts)

    vim.api.nvim_create_autocmd("TermClose", {
      pattern = "*lazygit",
      callback = function()
        if package.loaded["neo-tree.sources.git_status"] then
          require("neo-tree.sources.git_status").refresh()
        end
      end,
    })

    -- 以目录参数启动时打开 neo-tree（LazyVim init 段同款）
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("Neotree_start_directory", { clear = true }),
      desc = "Start Neo-tree with directory",
      once = true,
      callback = function()
        if package.loaded["neo-tree"] then
          return
        else
          local stats = vim.uv.fs_stat(vim.fn.argv(0))
          if stats and stats.type == "directory" then
            require("neo-tree")
          end
        end
      end,
    })

    -- LazyVim neo-tree extra 的 keymaps
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
    end
    map("<leader>fe", function()
      require("neo-tree.command").execute({ toggle = true, dir = require("meow.root")() })
    end, "Explorer NeoTree (Root Dir)")
    map("<leader>fE", function()
      require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
    end, "Explorer NeoTree (cwd)")
    vim.keymap.set(
      "n",
      "<leader>e",
      "<leader>fe",
      { desc = "Explorer NeoTree (Root Dir)", remap = true, silent = true }
    )
    vim.keymap.set("n", "<leader>E", "<leader>fE", { desc = "Explorer NeoTree (cwd)", remap = true, silent = true })
    map("<leader>ge", function()
      require("neo-tree.command").execute({ source = "git_status", toggle = true })
    end, "Git Explorer")
    map("<leader>be", function()
      require("neo-tree.command").execute({ source = "buffers", toggle = true })
    end, "Buffer Explorer")
  end,
}
