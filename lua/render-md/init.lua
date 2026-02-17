local M = {}

M.config = {
    enabled = true,
    highlights = {
        h1 = { bg = "#3d2b1f", fg = "#ffaa88" },
        h2 = { bg = "#1f2b3d", fg = "#88aaff" },
        h3 = { bg = "#2b3d1f", fg = "#aaff88" },
        bullet = { fg = "#569cd6" },
        quote = { fg = "#6a9955" },
        checkbox = { fg = "#ce9178" },
        code = { bg = "#1e1e1e" },
    },
    icons = {
        h1 = "󰉫 ",
        h2 = "󰉬 ",
        h3 = "󰉭 ",
        bullet = "• ",
        unchecked = "☐ ",
        checked = "☑ ",
        quote = "▎",
        code = "󰨰 ",
    }
}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    
    if M.config.enabled then
        M.enable()
    end
end

function M.enable()
    M.config.enabled = true
    local group = vim.api.nvim_create_augroup("RenderMD", { clear = true })

    -- インサートモード突入時：バッファ全体の装飾を消去
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = group,
        pattern = "*.md",
        callback = function()
            require("render-md.core").clear()
            vim.opt_local.conceallevel = 0
        end,
    })

    -- インサートモード脱出時：再描画
    vim.api.nvim_create_autocmd("InsertLeave", {
        group = group,
        pattern = "*.md",
        callback = function()
            vim.opt_local.conceallevel = 2
            vim.opt_local.concealcursor = ""
            require("render-md.core").render()
        end,
    })

    -- 通常の更新（ノーマルモード時のみ）
    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
        group = group,
        pattern = "*.md",
        callback = function()
            if vim.api.nvim_get_mode().mode ~= "i" then
                vim.opt_local.conceallevel = 2
                vim.opt_local.concealcursor = ""
                require("render-md.core").render()
            end
        end,
    })
    
    -- 初期表示設定
    if vim.bo.filetype == "markdown" then
        if vim.api.nvim_get_mode().mode ~= "i" then
            vim.opt_local.conceallevel = 2
            vim.opt_local.concealcursor = ""
            require("render-md.core").render()
        else
            vim.opt_local.conceallevel = 0
        end
    end
end

function M.disable()
    M.config.enabled = false
    vim.api.nvim_clear_autocmds({ group = "RenderMD" })
    require("render-md.core").clear()
    vim.opt_local.conceallevel = 0
end

function M.toggle()
    if M.config.enabled then
        M.disable()
    else
        M.enable()
    end
end

return M
