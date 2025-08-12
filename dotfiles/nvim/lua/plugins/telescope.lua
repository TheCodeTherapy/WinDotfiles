return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>?",
      function()
        require("telescope.builtin").keymaps()
      end,
      desc = "Keymaps (Telescope)",
    },
  },
  opts = function(_, opts)
    local actions = require("telescope.actions")

    -- merge with any existing opts from LazyVim
    return vim.tbl_deep_extend("force", opts or {}, {
      defaults = {
        -- Start Telescope in NORMAL mode so j/k, gg/G, <C-d>/<C-u> work and don't close the picker
        initial_mode = "insert",

        -- Make navigation feel like Vim in both insert and normal modes
        mappings = {
          i = {
            ["<C-n>"] = actions.move_selection_next,
            ["<C-p>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<Tab>"] = actions.move_selection_next,
            ["<S-Tab>"] = actions.move_selection_previous,
            ["<C-f>"] = actions.preview_scrolling_down,
            ["<C-b>"] = actions.preview_scrolling_up,
            ["<Esc>"] = actions.close,
          },
          n = {
            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["gg"] = actions.move_to_top,
            ["G"] = actions.move_to_bottom,
            ["<C-d>"] = actions.results_scrolling_down,
            ["<C-u>"] = actions.results_scrolling_up,
            ["<C-f"] = actions.preview_scrolling_down,
            ["<C-b"] = actions.preview_scrolling_up,
            ["q"] = actions.close,
            ["<CR>"] = actions.select_default,
          },
        },
      },
    })
  end,
}
