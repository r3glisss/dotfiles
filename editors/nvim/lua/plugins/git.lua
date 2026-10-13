-- Git : trois niveaux, trois outils.
--   gitsigns  -> le hunk sous le curseur (equivalent de vim-gitgutter)
--   fugitive  -> les commandes git dans un buffer (:Git, :Gwrite, :Gread...)
--   diffview  -> parcourir diffs et historique (equivalent de gv.vim)
--
-- Convention de mappings, tout sous <leader>g :
--   minuscule seule = action sur le hunk / le fichier courant
--   <leader>gf...    = "git find", les pickers telescope
--   ]h / [h          = navigation entre hunks

return {
  -----------------------------------------------------------------------------
  -- Hunks dans le buffer : signes, stage/reset, blame, preview
  -----------------------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signcolumn = true,
      -- Blame de la ligne courante en virtual text : off par defaut (bruyant),
      -- <leader>gB pour l'allumer ponctuellement.
      current_line_blame = false,
      current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
      preview_config = { border = "rounded" },

      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        -- Navigation. Dans un buffer en mode diff, ]c/[c natifs font deja le
        -- travail : on ne les ecrase pas, on prend ]h/[h.
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Hunk suivant")

        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Hunk precedent")

        -- Actions sur le hunk (les memes lettres que le .vimrc : gs / gu)
        map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
        map("v", "<leader>gs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selection")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("v", "<leader>gr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selection")
        map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")

        -- Inspection
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "Blame de la ligne")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Blame inline (toggle)")
        map("n", "<leader>gd", gs.diffthis, "Diff du fichier (index)")
        map("n", "<leader>gD", function()
          gs.diffthis("~")
        end, "Diff du fichier (HEAD~)")

        -- Text object : dih / cih / vih agissent sur le hunk
        map({ "o", "x" }, "ih", gs.select_hunk, "Hunk")
      end,
    },
  },

  -----------------------------------------------------------------------------
  -- Commandes git (:Git, :Gwrite, :Gread, :Gdiffsplit, :GBrowse...)
  -----------------------------------------------------------------------------
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gwrite", "Gread", "Gdiffsplit", "Gvdiffsplit", "GBrowse", "Gedit" },
    keys = {
      { "<leader>gg", "<cmd>Git<cr>", desc = "Git status (fugitive)" },
      { "<leader>gc", "<cmd>Git commit<cr>", desc = "Git commit" },
      { "<leader>ga", "<cmd>Git commit --amend<cr>", desc = "Git commit --amend" },
      { "<leader>gm", "<cmd>Gvdiffsplit!<cr>", desc = "Merge : diff 3 volets" },
      -- Resolution de conflit depuis le volet du milieu : //2 = ours, //3 = theirs
      { "<leader>g2", "<cmd>diffget //2<cr>", desc = "Conflit : prendre ours" },
      { "<leader>g3", "<cmd>diffget //3<cr>", desc = "Conflit : prendre theirs" },
    },
  },

  -----------------------------------------------------------------------------
  -- Diffs et historique navigables
  -----------------------------------------------------------------------------
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview : working tree" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview : fermer" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Historique du depot" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Historique du fichier" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
      },
      file_panel = {
        listing_style = "tree",
        win_config = { position = "right", width = 32 },
      },
      hooks = {
        -- scrollbind aligne les numeros de ligne, pas les lignes ecran : avec
        -- 'wrap' global, une ligne longue d'un seul cote decale les deux volets.
        diff_buf_win_enter = function(_, winid)
          vim.wo[winid].wrap = false
        end,
      },
    },
  },

  -----------------------------------------------------------------------------
  -- Pickers telescope : <leader>gf... ("git find")
  -- Enregistres ici pour garder tout le git au meme endroit ; telescope.lua ne
  -- definit plus de mapping <leader>g*.
  -----------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>gfs",
        function()
          require("telescope.builtin").git_status()
        end,
        desc = "Git : fichiers modifies",
      },
      {
        "<leader>gfc",
        function()
          require("telescope.builtin").git_commits()
        end,
        desc = "Git : commits du depot",
      },
      {
        "<leader>gfb",
        function()
          require("telescope.builtin").git_bcommits()
        end,
        desc = "Git : commits du fichier",
      },
      {
        "<leader>gfr",
        function()
          require("telescope.builtin").git_branches()
        end,
        desc = "Git : branches",
      },
      {
        "<leader>gfz",
        function()
          require("telescope.builtin").git_stash()
        end,
        desc = "Git : stash",
      },
      {
        "<leader>gfw",
        function()
          require("telescope").extensions.git_worktree.git_worktrees()
        end,
        desc = "Git : worktrees",
      },
      {
        "<leader>gfW",
        function()
          require("telescope").extensions.git_worktree.create_git_worktree()
        end,
        desc = "Git : creer un worktree",
      },
    },
  },
}
