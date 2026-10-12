-- ~/.config/nvim/lua/plugins/markdown.lua
--
-- Rendu markdown inline dans le buffer (titres, listes, tables, cases a cocher,
-- blocs de code, callouts) via tree-sitter. Pas de navigateur : le texte reste
-- editable, le rendu se masque sur la ligne courante en mode insertion.

return {
  -- Parsers requis par render-markdown. Listes concatenees grace a
  -- `opts_extend` declare dans treesitter.lua.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "markdown", "markdown_inline" },
    },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    -- Colorscheme `claude-white` sur les buffers markdown ; en les quittant, on
    -- revient au colorscheme precedent (claude-dark par defaut). Le colorscheme
    -- est global a nvim : toute l'UI bascule avec le buffer courant.
    -- Desactivable avec `vim.g.markdown_light_background = false`.
    -- `init` tourne au demarrage, avant tout chargement lazy du plugin.
    init = function()
      if vim.g.markdown_light_background == false then
        return
      end
      local saved -- colorscheme a restaurer en quittant le markdown
      local switching = false
      local group = vim.api.nvim_create_augroup("markdown-light-background", { clear = true })
      -- schedule : le chargement de la syntaxe (FileType) fait un `hi clear` qui
      -- effacerait le colorscheme applique pendant l'autocmd.
      local function apply(name)
        vim.schedule(function()
          if vim.g.colors_name == name then
            return
          end
          switching = true
          pcall(vim.cmd.colorscheme, name)
          switching = false
        end)
      end
      -- Un :colorscheme manuel annule la restauration automatique.
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
          if not switching then
            saved = nil
          end
        end,
      })
      vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        group = group,
        callback = function(ev)
          -- Buffers speciaux (nvim-tree, telescope, terminal...) : on ne touche a
          -- rien, sinon ouvrir l'explorateur depuis un .md rebascule en sombre.
          if vim.bo[ev.buf].buftype ~= "" then
            return
          end
          local current = vim.g.colors_name
          if vim.bo[ev.buf].filetype == "markdown" then
            if current ~= "claude-white" then
              saved = current
              apply("claude-white")
            end
          elseif saved then
            local name = saved
            saved = nil
            apply(name)
          end
        end,
      })
    end,
    opts = {
      -- Rendu masque sur la ligne courante en mode insertion (edition en brut).
      render_modes = { "n", "c", "t" },
      heading = { icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " } },
      code = { sign = false, width = "block", right_pad = 1 },
      checkbox = { enabled = true },
    },
    keys = {
      {
        "<leader>cm",
        function()
          require("render-markdown").toggle()
        end,
        ft = "markdown",
        desc = "Rendu markdown (toggle)",
      },
    },
  },
}
