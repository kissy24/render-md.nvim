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
        h2 = "󰉫 ",
        h3 = "󰉫 ",
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
    -- Markdown設定の適用
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
            vim.opt_local.conceallevel = 2
            vim.opt_local.concealcursor = "nc"
        end
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
        group = vim.api.nvim_create_augroup("RenderMD", { clear = true }),
        pattern = "*.md",
        callback = function()
            require("render-md.core").render()
        end,
    })
    
    -- 現在のバッファがMarkdownなら即座にレンダリング
    if vim.bo.filetype == "markdown" then
        vim.opt_local.conceallevel = 2
        vim.opt_local.concealcursor = "nc"
        require("render-md.core").render()
    end
end

function M.disable()
    M.config.enabled = false
    vim.api.nvim_clear_autocmds({ group = "RenderMD" })
    
    local bufnr = vim.api.nvim_get_current_buf()
    local ns_id = vim.api.nvim_create_namespace("render-md")
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    
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
