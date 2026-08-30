return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Capabilities pour TOUS les serveurs, y compris ceux declares ailleurs
      -- (verible, cf. plugins/systemverilog.lua). On passe par l'API native
      -- vim.lsp.config/enable de nvim 0.11 : le "framework" require("lspconfig")
      -- est deprecie et disparait en nvim-lspconfig v3.
      vim.lsp.config("*", { capabilities = capabilities })

      -- Mappings LSP, poses une seule fois pour n'importe quel serveur qui
      -- s'attache -- et non par serveur, ou ils finissent par manquer a l'un
      -- d'eux.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(ev)
          local opts = { buffer = ev.buf, silent = true }
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
          end

          map("gd", vim.lsp.buf.definition, "Aller a la definition")
          map("gD", vim.lsp.buf.declaration, "Aller a la declaration")
          map("gi", vim.lsp.buf.implementation, "Aller a l'implementation")
          map("gr", vim.lsp.buf.references, "References")
          map("K", vim.lsp.buf.hover, "Documentation")
          map("<leader>rn", vim.lsp.buf.rename, "Renommer")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          -- Dans le groupe `code` et non `<leader>ds` : `<leader>d` est reserve
          -- au debug, ou il serait le prefixe des pas-a-pas dap.
          map("<leader>cs", vim.lsp.buf.document_symbol, "Symboles du fichier")
          map("[d", function()
            vim.diagnostic.jump({ count = -1 })
          end, "Diagnostic precedent")
          map("]d", function()
            vim.diagnostic.jump({ count = 1 })
          end, "Diagnostic suivant")

          -- Inlay hints : allumes d'office quand le serveur sait les produire.
          -- Sur du SystemVerilog slang y met les noms de ports des connexions
          -- positionnelles et developpe les `.*` -- c'est la ou ils rapportent
          -- le plus.
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
            map("<leader>ch", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
            end, "Inlay hints (toggle)")
          end
        end,
      })

      vim.diagnostic.config({
        virtual_text = false,
        signs = true,
        underline = true,
        severity_sort = true,
        float = { border = "rounded", source = true },
      })

      -- Python : jedi doit pointer sur l'interpreteur du projet uv, pas sur le
      -- python systeme, sinon aucune completion sur les dependances.
      local function get_python_path()
        if vim.fn.executable("uv") == 1 then
          local out = vim.system(
            { "uv", "run", "python", "-c", "import sys; print(sys.executable)" },
            { text = true }
          ):wait()
          if out.code == 0 then
            local python = vim.trim(out.stdout or "")
            if python ~= "" then
              return python
            end
          end
        end
        return "python3"
      end

      vim.lsp.config("jedi_language_server", {
        init_options = {
          workspace = { environmentPath = get_python_path() },
        },
      })

      -- Les definitions de base (cmd, filetypes, root_markers) viennent des
      -- fichiers lsp/*.lua de nvim-lspconfig, presents sur le runtimepath.
      -- verible est configure dans plugins/systemverilog.lua.
      vim.lsp.enable({ "ts_ls", "lua_ls", "jedi_language_server" })
    end,
  },
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "typescript-language-server",
        "verible",
        "jedi-language-server",
        "ruff",
        "debugpy",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      for _, tool in ipairs(opts.ensure_installed) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
          p:install()
        end
      end
    end,
  },
}
