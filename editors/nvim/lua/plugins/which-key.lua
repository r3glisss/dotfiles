-- Affiche les continuations possibles d'un prefixe apres un court delai.
-- Avec ~80 mappings repartis sur une dizaine de namespaces, c'est ce qui rend
-- le reste de la configuration reellement utilisable.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    delay = 400,
    spec = {
      { "<leader>b", group = "buffer" },
      { "<leader>c", group = "code" },
      { "<leader>d", group = "debug (dap)" },
      { "<leader>f", group = "find (telescope)" },
      { "<leader>g", group = "git" },
      { "<leader>gf", group = "git find" },
      { "<leader>h", group = "harpoon" },
      { "<leader>l", group = "lsp (telescope)" },
      { "<leader>q", group = "session" },
      { "<leader>r", group = "remplacer / renommer" },
      { "<leader>s", group = "split" },
      { "<leader>t", group = "onglet" },
      { "<leader>v", group = "vim" },
      { "<leader>x", group = "diagnostics / listes" },
      { "<leader>i", desc = "inspect signal (RTL)" },
      { "<leader>I", desc = "inspect signal, quickfix (RTL)" },
      { "]", group = "aller a (suivant)" },
      { "[", group = "aller a (precedent)" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = true })
      end,
      desc = "Tous les mappings",
    },
  },
}
