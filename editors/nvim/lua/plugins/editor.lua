return {
  ---------------------------------------------------------------------------
  -- Contexte de scope colle en haut de l'ecran (remplace context.vim).
  -- Adosse a l'AST : sur un always_ff de 200 lignes il affiche
  -- module -> always_ff -> case -> etat courant.
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      max_lines = 4,
      multiline_threshold = 2,
      trim_scope = "outer",
      mode = "cursor",
      separator = "─",
    },
    keys = {
      {
        "[x",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Remonter au contexte englobant",
      },
      {
        "<leader>cx",
        function()
          require("treesitter-context").toggle()
        end,
        desc = "Contexte colle (toggle)",
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Flash : saut a l'ecran en tapant ce qu'on vise (remplace easymotion).
  -- `s` + 2-3 caracteres, puis la lettre d'etiquette.
  ---------------------------------------------------------------------------
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        -- Etiquette aussi les resultats de / et ?
        search = { enabled = true },
        char = { jump_labels = true },
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter search" },
    },
  },

  ---------------------------------------------------------------------------
  -- Surround : ysiw" cs"' ds" (remplace vim-surround). vim-repeat rend `.`
  -- fonctionnel dessus.
  ---------------------------------------------------------------------------
  { "tpope/vim-repeat", event = "VeryLazy" },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  ---------------------------------------------------------------------------
  -- mini.ai : text objects etendus. `va)` saute a la prochaine parenthese si on
  -- n'est pas dedans, `vaa` prend un argument, `vai` un bloc d'indentation --
  -- ce dernier est le plus utile en RTL faute de queries textobjects pour la
  -- grammaire SystemVerilog.
  ---------------------------------------------------------------------------
  {
    "echasnovski/mini.ai",
    version = "*",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          -- a = argument, i = bloc d'indentation, f = appel de fonction
          a = ai.gen_spec.argument({ brackets = { "%b()", "%b[]", "%b{}" } }),
          f = ai.gen_spec.function_call(),
        },
      }
    end,
  },

  ---------------------------------------------------------------------------
  -- Multi-curseurs (remplace vim-visual-multi, meme plugin : il marche en nvim)
  --   <C-n> selectionne l'occurrence suivante du mot
  --   <C-Down>/<C-Up> ajoutent un curseur vertical
  ---------------------------------------------------------------------------
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "VeryLazy",
    init = function()
      -- <C-Down>/<C-Up> sont deja pris par le redimensionnement de fenetres
      vim.g.VM_maps = {
        ["Find Under"] = "<C-n>",
        ["Find Subword Under"] = "<C-n>",
        ["Add Cursor Down"] = "<M-Down>",
        ["Add Cursor Up"] = "<M-Up>",
      }
    end,
  },

  ---------------------------------------------------------------------------
  -- Marqueurs d'indentation (remplace indentLine), avec mise en valeur du
  -- bloc courant.
  ---------------------------------------------------------------------------
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = {
        filetypes = {
          "help", "lazy", "mason", "NvimTree", "Trouble", "trouble",
          "aerial", "oil", "undotree", "diff", "gitcommit", "checkhealth",
        },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Arbre d'undo. Utile maintenant que `undofile` est actif : l'historique
  -- survit a la fermeture du fichier.
  ---------------------------------------------------------------------------
  {
    "mbbill/undotree",
    cmd = { "UndotreeToggle", "UndotreeShow" },
    init = function()
      vim.g.undotree_WindowLayout = 2
      vim.g.undotree_SetFocusWhenToggle = 1
    end,
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Arbre d'undo" },
    },
  },

  ---------------------------------------------------------------------------
  -- Sessions par projet : rouvre les memes buffers au retour dans un depot.
  ---------------------------------------------------------------------------
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restaurer la session du projet",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restaurer la derniere session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Ne pas enregistrer cette session",
      },
    },
  },
}
