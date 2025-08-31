return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
    { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
    { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
    { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
    { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
  },

  -- Build opts at runtime so we can conditionally inject Catppuccin highlights
  opts = function()
    local icons = (LazyVim and LazyVim.config and LazyVim.config.icons) or {}
    local diag_icons = icons.diagnostics or { Error = "E:", Warn = "W:" }
    local ft_icons = icons.ft or {}

    local opts = {
      options = {
        -- stylua: ignore
        close_command = function(n) Snacks.bufdelete(n) end,
        -- stylua: ignore
        right_mouse_command = function(n) Snacks.bufdelete(n) end,
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        diagnostics_indicator = function(_, _, diag)
          local ret = (diag.error and (diag_icons.Error .. diag.error .. " ") or "")
            .. (diag.warning and (diag_icons.Warn .. diag.warning) or "")
          return vim.trim(ret)
        end,
        offsets = {
          { filetype = "neo-tree", text = "Neo-tree", highlight = "Directory", text_align = "left" },
          { filetype = "snacks_layout_box" },
        },
        ---@param o bufferline.IconFetcherOpts
        get_element_icon = function(o)
          return ft_icons[o.filetype]
        end,
      },
    }

    -- If Catppuccin’s bufferline integration exposes .get(), use its themed highlights.
    local ok, bl = pcall(require, "catppuccin.groups.integrations.bufferline")
    if ok and type(bl.get) == "function" then
      opts.highlights = bl.get()
    end

    return opts
  end,

  config = function(_, opts)
    require("bufferline").setup(opts)

    -- Robust refresh for session restore / rapid buffer churn
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
      callback = function()
        vim.schedule(function()
          local ok, bufferline = pcall(require, "bufferline")
          if ok and type(bufferline.refresh) == "function" then
            bufferline.refresh()
          end
        end)
      end,
    })
  end,
}
