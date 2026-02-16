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
    vim.api.nvim_set_hl(0, "RenderMDDecoration", { fg = "#666666" })
    vim.api.nvim_set_hl(0, "RenderMDBullet", { fg = "#569cd6", bold = true })
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

    -- エラーを避けるため、確実に存在するノードだけをクエリする
    local query = vim.treesitter.query.parse("markdown", [[
        (atx_heading) @heading
        (list_item) @item
    ]])

    for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
        local capture_name = query.captures[id]
        local start_row, start_col, end_row, end_col = node:range()

        if capture_name == "heading" then
            local level = 0
            local marker_node = nil
            local inline_node = nil

            -- 子ノードを走査して構造を把握
            for i = 0, node:child_count() - 1 do
                local child = node:child(i)
                if child:type():find("atx_h%d_marker") then
                    marker_node = child
                    level = tonumber(child:type():match("%d"))
                elseif child:type() == "inline" then
                    inline_node = child
                end
            end

            if marker_node and level > 0 then
                local hl_group = "RenderMDH" .. level
                local sym = level == 1 and "===" or (level == 2 and "---" or "___")
                
                -- マーカー (#) を開始記号 (=== ) で上書き
                local msr, msc, mer, mec = marker_node:range()
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, msr, msc, {
                    virt_text = { { sym .. " ", "RenderMDDecoration" } },
                    virt_text_pos = "overlay",
                    conceal = "",
                })

                -- 内容の末尾に終了記号 ( ===) を追加
                if inline_node then
                    local isr, isc, ier, iec = inline_node:range()
                    vim.api.nvim_buf_set_extmark(bufnr, ns_id, ier, iec, {
                        virt_text = { { " " .. sym, "RenderMDDecoration" } },
                        virt_text_pos = "inline",
                    })
                end
            end

        elseif capture_name == "item" then
            -- リストアイテムの最初の文字（マーカー）を特定
            for i = 0, node:child_count() - 1 do
                local child = node:child(i)
                local c_type = child:type()
                -- パーサーによって '-' だったり 'list_marker' だったりするため柔軟に判定
                if c_type == "-" or c_type == "*" or c_type:find("marker") then
                    local csr, csc, cer, cec = child:range()
                    
                    -- チェックボックスかどうかの判定
                    local is_checkbox = false
                    local next_child = node:child(i + 1)
                    if next_child and next_child:type():find("task_list_marker") then
                        is_checkbox = true
                    end

                    if not is_checkbox then
                        vim.api.nvim_buf_set_extmark(bufnr, ns_id, csr, csc, {
                            virt_text = { { "  • ", "RenderMDBullet" } },
                            virt_text_pos = "overlay",
                            conceal = "",
                        })
                    end
                    break
                end
            end
        end
    end
end

return M
