return {
  {
    'nvimtools/none-ls.nvim',
    optional = true,
    opts = function(_, opts)
      local nls = require 'null-ls'
      opts.sources = opts.sources or {}
      table.insert(opts.sources, nls.builtins.formatting.csharpier)
    end,
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'hrsh7th/cmp-nvim-lsp',
      'Hoffs/omnisharp-extended-lsp.nvim',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          local ts_builtin = require 'telescope.builtin'
          map('gd', ts_builtin.lsp_definitions, '[G]oto [D]efinition')
          map('gr', ts_builtin.lsp_references, '[G]oto [R]eferences')
          map('gI', ts_builtin.lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', ts_builtin.lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', ts_builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', ts_builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('gh', vim.lsp.buf.hover, '[H]over')
          map('gR', vim.lsp.buf.rename, '[R]ename')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == 'omnisharp' then
            local omni_ex = require 'omnisharp_extended'
            map('gd', omni_ex.telescope_lsp_definition, '[G]oto [D]efinition')
            map('gr', omni_ex.telescope_lsp_references, '[G]oto [R]eferences')
            map('gI', omni_ex.telescope_lsp_implementation, '[G]oto [I]mplementation')
            map('<leader>D', omni_ex.telescope_lsp_type_definition, 'Type [D]efinition')
          end

          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      local cmp_nvim_lsp = require 'cmp_nvim_lsp'
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, cmp_nvim_lsp.default_capabilities())

      local servers = {
        pylsp = {
          settings = {
            pylsp = {
              plugins = {
                pycodestyle = {
                  maxLineLength = 128,
                },
              },
            },
          },
        },
        omnisharp = {
          settings = {
            FormattingOptions = {
              EnableEditorConfigSupport = true,
              OrganizeImports = nil,
            },
            MsBuild = {
              LoadProjectsOnDemand = nil,
            },
            RoslynExtensionsOptions = {
              EnableAnalyzersSupport = nil,
              EnableImportCompletion = nil,
              AnalyzeOpenDocumentsOnly = nil,
            },
            Sdk = {
              IncludePrereleases = true,
            },
          },
        },
        gopls = {},
        ts_ls = {},
        html = {},
        cssls = {},
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              format = {
                enable = false,
              },
              diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      require('mason').setup {}

      require('mason-tool-installer').setup {
        ensure_installed = {
          'eslint_d',
          'prettierd',
          'prettier',
          'csharpier',
          'stylua',
          'isort',
          'black',
        },
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      require('mason-lspconfig').setup {
        ensure_installed = ensure_installed,
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
}
