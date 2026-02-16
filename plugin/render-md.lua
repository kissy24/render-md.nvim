if vim.g.loaded_render_md then
    return
end
vim.g.loaded_render_md = 1

vim.api.nvim_create_user_command("RenderMDEnable", function()
    require("render-md").enable()
end, {})

vim.api.nvim_create_user_command("RenderMDDisable", function()
    require("render-md").disable()
end, {})

vim.api.nvim_create_user_command("RenderMDToggle", function()
    require("render-md").toggle()
end, {})
