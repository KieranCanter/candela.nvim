local M = {}

function M.enable(opts)
    vim.cmd("syntax enable")

    M.syntax_groups = {
        -- Main Sections
        ["CandelaLogDate"] = "Constant",
        ["CandelaLogTime"] = "Function",
        ["CandelaLogHost"] = "Type",
        ["CandelaLogFacility"] = "Title",
        ["CandelaLogProcess"] = "Tag",
        ["CandelaLogBody"] = "Normal",

        -- Log levels
        ["CandelaLogLevelFatal"] = "ErrorMsg",
        ["CandelaLogLevelError"] = "Error",
        ["CandelaLogLevelWarning"] = "WarningMsg",
        ["CandelaLogLevelInfo"] = "Repeat",
        ["CandelaLogLevelDebug"] = "Debug",
        ["CandelaLogLevelTrace"] = "Comment",

        -- Types
        ["CandelaLogTypeInt"] = "Number",
        ["CandelaLogTypeBin"] = "Number",
        ["CandelaLogTypeOct"] = "Number",
        ["CandelaLogTypeHex"] = "Number",
        ["CandelaLogTypeFloat"] = "Float",
        ["CandelaLogTypeBool"] = "Boolean",
        ["CandelaLogTypeNull"] = "Constant",
        ["CandelaLogTypeChar"] = "Character",
        ["CandelaLogTypeString"] = "String",

        -- Entities
        ["CandelaLogEntityUrl"] = "Underlined",
        ["CandelaLogEntityDomain"] = "Identifier",
        ["CandelaLogEntityUuid"] = "Label",
        ["CandelaLogEntityPath"] = "Directory",
        ["CandelaLogEntityMd5"] = "Label",
        ["CandelaLogEntitySha"] = "Label",
        ["CandelaLogEntityIpv4"] = "Special",
        ["CandelaLogEntityIpv6"] = "Special",
        ["CandelaLogEntityMac"] = "Special",

        -- Special
        ["CandelaLogSeparator"] = "Comment",
        ["CandelaLogSymbol"] = "Operator",
    }

    M.syntax = {
        -- Symbols / separators
        ["CandelaLogSymbol"] = { type = "match", pattern = "[!@#$%^&*;:?]" },
        ["CandelaLogSeparator"] = {
            type = "match",
            pattern = [[-\{3,}\|=\{3,}\|#\{3,}\|\*\{3,}\|<\{3,}\|>\{3,}]],
        },

        -- Strings
        ["CandelaLogTypeString"] = {
            { type = "region", start = [["]], ["end"] = [["]], skip = [[\\\.]] },
            { type = "region", start = [[`]], ["end"] = [[`]], skip = [[\\\.]] },
            { type = "region", start = [[\(s\)\@<!'\(s\|t\)\@!]], ["end"] = [[']], skip = [[\\\.]] },
        },
        ["CandelaLogTypeChar"] = { type = "region", start = [[']], ["end"] = [[']], skip = [[\\\.]] },

        -- Numbers
        ["CandelaLogTypeInt"] = { type = "match", pattern = [[\<\d\+\>]] },
        ["CandelaLogTypeFloat"] = { type = "match", pattern = [[\<\d\+\.\d\+\([eE][+-]\?\d\+\)\?\>]] },
        ["CandelaLogTypeBin"] = { type = "match", pattern = [[\<0[bB][01]\+\>]] },
        ["CandelaLogTypeOct"] = { type = "match", pattern = [[\<0[oO]\o\+\>]] },
        ["CandelaLogTypeHex"] = {
            { type = "match", pattern = [[\<0[xX]\x\+\>]] },
            { type = "match", pattern = [[\<\x\{4,}\>]] },
        },

        -- Constants
        ["CandelaLogTypeBool"] = {
            type = "keyword",
            keywords = { "TRUE", "True", "true", "FALSE", "False", "false" },
        },
        ["CandelaLogTypeNull"] = { type = "keyword", keywords = { "NULL", "Null", "null" } },

        -- Dates
        ["CandelaLogDate"] = {
            { type = "match", pattern = [[\<\d\{2}[-\/]\d\{2}\>]] },
            { type = "match", pattern = [[\<\d\{4}[-\/]\d\{2}[-\/]\d\{2}\>]] },
            { type = "match", pattern = [[\<\d\{2}[-\/]\d\{2}[-\/]\d\{4}\>]] },
            { type = "match", pattern = [[\<\d\{4}-\d\{2}-\d\{2}T]] },
            { type = "match", pattern = [[\<\a\{3} \d\{1,2}\(,\? \d\{4}\)\?\>]] },
            { type = "match", pattern = [[\<\d\{1,2}[- ]\a\{3}[- ]\d\{4}\>]] },
        },

        -- Times
        ["CandelaLogTime"] = { type = "match", pattern = [[\d\{2}:\d\{2}:\d\{2}\(\.\d\{2,6}\)\?]] },

        -- Entities
        ["CandelaLogEntityUrl"] = { type = "match", pattern = [[\<https\?:\/\/\S\+]] },
        ["CandelaLogEntityIpv4"] = { type = "match", pattern = [[\<\d\{1,3}\(\.\d\{1,3}\)\{3}\(\/\d\+\)\?\>]] },
        ["CandelaLogEntityIpv6"] = { type = "match", pattern = [[\<\x\{1,4}\(:\x\{1,4}\)\{7}\(\/\d\+\)\?\>]] },
        ["CandelaLogEntityMac"] = { type = "match", pattern = [[\<\x\{2}\([:-]\?\x\{2}\)\{5}\>]] },
        ["CandelaLogEntityUuid"] = { type = "match", pattern = [[\<\x\{8}-\x\{4}-\x\{4}-\x\{4}-\x\{12}\>]] },
        ["CandelaLogEntityMd5"] = { type = "match", pattern = [[\<\x\{32}\>]] },
        ["CandelaLogEntitySha"] = {
            type = "match",
            pattern = [[\<\(\x\{40}\|\x\{56}\|\x\{64}\|\x\{96}\|\x\{128}\)\>]],
        },
        ["CandelaLogEntityPath"] = {
            { type = "match", pattern = [[\(^\|\s\|=\)\zs\(\.\{0,2}\|\~\)\/[^ \t\n\r]\+\ze]] },
            { type = "match", pattern = [[\(^\|\s\|=\)\zs\a:\\[^ \t\n\r]\+\ze]] },
            { type = "match", pattern = [[\(^\|\s\|=\)\zs\\\\[^ \t\n\r]\+\ze]] },
        },

        -- Log levels
        ["CandelaLogLevelFatal"] = { type = "keyword", keywords = { "FATAL", "Fatal", "fatal" } },
        ["CandelaLogLevelError"] = { type = "keyword", keywords = { "ERROR", "Error", "error", "ERR", "Err", "err" } },
        ["CandelaLogLevelWarning"] = {
            type = "keyword",
            keywords = { "WARN", "Warn", "warn", "WARNING", "Warning", "warning" },
        },
        ["CandelaLogLevelInfo"] = { type = "keyword", keywords = { "INFO", "Info", "info" } },
        ["CandelaLogLevelDebug"] = { type = "keyword", keywords = { "DEBUG", "Debug", "debug", "DBG", "Dbg", "dbg" } },
        ["CandelaLogLevelTrace"] = { type = "keyword", keywords = { "TRACE", "Trace", "trace" } },
    }

    local filetypes = {}
    for _, ext in ipairs(opts.file_types) do
        table.insert(filetypes, "*." .. ext)
    end
    vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = filetypes,
        callback = function()
            M.apply()
            for name, link in pairs(M.syntax_groups) do
                vim.cmd(string.format("highlight default link %s %s", name, link))
            end
        end,
    })
end

---@class SynKeyword
---@field type "keyword"
---@field keywords string[]

---@class SynMatch
---@field type "match"
---@field pattern string

---@class SynRegion
---@field type "region"
---@field start string
---@field ["end"] string
---@field skip string

---@alias Syn
---| SynKeyword
---| SynMatch
---| SynRegion

---@param hl_group string: highlight group
---@param defs Syn|Syn[]
function M.apply_syntax(hl_group, defs)
    if type(defs[1]) ~= "table" then
        defs = { defs }
    end

    for _, def in pairs(defs) do
        if def.type == "match" then
            vim.cmd(string.format("syntax match %s '%s'", hl_group, def.pattern))
        elseif def.type == "region" then
            vim.cmd(
                string.format(
                    "syntax region %s start=/%s/ end=/%s/ skip=/%s/",
                    hl_group,
                    def.start,
                    def["end"],
                    def.skip
                )
            )
        elseif def.type == "keyword" then
            vim.cmd(string.format("syntax keyword %s %s", hl_group, table.concat(def.keywords, " ")))
        end
    end
end

function M.apply()
    -- Define syntax from table
    for hl_group, def in pairs(M.syntax) do
        M.apply_syntax(hl_group, def)
    end
end

return M
