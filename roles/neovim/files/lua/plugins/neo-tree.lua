-- TODO

-- references:
-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Recipes
return {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    event = "VeryLazy",
    keys = {
        { "<leader>w", ":Neotree focus<CR>", silent = true, desc = "File Explorer" },
    },
    config = function()
        local icons = require('techdufus.core.icons')
        require("neo-tree").setup({
            close_if_last_window = false,
            popup_border_style = "rounded",
            enable_git_status = true,
            enable_modified_markers = true,
            update_cwd = true,
            enable_diagnostics = true,
            sort_case_insensitive = true,
            default_component_configs = {
                container = {
                    enable_character_fade = true,
                },
                indent = {
                    with_markers = true,
                    with_expanders = true,
                },
                git_status = {
                    symbols = {
                        -- Change type
                        added = icons.git.added,
                        deleted = icons.git.deleted,
                        modified = icons.git.modified,
                        renamed = icons.git.renamed,
                        -- Status type
                        untracked = icons.git.untracked,
                        ignored = icons.git.ignored,
                        unstaged = icons.git.Unstaged,
                        staged = icons.git.staged,
                        conflict = icons.git.conflict,
                    },
                },
            },
            window = {
                position = "float",
                width = 35,
                mappings = {
                    ["<Backspace>"] = {
                        "close_node",
                        nowait = true, -- disable `nowait` if you have existing combos starting with this char that you want to use
                    },
                    ["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = true } }
                }
            },
            filesystem = {
                use_libuv_file_watcher = true,
                filtered_items = {
                    visable = true,
                    hide_dotfiles = false,
                    hide_gitignored = false,
                    hide_by_name = {
                        "node_modules",
                    },
                    never_show = {
                        ".DS_Store",
                        "thumbs.db",
                    },
                },
                components = {
                    harpoon_index = function(config, node, state)
                        local Marked = require("harpoon.mark")
                        local path = node:get_id()
                        local succuss, index = pcall(Marked.get_index_of, path)
                        if succuss and index and index > 0 then
                            return {
                                text = string.format(" ⥤ %d", index), -- <-- Add your favorite harpoon like arrow here
                                highlight = config.highlight or "NeoTreeDirectoryIcon",
                            }
                        else
                            return {}
                        end
                    end
                },
                renderers = {
                    file = {
                        { "icon" },
                        { "name",         use_git_status_colors = true },
                        { "harpoon_index" }, --> This is what actually adds the component in where you want it
                        { "diagnostics" },
                        { "git_status",   highlight = "NeoTreeDimText" },
                    }
                }
            },
            buffers = {
                follow_current_file = {
                    enabled = true
                },
            },
            event_handlers = {},
        })
    end,
}
