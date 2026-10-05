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
    -- Ambiance claire (cafe au lait) sur les buffers markdown, sombre ailleurs.
    -- `background` est global a nvim : toute l'UI bascule quand le buffer
    -- courant est du markdown, et revient a l'ambiance sombre en le quittant.
    -- Le colorscheme `claude` se recharge tout seul au changement de
    -- `background`. Desactivable avec `vim.g.markdown_light_background = false`.
    -- `init` tourne au demarrage, avant tout chargement lazy du plugin.
    init = function()
      if vim.g.markdown_light_background == false then
        return
      end
      local group = vim.api.nvim_create_augroup("markdown-light-background", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        group = group,
        callback = function(ev)
          -- Buffers speciaux (nvim-tree, telescope, terminal...) : on ne touche a
          -- rien, sinon ouvrir l'explorateur depuis un .md rebascule en sombre.
          if vim.bo[ev.buf].buftype ~= "" then
            return
          end
          local wanted = vim.bo[ev.buf].filetype == "markdown" and "light" or "dark"
          if vim.o.background ~= wanted then
            vim.o.background = wanted
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
