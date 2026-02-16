local M = {}

local ns_id = vim.api.nvim_create_namespace("render-md")

local function setup_highlights()
    local h = {
        h1 = "#ffaf00",
        h2 = "#00afff",
        h3 = "#5fff00",
    }
    vim.api.nvim_set_hl(0, "RenderMDH1", { fg = h.h1, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDH2", { fg = h.h2, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDH3", { fg = h.h3, bold = true })
    vim.api.nvim_set_hl(0, "RenderMDDecoration", { fg = "#666666" }) -- 囲み記号の色
end

function M.render()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].filetype ~= "markdown" then return end

    setup_highlights()
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    local parser = vim.treesitter.get_parser(bufnr, "markdown")
    if not parser then return end
    local tree = parser:parse()[1]
    local root = tree:root()

    -- キャプチャ名に頼らず、すべての atx_heading を取得
    local query = vim.treesitter.query.parse("markdown", [[
        (atx_heading) @heading
        (list_item (list_marker_dash) @bullet)
        (task_list_marker_unchecked) @unchecked
        (task_list_marker_checked) @checked
    ]])

    for _, node, _ in query:iter_captures(root, bufnr, 0, -1) do
        local type = node:type()
        local start_row, start_col, end_row, end_col = node:range()

        if type == "atx_heading" then
            -- 子ノードを走査してマーカーと内容を特定
            local marker_node = nil
            local inline_node = nil
            local level = 0

            for i = 0, node:child_count() - 1 do
                local child = node:child(i)
                local child_type = child:type()
                if child_type:find("atx_h%d_marker") then
                    marker_node = child
                    level = tonumber(child_type:match("%d"))
                elseif child_type == "inline" then
                    inline_node = child
                end
            end

            if marker_node and level > 0 then
                local m_s_r, m_s_c, m_e_r, m_e_c = marker_node:range()
                local hl_group = "RenderMDH" .. level
                local sym = level == 1 and "===" or (level == 2 and "---" or "___")

                -- 開始記号 (=== )
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, m_s_r, m_s_c, {
                    virt_text = { { sym .. " ", "RenderMDDecoration" } },
                    virt_text_pos = "overlay",
                    conceal = "",
                })

                -- 終了記号 ( ===)
                if inline_node then
                    local i_s_r, i_s_c, i_e_r, i_e_c = inline_node:range()
                    vim.api.nvim_buf_set_extmark(bufnr, ns_id, i_e_r, i_e_c, {
                        virt_text = { { " " .. sym, "RenderMDDecoration" } },
                        virt_text_pos = "inline",
                    })
                end
            end

        elseif type == "list_marker_dash" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
                virt_text = { { "  • ", "RenderMDBullet" } },
                virt_text_pos = "overlay",
                conceal = "",
            })
        elseif type == "task_list_marker_unchecked" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
                virt_text = { { " ☐ ", "RenderMDCheckbox" } },
                virt_text_pos = "overlay",
                conceal = "",
            })
        elseif type == "task_list_marker_checked" then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
                virt_text = { { " ☑ ", "RenderMDCheckbox" } },
                virt_text_pos = "overlay",
                conceal = "",
            })
        end
    end
end

return M
