if vim.g.loaded_candela then
    return
end
vim.g.loaded_candela = true

vim.api.nvim_create_user_command("Candela", function(args)
    require("candela").cmd(args)
end, {
    nargs = "*",
    desc = "Candela regex highlighter",
    complete = function(arglead, cmdline, cursorpos)
        return require("candela").complete(arglead, cmdline, cursorpos)
    end,
    bang = true,
})

local plugs = {
    {
        "<Plug>CandelaUI",
        function()
            require("candela.ui").toggle()
        end,
    },
    {
        "<Plug>CandelaHelp",
        function()
            require("candela.ui").help()
        end,
    },
    {
        "<Plug>CandelaRefresh",
        function()
            require("candela.highlighter").refresh()
            require("candela.highlighter").refresh_ui()
        end,
    },
    {
        "<Plug>CandelaClear",
        function()
            require("candela.highlighter").remove_all()
            require("candela.patterns").clear()
            require("candela.highlighter").refresh_ui()
        end,
    },
    {
        "<Plug>CandelaLightbox",
        function()
            require("candela.lightbox").toggle()
        end,
    },
}

for _, plug in ipairs(plugs) do
    vim.keymap.set("n", plug[1], function()
        require("candela").ensure_init()
        plug[2]()
    end, { silent = true })
end
