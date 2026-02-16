local M = {}

local ns_id = vim.api.nvim_create_namespace("render-md")

local function setup_highlights()
    local config = require("render-md").config
    local h = config.highlights
    
    vim.api.nvim_set_hl(0, "RenderMDH1", { bg = h.h1.bg, fg = h.h1.fg, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDH2", { bg = h.h2.bg, fg = h.h2.fg, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDH3", { bg = h.h3.bg, fg = h.h3.fg, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDBullet", { fg = h.bullet.fg, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDQuote", { fg = h.quote.fg, italic = true })
    vim.api.nvim_set_hl(0, "RenderMDCode", { bg = h.code.bg })
    vim.api.nvim_set_hl(0, "RenderMDCheckbox", { fg = h.checkbox.fg })
    
    -- テーブル用ハイライト
    vim.api.nvim_set_hl(0, "RenderMDTableBorder", { fg = "#444444" })
    vim.api.nvim_set_hl(0, "RenderMDTableHead", { bg = "#2d2d2d", bold = true })
end

function M.render()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].filetype ~= "markdown" then return end

    local config = require("render-md").config
    setup_highlights()
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    local parser = vim.treesitter.get_parser(bufnr, "markdown")
    if not parser then return end
    local tree = parser:parse()[1]
    local root = tree:root()

    local query = vim.treesitter.query.parse("markdown", [[
        (atx_heading) @heading
        (list_item) @item
        (block_quote) @quote
        (fenced_code_block) @code
        (pipe_table) @table
    ]])

    for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
        local capture_name = query.captures[id]
        local start_row, start_col, end_row, end_col = node:range()

        if capture_name == "heading" then
            local level = 0
            local marker_node = nil
            for i = 0, node:child_count() - 1 do
                local child = node:child(i)
                if child:type():find("atx_h%d_marker") then
                    marker_node = child
                    level = tonumber(child:type():match("%d"))
                    break
                end
            end
            if marker_node and level > 0 then
                local hl_group = "RenderMDH" .. level
                local msr, msc, mer, mec = marker_node:range()
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
                    end_row = start_row, end_col = end_col,
                    hl_group = hl_group, hl_eol = true,
                })
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, msr, msc, {
                    end_col = mec, conceal = "",
                    virt_text = { { string.rep(" ", level - 1) .. config.icons["h" .. level], hl_group } },
                    virt_text_pos = "inline",
                })
            end

        elseif capture_name == "item" then
            for i = 0, node:child_count() - 1 do
                local child = node:child(i)
                if child:type() == "-" or child:type() == "*" or child:type():find("marker") then
                    local csr, csc, cer, cec = child:range()
                    local is_task = false
                    local next_child = node:child(i + 1)
                    if next_child and next_child:type():find("task_list_marker") then
                        is_task = true
                        local icon = next_child:type():find("unchecked") and config.icons.unchecked or config.icons.checked
                        local tsr, tsc, ter, tec = next_child:range()
                        vim.api.nvim_buf_set_extmark(bufnr, ns_id, csr, csc, { end_col = cec, conceal = "" })
                        vim.api.nvim_buf_set_extmark(bufnr, ns_id, tsr, tsc, {
                            end_col = tec, conceal = "",
                            virt_text = { { icon, "RenderMDCheckbox" } },
                            virt_text_pos = "inline",
                        })
                    end
                    if not is_task then
                        vim.api.nvim_buf_set_extmark(bufnr, ns_id, csr, csc, {
                            end_col = cec, conceal = "",
                            virt_text = { { " " .. config.icons.bullet, "RenderMDBullet" } },
                            virt_text_pos = "inline",
                        })
                    end
                    break
                end
            end

        elseif capture_name == "table" then
            -- テーブルの各行をループ
            for row_node in node:iter_children() do
                local r_sr, r_sc, r_er, r_ec = row_node:range()
                local r_type = row_node:type()

                if r_type == "pipe_table_header" then
                    vim.api.nvim_buf_set_extmark(bufnr, ns_id, r_sr, 0, {
                        end_row = r_sr, end_col = r_ec,
                        hl_group = "RenderMDTableHead", hl_eol = true,
                    })
                end

                -- | 記号を罫線に置換
                for cell_child in row_node:iter_children() do
                    if cell_child:type() == "|" then
                        local c_sr, c_sc, c_er, c_ec = cell_child:range()
                        vim.api.nvim_buf_set_extmark(bufnr, ns_id, c_sr, c_sc, {
                            end_col = c_ec, conceal = "",
                            virt_text = { { "│", "RenderMDTableBorder" } },
                            virt_text_pos = "overlay",
                        })
                    end
                end
                
                -- デリミタ行（|---|）の処理
                if r_type == "pipe_table_delimiter_row" then
                    -- 行全体を conceal して、仮想テキストで一本の線にする
                    vim.api.nvim_buf_set_extmark(bufnr, ns_id, r_sr, r_sc, {
                        end_row = r_sr, end_col = r_ec,
                        conceal = "",
                        virt_text = { { string.rep("─", r_ec - r_sc), "RenderMDTableBorder" } },
                        virt_text_pos = "overlay",
                    })
                end
            end

        elseif capture_name == "quote" then
            local first_child = node:child(0)
            if first_child and (first_child:type() == ">" or first_child:type():find("marker")) then
                local qsr, qsc, qer, qec = first_child:range()
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, qsr, qsc, {
                    end_col = qec, conceal = "",
                    virt_text = { { config.icons.quote, "RenderMDQuote" } },
                    virt_text_pos = "inline",
                })
            end

        elseif capture_name == "code" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
                end_row = end_row, hl_group = "RenderMDCode", hl_eol = true,
            })
        end
    end

    -- インライン装飾の処理（略）
    local inline_parser = vim.treesitter.get_parser(bufnr, "markdown_inline")
    if inline_parser then
        local inline_tree = inline_parser:parse()[1]
        local inline_query = vim.treesitter.query.parse("markdown_inline", [[
            (emphasis) @em
            (strong_emphasis) @strong
            (strikethrough) @strike
            (code_span) @code_delim
        ]])
        for id, node, _ in inline_query:iter_captures(inline_tree:root(), bufnr, 0, -1) do
            local name = inline_query.captures[id]
            local s_r, s_c, e_r, e_c = node:range()
            local offset = (name == "strong" or name == "strike") and 2 or 1
            if name == "code_delim" then
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, s_r, s_c, { end_col = s_c + 1, conceal = "" })
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, e_r, e_c - 1, { end_col = e_c, conceal = "" })
            else
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, s_r, s_c, { end_col = s_c + offset, conceal = "" })
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, e_r, e_c - offset, { end_col = e_c, conceal = "" })
            end
        end
    end
end

return M
