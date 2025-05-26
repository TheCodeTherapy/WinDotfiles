return {
  "iamcco/markdown-preview.nvim",
  config = function()
    -- vim.fn["mkdp#util#install"]()
    if not vim.fn.exists("g:mkdp_path") then
      vim.fn["mkdp#util#install"]()
    end
  end,
}
