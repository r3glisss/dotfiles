return {
  ---------------------------------------------------------------------------
  -- Harpoon : epingler les 4-5 fichiers sur lesquels on fait des allers-retours
  -- (le module, son package, le TB, le wrapper) et sauter dessus en une touche.
  ---------------------------------------------------------------------------
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    },
    config = function(_, opts)
      require("harpoon"):setup(opts)
    end,
    keys = function()
      local keys = {
        {
          "<leader>ha",
          function()
            require("harpoon"):list():add()
          end,
          desc = "Epingler le fichier",
        },
        {
          "<leader>hh",
          function()
            local h = require("harpoon")
            h.ui:toggle_quick_menu(h:list())
          end,
          desc = "Menu des fichiers epingles",
        },
        {
          "<leader>hn",
          function()
            require("harpoon"):list():next()
          end,
          desc = "Epingle suivante",
        },
        {
          "<leader>hp",
          function()
            require("harpoon"):list():prev()
          end,
          desc = "Epingle precedente",
        },
      }
      for i = 1, 5 do
        table.insert(keys, {
          "<leader>" .. i,
          function()
            require("harpoon"):list():select(i)
          end,
          desc = "Epingle " .. i,
        })
      end
      return keys
    end,
  },

  ---------------------------------------------------------------------------
  -- Trouble : diagnostics, references et quickfix dans une liste navigable
  -- plutot qu'au fil des buffers ouverts.
  ---------------------------------------------------------------------------
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {
      focus = true,
      warn_no_results = false,
      open_no_results = true,
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics du fichier" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics du projet" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symboles du fichier" },
      { "<leader>xr", "<cmd>Trouble lsp toggle<cr>", desc = "References / definitions LSP" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
    },
  },

  ---------------------------------------------------------------------------
  -- grug-far : chercher/remplacer sur tout le projet, avec previsualisation et
  -- annulation. Renommer un signal a travers 40 fichiers RTL.
  ---------------------------------------------------------------------------
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        "<leader>R",
        function()
          require("grug-far").open({ transient = true })
        end,
        desc = "Chercher / remplacer (projet)",
      },
      {
        "<leader>R",
        mode = "v",
        function()
          require("grug-far").with_visual_selection({ transient = true })
        end,
        desc = "Chercher / remplacer (selection)",
      },
      {
        "<leader>rw",
        function()
          require("grug-far").open({ transient = true, prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "Remplacer le mot sous le curseur",
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Aerial : plan du fichier (remplace vista.vim)
  ---------------------------------------------------------------------------
  {
    "stevearc/aerial.nvim",
    -- Meme piege que nvim-treesitter : master exige nvim >= 0.12 et refuse de
    -- s'initialiser en dessous (aucune commande Aerial* n'est alors creee).
    -- La branche nvim-0.11 est la version maintenue pour notre version.
    branch = "nvim-0.11",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    cmd = { "AerialToggle", "AerialNavToggle" },
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = { default_direction = "right", width = 34 },
      show_guides = true,
      -- Suit la position du curseur dans le plan
      highlight_on_jump = 200,
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle<cr>", desc = "Plan du fichier" },
      { "<leader>O", "<cmd>AerialNavToggle<cr>", desc = "Naviguer dans le plan" },
      { "]s", "<cmd>AerialNext<cr>", desc = "Symbole suivant" },
      { "[s", "<cmd>AerialPrev<cr>", desc = "Symbole precedent" },
    },
  },

  ---------------------------------------------------------------------------
  -- Oil : le systeme de fichiers comme un buffer editable. Renommer, deplacer
  -- et supprimer avec les commandes d'edition habituelles, puis :w.
  ---------------------------------------------------------------------------
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- Chargeable a la demande : `default_file_explorer = false` laisse
    -- nvim-tree gerer l'ouverture d'un repertoire, donc rien a intercepter au
    -- demarrage.
    cmd = "Oil",
    opts = {
      -- nvim-tree garde la main sur netrw / l'explorateur lateral
      default_file_explorer = false,
      view_options = { show_hidden = true },
      keymaps = { ["q"] = "actions.close" },
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Ouvrir le dossier parent (oil)" },
    },
  },
}
