local M = {}

M.ns_id = vim.api.nvim_create_namespace("render-md")

-- ============================================================
-- ハイライト設定
-- ============================================================

local function setup_highlights(config)
    local h = config.highlights
    vim.api.nvim_set_hl(0, "RenderMDH1", { bg = h.h1.bg, fg = h.h1.fg, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDH2", { bg = h.h2.bg, fg = h.h2.fg, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDH3", { bg = h.h3.bg, fg = h.h3.fg, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDBullet", { fg = h.bullet.fg, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDQuote", { fg = h.quote.fg, italic = true })
    vim.api.nvim_set_hl(0, "RenderMDCode", { bg = h.code.bg })
    vim.api.nvim_set_hl(0, "RenderMDCheckbox", { fg = h.checkbox.fg })
end

-- ============================================================
-- ハンドラー群
-- 将来的に require("render-md.handlers.heading") 等に切り出せる形
-- シグネチャ: handler(bufnr, ns_id, node, config, state)
-- ============================================================

local handlers = {}

function handlers.heading(bufnr, ns_id, node, config, _state)
    local start_row, _, _, end_col = node:range()
    local level = 0
    local marker_node = nil

    for i = 0, node:child_count() - 1 do
        local child = node:child(i)
        local c_type = child:type()
        if c_type:find("atx_h%d_marker") then
            marker_node = child
            level = tonumber(c_type:match("%d"))
            break
        end
    end

    if not (marker_node and level > 0) then return end

    local hl_group = "RenderMDH" .. level
    local icon = config.icons["h" .. level] or config.icons.h1

    vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
        end_row = start_row,
        end_col = end_col,
        hl_group = hl_group,
        hl_eol = true,
    })

    local msr, msc, _, mec = marker_node:range()
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, msr, msc, {
        end_col = mec,
        conceal = "",
        virt_text = { { string.rep(" ", level - 1) .. icon, hl_group } },
        virt_text_pos = "inline",
    })
end

function handlers.item(bufnr, ns_id, node, config, state)
    local parent = node:parent()
    if not parent then return end
    local parent_id = parent:id()

    for i = 0, node:child_count() - 1 do
        local child = node:child(i)
        local c_type = child:type()
        local is_marker = (c_type == "-" or c_type == "*" or c_type == "+" or c_type:find("marker"))
        if not is_marker then goto continue end

        local csr, csc, _, cec = child:range()
        local marker_text = vim.api.nvim_buf_get_text(bufnr, csr, csc, csr, cec, {})[1]

        -- タスクリストチェック
        local next_child = node:child(i + 1)
        if next_child and next_child:type():find("task_list_marker") then
            local icon = next_child:type():find("unchecked") and config.icons.unchecked or config.icons.checked
            local tsr, tsc, _, tec = next_child:range()
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, csr, csc, { end_col = cec, conceal = "" })
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, tsr, tsc, {
                end_col = tec,
                conceal = "",
                virt_text = { { icon, "RenderMDCheckbox" } },
                virt_text_pos = "inline",
            })
            break
        end

        -- 順序付きリスト
        if marker_text:match("^%s*%d+[%.%)]") then
            if state.ordered_list_counters[parent_id] then
                state.ordered_list_counters[parent_id] = state.ordered_list_counters[parent_id] + 1
            else
                state.ordered_list_counters[parent_id] = tonumber(marker_text:match("%d+"))
            end
            local suffix = marker_text:match("[%.%)]") or "."
            local virt_text = tostring(state.ordered_list_counters[parent_id]) .. suffix
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, csr, csc, {
                end_col = cec,
                conceal = "",
                virt_text = { { virt_text, "RenderMDBullet" } },
                virt_text_pos = "inline",
            })
        else
            -- 通常の箇条書き
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, csr, csc, {
                end_col = cec,
                conceal = "",
                virt_text = { { " " .. config.icons.bullet, "RenderMDBullet" } },
                virt_text_pos = "inline",
            })
        end
        break

        ::continue::
    end
end

function handlers.table(bufnr, ns_id, node, _config, _state)
    for row_node in node:iter_children() do
        local r_sr, _, _, r_ec = row_node:range()
        local r_type = row_node:type()

        if r_type == "pipe_table_header" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, r_sr, 0, {
                end_row = r_sr,
                end_col = r_ec,
                hl_group = "RenderMDTableHead",
                hl_eol = true,
            })
        end

        for cell_child in row_node:iter_children() do
            if cell_child:type() == "|" then
                local c_sr, c_sc, _, c_ec = cell_child:range()
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, c_sr, c_sc, {
                    end_col = c_ec,
                    conceal = "",
                    virt_text = { { "│", "RenderMDTableBorder" } },
                    virt_text_pos = "overlay",
                })
            end
        end

        if r_type == "pipe_table_delimiter_row" then
            local r_sr2, r_sc, _, r_ec2 = row_node:range()
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, r_sr2, r_sc, {
                end_row = r_sr2,
                end_col = r_ec2,
                conceal = "",
                virt_text = { { string.rep("─", r_ec2 - r_sc), "RenderMDTableBorder" } },
                virt_text_pos = "overlay",
            })
        end
    end
end

function handlers.quote(bufnr, ns_id, node, config, _state)
    local start_row, start_col, end_row, _ = node:range()

    for row = start_row, end_row - 1 do
        local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
        if not line then goto continue end

        local col = start_col
        while col < #line and line:sub(col + 1, col + 1) == " " do
            col = col + 1
        end

        if line:sub(col + 1, col + 1) == ">" then
            local marker_end = col + 1
            if marker_end < #line and line:sub(marker_end + 1, marker_end + 1) == " " then
                marker_end = marker_end + 1
            end
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, col, {
                end_col = marker_end,
                conceal = "",
                virt_text = { { config.icons.quote, "RenderMDQuote" } },
                virt_text_pos = "inline",
            })
        end

        ::continue::
    end
end

function handlers.code(bufnr, ns_id, node, _config, _state)
    local start_row, _, end_row, _ = node:range()
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
        end_row = end_row, hl_group = "RenderMDCode", hl_eol = true,
    })
end

-- ============================================================
-- インライン装飾（将来 handlers.inline として切り出し可能）
-- ============================================================

local function render_inline(bufnr, ns_id)
    local inline_parser = vim.treesitter.get_parser(bufnr, "markdown_inline")
    if not inline_parser then return end

    local inline_query = vim.treesitter.query.parse("markdown_inline", [[
        (emphasis)         @em
        (strong_emphasis)  @strong
        (strikethrough)    @strike
        (code_span)        @code_delim
    ]])

    for id, node, _ in inline_query:iter_captures(inline_parser:parse()[1]:root(), bufnr, 0, -1) do
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

-- ============================================================
-- ブロッククエリ定義（将来 config 化も可能）
-- ============================================================

local BLOCK_QUERY = nil
-- capture名 → ハンドラー のマッピング
local CAPTURE_HANDLERS = {
    heading = handlers.heading,
    item    = handlers.item,
    quote   = handlers.quote,
    code    = handlers.code,
    table   = handlers.table,
}

-- ============================================================
-- パブリック API
-- ============================================================

function M.clear(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
end

function M.render()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].filetype ~= "markdown" then return end
    if vim.api.nvim_get_mode().mode == "i" then return end

    if not BLOCK_QUERY then
        BLOCK_QUERY = vim.treesitter.query.parse("markdown", [[
            (atx_heading)       @heading
            (list_item)         @item
            (block_quote)       @quote
            (fenced_code_block) @code
            (pipe_table)        @table
        ]])
    end

    local config = require("render-md").config
    setup_highlights(config)
    M.clear(bufnr)

    local parser = vim.treesitter.get_parser(bufnr, "markdown")
    if not parser then return end

    local root = parser:parse()[1]:root()

    -- レンダリング中に使う共有状態
    local state = {
        ordered_list_counters = {},
    }

    for id, node, _ in BLOCK_QUERY:iter_captures(root, bufnr, 0, -1) do
        local capture_name = BLOCK_QUERY.captures[id]
        local handler = CAPTURE_HANDLERS[capture_name]
        if handler then
            handler(bufnr, M.ns_id, node, config, state)
        end
    end

    render_inline(bufnr, M.ns_id)
end

return M
