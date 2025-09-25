local M = {}

local function define_highlights()
    local highlights = {
        -- Main Sections
        ["@candela.log.date"] = "Constant",
        ["@candela.log.time"] = "Function",
        ["@candela.log.host"] = "Type",
        ["@candela.log.facility"] = "Title",
        ["@candela.log.process"] = "Tag",
        ["@candela.log.body"] = "Normal",

        -- Log levels
        ["@candela.log.level.fatal"] = "ErrorMsg",
        ["@candela.log.level.error"] = "Error",
        ["@candela.log.level.warning"] = "WarningMsg",
        ["@candela.log.level.info"] = "Repeat",
        ["@candela.log.level.debug"] = "Debug",
        ["@candela.log.level.trace"] = "Comment",

        -- Types
        ["@candela.log.type.int"] = "Number",
        ["@candela.log.type.bin"] = "Number",
        ["@candela.log.type.oct"] = "Number",
        ["@candela.log.type.hex"] = "Number",
        ["@candela.log.type.float"] = "Float",
        ["@candela.log.type.bool"] = "Boolean",
        ["@candela.log.type.null"] = "Constant",
        ["@candela.log.type.char"] = "Character",
        ["@candela.log.type.string"] = "String",

        -- Entities
        ["@candela.log.entity.url"] = "Underlined",
        ["@candela.log.entity.domain"] = "Identifier",
        ["@candela.log.entity.uuid"] = "Label",
        ["@candela.log.entity.path"] = "Directory",
        ["@candela.log.entity.md5"] = "Label",
        ["@candela.log.entity.sha"] = "Label",
        ["@candela.log.entity.ipv4"] = "Special",
        ["@candela.log.entity.ipv6"] = "Special",
        ["@candela.log.entity.mac"] = "Special",

        -- Special
        ["@candela.log.separator"] = "Comment",
        ["@candela.log.symbol"] = "Operator",
    }

    for group, link in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, { link = link })
    end
end

local function attach_syntax(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- Regex for each highlight group
    local syntax = {
        -- TODO: continue from here with patterns
        { "vim.api", "@candela.log.date" },
    }

    local ns = vim.api.nvim_create_namespace("CandelaSyntax")
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    -- Apply per line
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for lnum, line in ipairs(lines) do
        for _, pat in ipairs(syntax) do
            local regex, hl_group = pat[1], pat[2]
            local s, e, _ = line:find(regex)
            if s and e then
                vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, s - 1, {
                    end_col = e,
                    hl_group = hl_group,
                })
            end
        end
    end
end

function M.setup()
    define_highlights()

    -- Autocmd to apply on log files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "lua",
        callback = function(args)
            attach_syntax(args.buf)
        end,
    })
end

return M
