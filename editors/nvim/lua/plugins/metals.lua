return {
  "scalameta/nvim-metals",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "j-hui/fidget.nvim",
      opts = {},
    },
    {
      "mfussenegger/nvim-dap",
      config = function(self, opts)
        -- Debug settings if you're using nvim-dap
        local dap = require("dap")

        dap.configurations.scala = {
          {
            type = "scala",
            request = "launch",
            name = "RunOrTest",
            metals = {
              runType = "runOrTestFile",
              --args = { "firstArg", "secondArg", "thirdArg" }, -- here just as an example
            },
          },
          {
            type = "scala",
            request = "launch",
            name = "Test Target",
            metals = {
              runType = "testTarget",
            },
          },
        }
      end
    },
  },
  ft = { "scala", "sbt", "java" },
  opts = function()
    local metals_config = require("metals").bare_config()

    -- Example of settings
    metals_config.settings = {
      showImplicitArguments = true,
      excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
      -- scalafmtConfigPath = "~/.scalafmt.conf"
    }

    -- *READ THIS*
    -- I *highly* recommend setting statusBarProvider to either "off" or "on"
    --
    -- "off" will enable LSP progress notifications by Metals and you'll need
    -- to ensure you have a plugin like fidget.nvim installed to handle them.
    --
    -- "on" will enable the custom Metals status extension and you *have* to have
    -- a have settings to capture this in your statusline or else you'll not see
    -- any messages from metals. There is more info in the help docs about this
    metals_config.init_options.statusBarProvider = "off"

    -- Example if you are using cmp how to make sure the correct capabilities for snippets are set
    metals_config.capabilities = require("blink.cmp").get_lsp_capabilities()

    -- Pas d'`on_attach` maison : les mappings LSP communs (gd, gD, gi, gr, K,
    -- <leader>rn, <leader>ca, <leader>cs, [d, ]d) sont poses une seule fois par
    -- l'autocmd LspAttach de plugins/completion.lua, pour tous les serveurs.
    -- On ne garde ici que ce qui est propre a metals et a dap, sur des touches
    -- qui n'ecrasent rien de global.
    --
    -- Ce qui a ete retire, et pourquoi : <leader>f (formatage) ecrasait le
    -- groupe telescope <leader>f* dans les buffers scala -- <leader>cf de
    -- conform retombe sur le formatage LSP et fait le meme travail ; <leader>sh
    -- (signature help) ecrasait le split horizontal ; <leader>d et [c/]c
    -- (diagnostics) doublonnaient trouble et la convention diff.
    metals_config.on_attach = function(client, bufnr)
      require("metals").setup_dap()

      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
      end

      -- Propre a metals
      map("<leader>cc", vim.lsp.codelens.run, "Codelens")
      map("<leader>ck", vim.lsp.buf.signature_help, "Signature")
      map("<leader>cw", function()
        require("metals").hover_worksheet()
      end, "Worksheet metals")

      -- Debug. `<leader>do`/`<leader>di` et non `<leader>dso`/`<leader>dsi` :
      -- ces derniers auraient fait de `<leader>ds` un prefixe.
      map("<leader>dc", function()
        require("dap").continue()
      end, "Continuer")
      map("<leader>db", function()
        require("dap").toggle_breakpoint()
      end, "Point d'arret")
      map("<leader>dr", function()
        require("dap").repl.toggle()
      end, "REPL")
      map("<leader>dK", function()
        require("dap.ui.widgets").hover()
      end, "Inspecter la valeur")
      map("<leader>do", function()
        require("dap").step_over()
      end, "Pas a pas principal")
      map("<leader>di", function()
        require("dap").step_into()
      end, "Pas a pas detaille")
      map("<leader>du", function()
        require("dap").step_out()
      end, "Sortir de la fonction")
      map("<leader>dl", function()
        require("dap").run_last()
      end, "Relancer la derniere session")
    end

    return metals_config
  end,
  config = function(self, metals_config)
    local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = self.ft,
      callback = function()
        require("metals").initialize_or_attach(metals_config)
      end,
      group = nvim_metals_group,
    })
  end

}
