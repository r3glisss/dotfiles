return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        -- Surtout pas <leader>f : ce serait a la fois un mapping complet et le
        -- prefixe de tous les <leader>f* de telescope, qui attendraient alors
        -- 'timeoutlen' avant de se declencher.
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Formater le buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports" },
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "jq", "prettier" },
      },
      -- Fonction plutot que table : permet a un buffer de se retirer du
      -- formatage automatique via vim.b.disable_autoformat (le RTL le fait,
      -- cf. plugins/systemverilog.lua). <leader>f reste toujours disponible.
      format_on_save = function(bufnr)
        if vim.b[bufnr].disable_autoformat or vim.g.disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_format = "fallback" }
      end,
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    -- Passe par `opts` pour que d'autres specs puissent ajouter leurs linters
    -- (systemverilog.lua ajoute verible) sans ecraser ce `config`.
    opts = {
      linters_by_ft = {
        python = { "ruff" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
      },
      -- Definitions de linters absents du catalogue nvim-lint.
      linters = {},
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft
      for name, def in pairs(opts.linters or {}) do
        lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name] or {}, def)
      end

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          -- Ne lance que les linters reellement installes : evite une erreur a
          -- chaque save quand le binaire manque.
          local names = lint.linters_by_ft[vim.bo.filetype] or {}
          local runnable = vim.tbl_filter(function(n)
            local l = lint.linters[n]
            return l and vim.fn.executable(type(l) == "table" and l.cmd or n) == 1
          end, names)
          if #runnable > 0 then
            lint.try_lint(runnable)
          end
        end,
      })

      vim.keymap.set("n", "<leader>cl", function()
        lint.try_lint()
      end, { desc = "Lancer le lint sur le fichier" })
    end,
  },

  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
      require("dap-python").setup(path)
    end,
  },
}

