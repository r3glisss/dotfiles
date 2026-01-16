return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "ThePrimeagen/git-worktree.nvim",
    "smartpde/telescope-recent-files",
    -- Enhanced dependencies for better functionality
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-telescope/telescope-file-browser.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-tree/nvim-web-devicons", -- for file icons
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local builtin = require("telescope.builtin")

    -- Enhanced telescope setup with beautiful UI and performance optimizations
    telescope.setup({
      defaults = {
        -- Visual improvements
        prompt_prefix = "🔍 ",
        selection_caret = "▶ ",
        entry_prefix = "  ",
        multi_icon = "✓ ",

        -- Layout and sizing
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
            results_width = 0.8,
          },
          vertical = {
            mirror = false,
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },

        -- Sorting and performance
        sorting_strategy = "ascending",
        file_ignore_patterns = {
          "node_modules/",
          ".git/",
          ".DS_Store",
          "*.pyc",
          "__pycache__/",
          ".pytest_cache/",
          ".venv/",
          "venv/",
          "dist/",
          "build/",
          "target/",
          "*.min.js",
          "*.min.css",
        },

        -- Enhanced search behavior
        set_env = { ["COLORTERM"] = "truecolor" },
        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,

        -- Better mappings
        mappings = {
          i = {
            -- Navigation
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,

            -- Selection actions
            ["<C-c>"] = actions.close,
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["<CR>"] = actions.select_default,
            ["<C-x>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,

            -- Preview control
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,

            -- Multi-select
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

            -- Clear prompt
            ["<C-l>"] = actions.complete_tag,
            ["<C-_>"] = actions.which_key, -- keys from pressing <C-/>
          },
          n = {
            ["<esc>"] = actions.close,
            ["<CR>"] = actions.select_default,
            ["<C-x>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,

            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["H"] = actions.move_to_top,
            ["M"] = actions.move_to_middle,
            ["L"] = actions.move_to_bottom,

            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["gg"] = actions.move_to_top,
            ["G"] = actions.move_to_bottom,

            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,

            ["?"] = actions.which_key,
          },
        },

        -- Color scheme and appearance
        winblend = 0,
        border = {},
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        use_less = true,
        path_display = { "truncate" },

        -- Performance optimizations
        cache_picker = {
          num_pickers = 10,
        },
      },

      pickers = {
        -- Enhanced find_files picker
        find_files = {
          theme = "dropdown",
          previewer = true,
          hidden = true,
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
          layout_config = {
            width = 0.8,
            height = 0.8,
          },
        },

        -- Enhanced live_grep picker
        live_grep = {
          theme = "ivy",
          additional_args = function(opts)
            return { "--hidden" }
          end,
          layout_config = {
            height = 0.9,
          },
        },

        -- Enhanced buffers picker
        buffers = {
          theme = "dropdown",
          previewer = true,
          initial_mode = "normal",
          sort_mru = true,
          sort_lastused = true,
          layout_config = {
            width = 0.8,
            height = 0.6,
          },
          mappings = {
            i = {
              ["<c-d>"] = actions.delete_buffer + actions.move_to_top,
            },
            n = {
              ["dd"] = actions.delete_buffer + actions.move_to_top,
            },
          },
        },

        -- Enhanced git pickers
        git_status = {
          theme = "ivy",
          layout_config = {
            height = 0.7,
          },
        },

        git_commits = {
          theme = "ivy",
          layout_config = {
            height = 0.8,
          },
        },

        git_bcommits = {
          theme = "ivy",
          layout_config = {
            height = 0.8,
          },
        },

        -- Enhanced help_tags
        help_tags = {
          theme = "ivy",
        },

        -- Enhanced oldfiles
        oldfiles = {
          theme = "dropdown",
          previewer = true,
          layout_config = {
            width = 0.8,
            height = 0.7,
          },
        },

        -- Enhanced grep_string
        grep_string = {
          theme = "ivy",
          layout_config = {
            height = 0.8,
          },
        },
      },

      extensions = {
        -- FZF extension for better performance
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },

        -- File browser extension
        file_browser = {
          theme = "ivy",
          hijack_netrw = true,
          mappings = {
            ["i"] = {
              ["<A-c>"] = require("telescope").extensions.file_browser.actions.create,
              ["<S-CR>"] = require("telescope").extensions.file_browser.actions.create_from_prompt,
              ["<A-r>"] = require("telescope").extensions.file_browser.actions.rename,
              ["<A-m>"] = require("telescope").extensions.file_browser.actions.move,
              ["<A-y>"] = require("telescope").extensions.file_browser.actions.copy,
              ["<A-d>"] = require("telescope").extensions.file_browser.actions.remove,
              ["<C-o>"] = require("telescope").extensions.file_browser.actions.open,
              ["<C-g>"] = require("telescope").extensions.file_browser.actions.goto_parent_dir,
              ["<C-e>"] = require("telescope").extensions.file_browser.actions.goto_home_dir,
              ["<C-w>"] = require("telescope").extensions.file_browser.actions.goto_cwd,
              ["<C-t>"] = require("telescope").extensions.file_browser.actions.change_cwd,
              ["<C-f>"] = require("telescope").extensions.file_browser.actions.toggle_browser,
              ["<C-h>"] = require("telescope").extensions.file_browser.actions.toggle_hidden,
              ["<C-s>"] = require("telescope").extensions.file_browser.actions.toggle_all,
            },
          },
        },

        -- UI select extension for better vim.ui.select
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({
            winblend = 10,
          }),
        },
      },
    })

    -- Load extensions
    telescope.load_extension("fzf")
    telescope.load_extension("file_browser")
    telescope.load_extension("ui-select")
    telescope.load_extension("git_worktree")
    telescope.load_extension("recent_files")

    -- Enhanced keymaps with better descriptions and functionality
    local keymap = vim.keymap

    -- File navigation
    keymap.set("n", "<leader>ff", function() builtin.find_files() end, { desc = "🔍 Find files" })
    keymap.set("n", "<leader>fa", function() builtin.find_files({ follow = true, no_ignore = true, hidden = true }) end,
      { desc = "🔍 Find all files" })
    keymap.set("n", "<leader>fb", function() builtin.file_browser() end, { desc = "📁 File browser" })
    keymap.set("n", "<leader>fr", function() telescope.extensions.recent_files.pick() end, { desc = "⏰ Recent files" })
    keymap.set("n", "<leader>fo", function() builtin.oldfiles() end, { desc = "📄 Old files" })

    -- Text search
    keymap.set("n", "<leader>fs", function() builtin.live_grep() end, { desc = "🔎 Live grep" })
    keymap.set("n", "<leader>fw", function() builtin.grep_string() end, { desc = "🔍 Find word under cursor" })
    keymap.set("n", "<leader>fc", function() builtin.grep_string({ search = vim.fn.input("Grep > ") }) end,
      { desc = "🔍 Custom grep" })

    -- Buffers and tabs
    keymap.set("n", "<leader>fb", function() builtin.buffers() end, { desc = "📋 Buffers" })
    keymap.set("n", "<leader><Tab>", function() builtin.buffers() end, { desc = "📋 Switch buffer" })

    -- Git integration
    keymap.set("n", "<leader>gs", function() builtin.git_status() end, { desc = "🔧 Git status" })
    keymap.set("n", "<leader>gc", function() builtin.git_commits() end, { desc = "📝 Git commits" })
    keymap.set("n", "<leader>gb", function() builtin.git_bcommits() end, { desc = "📝 Buffer commits" })
    keymap.set("n", "<leader>gB", function() builtin.git_branches() end, { desc = "🌿 Git branches" })

    -- LSP integration
    keymap.set("n", "<leader>lr", function() builtin.lsp_references() end, { desc = "🔗 LSP references" })
    keymap.set("n", "<leader>ld", function() builtin.lsp_definitions() end, { desc = "📍 LSP definitions" })
    keymap.set("n", "<leader>ls", function() builtin.lsp_document_symbols() end, { desc = "🏷️  Document symbols" })
    keymap.set("n", "<leader>lw", function() builtin.lsp_dynamic_workspace_symbols() end,
      { desc = "🏷️  Workspace symbols" })

    -- Vim integration
    keymap.set("n", "<leader>vh", function() builtin.help_tags() end, { desc = "❓ Help tags" })
    keymap.set("n", "<leader>vk", function() builtin.keymaps() end, { desc = "⌨️  Keymaps" })
    keymap.set("n", "<leader>vc", function() builtin.commands() end, { desc = "⚡ Commands" })
    keymap.set("n", "<leader>vo", function() builtin.vim_options() end, { desc = "⚙️  Vim options" })

    -- Resume last search
    keymap.set("n", "<leader>r", function() builtin.resume() end, { desc = "🔄 Resume last search" })

    -- Diagnostics
    keymap.set("n", "<leader>xx", function() builtin.diagnostics() end, { desc = "🚨 Diagnostics" })
    keymap.set("n", "<leader>xd", function() builtin.diagnostics({ bufnr = 0 }) end, { desc = "🚨 Buffer diagnostics" })
  end,
}
