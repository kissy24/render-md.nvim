local M = {}

local ns_id = vim.api.nvim_create_namespace("render-md")

-- ハイライトグループの定義
local function setup_highlights()
    local config = require("render-md").config
    local h = config.highlights
    
    -- より洗練されたデフォルトハイライト
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

    local config = require("render-md").config
    setup_highlights()
    
    -- 既存の装飾をクリア
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    local parser = vim.treesitter.get_parser(bufnr, "markdown")
    if not parser then return end
    local tree = parser:parse()[1]
    local root = tree:root()

    -- 拡張されたクエリ
    local query = vim.treesitter.query.parse("markdown", [[
        (atx_heading (atx_h1_marker) (inline) @h1)
        (atx_heading (atx_h2_marker) (inline) @h2)
        (atx_heading (atx_h3_marker) (inline) @h3)
        (list_item (list_marker_dash) @bullet)
        (task_list_marker_unchecked) @unchecked
        (task_list_marker_checked) @checked
        (block_quote (block_quote_marker) @quote)
        (fenced_code_block) @code_block
        (fenced_code_block (info_string (language) @code_lang))
    ]])

    for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
        local name = query.captures[id]
        local start_row, start_col, end_row, end_col = node:range()

        if name == "h1" or name == "h2" or name == "h3" then
            local level = tonumber(name:sub(2, 2))
            local hl_group = "RenderMDH" .. level
            
            -- 見出しの装飾 (アイコン表示とマーカー隠蔽)
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
                virt_text = { { string.rep(" ", level - 1) .. config.icons["h" .. level], hl_group } },
                virt_text_pos = "overlay",
                conceal = "",
            })

            -- H1 の下に境界線を表示
            if level == 1 then
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
                    virt_lines = {
                        { { string.rep("━", vim.api.nvim_win_get_width(0)), "RenderMDBorder" } }
                    },
                    virt_lines_above = false,
                })
            end
            
            -- H2 の左側にボーダー
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
        elseif name == "quote" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
                virt_text = { { config.icons.quote, "RenderMDQuote" } },
                virt_text_pos = "overlay",
                conceal = "",
            })
        elseif name == "code_block" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
                end_row = end_row,
                hl_group = "RenderMDCode",
                hl_eol = true,
            })
        elseif name == "code_lang" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, end_col, {
                virt_text = { { " " .. config.icons.code .. vim.treesitter.get_node_text(node, bufnr), "RenderMDCodeLang" } },
                virt_text_pos = "eol",
            })
        end
    end

    -- インライン装飾（markdown_inline）のパース
    local inline_parser = vim.treesitter.get_parser(bufnr, "markdown_inline")
    if inline_parser then
        local inline_tree = inline_parser:parse()[1]
        local inline_root = inline_tree:root()
        local inline_query = vim.treesitter.query.parse("markdown_inline", [[
            (emphasis (emphasis_marker) @em)
            (strong_emphasis (emphasis_marker) @strong)
            (strikethrough (strikethrough_marker) @strike)
            (code_span (code_span_delimiter) @code_delim)
        ]])

        for id, node, _ in inline_query:iter_captures(inline_root, bufnr, 0, -1) do
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, select(1, node:range()), select(2, node:range()), {
                end_col = select(4, node:range()),
                conceal = "",
            })
        end
    end
end

return M
