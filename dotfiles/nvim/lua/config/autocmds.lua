-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

vim.cmd([[
  autocmd ColorScheme * highlight Normal guibg=NONE ctermbg=NONE
  autocmd ColorScheme * highlight NormalFloat guibg=NONE ctermbg=NONE
  autocmd ColorScheme * highlight SignColumn guibg=NONE ctermbg=NONE
]])

vim.cmd([[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalFloat guibg=NONE ctermbg=NONE
  highlight SignColumn guibg=NONE ctermbg=NONE
]])

vim.o.updatetime = 300

local function smart_hover()
  -- only in normal mode
  if vim.fn.mode() ~= "n" then
    return
  end

  -- need at least one LSP client
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return
  end

  -- use the server's encoding (required by newer APIs)
  local enc = clients[1].offset_encoding or "utf-16"
  local params = vim.lsp.util.make_position_params(0, enc)

  vim.lsp.buf_request(0, "textDocument/hover", params, function(err, result)
    if err or not result or not result.contents then
      return
    end

    local md = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
    -- trim empty lines without the deprecated helper
    local lines = vim.split(table.concat(md, "\n"), "\n", { trimempty = true })
    if vim.tbl_isempty(lines) then
      return
    end

    -- open a hover window only when we actually have content
    vim.lsp.util.open_floating_preview(lines, "markdown", { border = "rounded" })
  end)
end

vim.api.nvim_create_autocmd("CursorHold", { callback = smart_hover })
-- Optional: make `K` use the same silent behavior
vim.keymap.set("n", "K", smart_hover, { silent = true })

-- function CenterCursor()
--   local pos = vim.api.nvim_win_get_cursor(0) -- Get the current cursor position
--   vim.cmd("normal! zz") -- Center the cursor
--   vim.api.nvim_win_set_cursor(0, pos) -- Restore the exact cursor position
-- end
--
-- vim.api.nvim_create_autocmd("CursorMoved", {
--   callback = CenterCursor,
-- })
