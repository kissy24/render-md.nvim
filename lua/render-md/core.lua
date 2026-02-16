local M = {}

local ns_id = vim.api.nvim_create_namespace("render-md")

local function setup_highlights()
    local config = require("render-md").config
    local h = config.highlights
    
    vim.api.nvim_set_hl(0, "RenderMDH1", { fg = "#ffaf00", bold = true })
    vim.api.nvim_set_hl(0, "RenderMDH2", { fg = "#00afff", bold = true })
    vim.api.nvim_set_hl(0, "RenderMDH3", { fg = "#5fff00", bold = true })
    vim.api.nvim_set_hl(0, "RenderMDBorder", { fg = "#444444" })
    vim.api.nvim_set_hl(0, "RenderMDBullet", { fg = "#569cd6", bold = true })
    vim.api.nvim_set_hl(0, "RenderMDQuote", { fg = "#6a9955", italic = true })
    vim.api.nvim_set_hl(0, "RenderMDCode", { bg = "#1e1e1e" })
    vim.api.nvim_set_hl(0, "RenderMDCodeLang", { fg = "#dcdcaa", italic = true })
    vim.api.nvim_set_hl(0, "RenderMDCheckbox", { fg = "#ce9178" })
end

function M.render()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].filetype ~= "markdown" then return end

    local ok, config = pcall(function() return require("render-md").config end)
    if not ok or not config then return end
    
    setup_highlights()
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    local parser = vim.treesitter.get_parser(bufnr, "markdown")
    if not parser then return end
    local tree = parser:parse()[1]
    local root = tree:root()

    -- デバッグ用：実行されていることを確認
    -- vim.api.nvim_echo({{"render-md: rendering...", "Normal"}}, false, {})

    -- クエリをより汎用的なものに修正
    local query = vim.treesitter.query.parse("markdown", [[
        (atx_heading (atx_h1_marker) (inline) @h1_content)
        (atx_heading (atx_h2_marker) (inline) @h2_content)
        (atx_heading (atx_h3_marker) (inline) @h3_content)
        (atx_h1_marker) @h1_marker
        (atx_h2_marker) @h2_marker
        (atx_h3_marker) @h3_marker
        (list_item (list_marker_dash) @bullet)
        (task_list_marker_unchecked) @unchecked
        (task_list_marker_checked) @checked
        (block_quote (block_quote_marker) @quote)
        (fenced_code_block) @code_block
    ]])

    for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
        local name = query.captures[id]
        local start_row, start_col, end_row, end_col = node:range()

        if name:find("^h%d_marker") then
            local level = tonumber(name:sub(2, 2))
            local hl_group = "RenderMDH" .. level
            
            -- マーカーをアイコンに置換
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
                virt_text = { { string.rep(" ", level - 1) .. config.icons["h" .. level], hl_group } },
                virt_text_pos = "overlay",
                conceal = "",
            })

            -- H1の下線
            if level == 1 then
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
                    virt_lines = {
                        { { string.rep("━", vim.api.nvim_win_get_width(0)), "RenderMDBorder" } }
                    },
                })
            end
            
            -- H2の左ボーダー
            if level == 2 then
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
                    virt_text = { { "▍ ", hl_group } },
                    virt_text_pos = "inline",
                })
            end
        elseif name == "bullet" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
                virt_text = { { "  " .. config.icons.bullet, "RenderMDBullet" } },
                virt_text_pos = "overlay",
                conceal = "",
            })
        elseif name == "unchecked" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
                virt_text = { { " " .. config.icons.unchecked, "RenderMDCheckbox" } },
                virt_text_pos = "overlay",
                conceal = "",
            })
        elseif name == "checked" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
                virt_text = { { " " .. config.icons.checked, "RenderMDCheckbox" } },
                virt_text_pos = "overlay",
                conceal = "",
            })
        elseif name == "code_block" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
                end_row = end_row,
                hl_group = "RenderMDCode",
                hl_eol = true,
            })
        end
    end

    -- インライン装飾
    local inline_parser = vim.treesitter.get_parser(bufnr, "markdown_inline")
    if inline_parser then
        local inline_tree = inline_parser:parse()[1]
        local inline_query = vim.treesitter.query.parse("markdown_inline", [[
            (emphasis (emphasis_marker) @em)
            (strong_emphasis (emphasis_marker) @strong)
            (strikethrough (strikethrough_marker) @strike)
            (code_span (code_span_delimiter) @code_delim)
        ]])
        for _, node, _ in inline_query:iter_captures(inline_tree:root(), bufnr, 0, -1) do
            local s_r, s_c, e_r, e_c = node:range()
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, s_r, s_c, { end_col = e_c, conceal = "" })
        end
    end
end

return M
