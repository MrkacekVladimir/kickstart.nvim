-- LaTex LSP
return {
  'lervag/vimtex',
  lazy = true,
  init = function()
    vim.g.vimtex_view_general_viewer = 'SumatraPDF'
    vim.g.vimtex_view_general_options = '-reuse-instance -forward-search @tex @line @pdf'
  end,
}
