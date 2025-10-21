-- Derived from log-highlight.nvim by Fei Shao (fei6409 on GitHub)
-- https://github.com/fei6409/log-highlight.nvim

local M = {}
M.enabled = false
local CANDELA_AUGROUP = require("candela.init").CANDELA_AUGROUP

local function apply()
    for _, cmd in ipairs(M.syntax_commands) do
        vim.api.nvim_exec2(cmd, {})
    end
end

function M.enable(opts)
    vim.api.nvim_exec2("syntax enable", {})

    M.syntax_groups = {
        -- Dates/Times
        ["CandelaLogSysDate"] = "Function",
        ["CandelaLogSysDay"] = "Function",
        ["CandelaLogSysTime"] = "Conditional",
        ["CandelaLogSysTimeAMPM"] = "Conditional",
        ["CandelaLogSysTimeZone"] = "Conditional",
        ["CandelaLogSysTimeDuration"] = "Conditional",
        -- System info
        ["CandelaLogSysHost"] = "Tag",
        ["CandelaLogSysFacility"] = "Winbar",
        ["CandelaLogSysProcess"] = "Title",
        -- Special
        ["CandelaLogSysSeparator"] = "Comment",
        ["CandelaLogSysSymbol"] = "Operator",

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
        ["CandelaLogTypeChar"] = "Character",
        ["CandelaLogTypeString"] = "String",
        ["CandelaLogTypeBool"] = "Boolean",
        ["CandelaLogTypeNull"] = "Constant",

        -- Entities
        ["CandelaLogEntityUrl"] = "Underlined",
        ["CandelaLogEntityDns"] = "Removed",
        ["CandelaLogEntityUuid"] = "Label",
        ["CandelaLogEntityPath"] = "Directory",
        ["CandelaLogEntityMd5"] = "Label",
        ["CandelaLogEntitySha"] = "Label",
        ["CandelaLogEntityIpv4"] = "Special",
        ["CandelaLogEntityIpv6"] = "Special",
        ["CandelaLogEntityMac"] = "Special",
    }

    M.syntax_commands = {
        -- Dates
        [=[syntax match CandelaLogSysDate '\<\d\{2}[-/]\d\{2}\>']=],
        [=[syntax match CandelaLogSysDate '\<\d\{4}[-/]\d\{2}[-/]\d\{2}\>']=],
        [=[syntax match CandelaLogSysDate '\<\d\{2}[-/]\d\{2}[-/]\d\{4}\>']=],
        [=[syntax match CandelaLogSysDate '\<\d\{4}-\d\{2}-\d\{2}T']=],
        [=[syntax match CandelaLogSysDate '\<\a\{3} \d\{1,2}\(,\? \d\{4}\)\?\>']=],
        [=[syntax match CandelaLogSysDate '\<\d\{1,2}[- ]\a\{3}[- ]\d\{4}\>']=],
        -- Weekdays
        [=[syntax keyword CandelaLogSysDay Mon Tue Wed Thu Fri Sat Sun]=],
        -- Time
        [=[syntax match CandelaLogSysTime '\%(^\|\s\)\zs\d\{2}:\d\{2}:\d\{2}\(\.\d\{2,6}\)\?\ze\%(\s\|$\)' contains=CandelaLogSysTimeZone,CandelaLogSysTimeAMPM nextgroup=CandelaLogSysHost skipwhite]=],
        [=[syntax match CandelaLogSysTimeAMPM '\cAM\|\cPM\>' contained skipwhite nextgroup=CandelaLogSysHost]=],
        [=[syntax match CandelaLogSysTimeZone 'Z\|[+-]\d\{2}:\d\{2}\|\a\{3}\>' contained skipwhite nextgroup=CandelaLogSysHost]=],
        [=[syntax match CandelaLogSysTimeDuration '\(\(\(\d\+d\)\?\d\+h\)\?\d\+m\)\?\d\+\(\.\d\+\)\?[mun]\?s\>']=],
        -- System info
        [=[syntax match CandelaLogSysHost '\<[[:alnum:]\._-]\+\>' contained skipwhite nextgroup=CandelaLogSysFacility,CandelaLogSysProcess]=],
        [=[syntax match CandelaLogSysFacility '\<[[:alnum:]]\+\.[[:alnum:]]\+\>' contained skipwhite contains=@CandelaLogLevels nextgroup=CandelaLogSysProcess]=],
        [=[syntax match CandelaLogSysProcess '\<[[:alnum:]\._-]\+\%(([^)]\+)\)\?\%(\[[[:digit:]]\+\]\)\?:' contained skipwhite contains=CandelaLogTypeInt]=],
        -- Symbols/separators
        [=[syntax match CandelaLogSysSymbol '[!@#$%^&*;:?]']=],
        [=[syntax match CandelaLogSysSeparator '-\{3,}\|=\{3,}\|#\{3,}\|\*\{3,}\|<\{3,}\|>\{3,}']=],

        -- Log Levels
        [=[syntax keyword CandelaLogLevelFatal containedin=CandelaLogSysFacility FATAL Fatal fatal]=],
        [=[syntax keyword CandelaLogLevelError containedin=CandelaLogSysFacility E ERR[ORS] Err[ors] err[ors]]=],
        [=[syntax keyword CandelaLogLevelWarning containedin=CandelaLogSysFacility W WARN[ING] Warn[ing] warn[ing]]=],
        [=[syntax keyword CandelaLogLevelInfo containedin=CandelaLogSysFacility I INFO Info info]=],
        [=[syntax keyword CandelaLogLevelDebug containedin=CandelaLogSysFacility D DEBUG Debug debug DBG Dbg dbg]=],
        [=[syntax keyword CandelaLogLevelTrace containedin=CandelaLogSysFacility TRACE Trace trace]=],
        [=[syntax cluster CandelaLogLevels contains=CandelaLogLevelFatal,CandelaLogLevelError,CandelaLogLevelWarning,CandelaLogLevelInfo,CandelaLogLevelDebug,CandelaLogLevelTrace]=],

        -- Objects / Entities
        [=[syntax match CandelaLogEntityUrl '\<https\?:\/\/\S\+']=],
        [=[syntax match CandelaLogEntityDns '\<[a-zA-Z0-9_-]\+\(\.[a-zA-Z0-9_-]\+\)\{1,}\>']=],
        [=[syntax match CandelaLogEntityMac '\<\x\{2}\([:-]\?\x\{2}\)\{5}\>']=],
        [=[syntax match CandelaLogEntityIpv4 '\<\d\{1,3}\(\.\d\{1,3}\)\{3}\(\/\d\+\)\?\>']=],
        [=[syntax match CandelaLogEntityIpv6 '\<\x\{1,4}\(:\x\{1,4}\)\{7}\(\/\d\+\)\?\>']=],
        [=[syntax match CandelaLogEntityUuid '\<\x\{8}-\x\{4}-\x\{4}-\x\{4}-\x\{12}\>']=],
        [=[syntax match CandelaLogEntityMd5 '\<\x\{32}\>']=],
        [=[syntax match CandelaLogEntitySha '\<\(\x\{40}\|\x\{56}\|\x\{64}\|\x\{96}\|\x\{128}\)\>']=],
        [=[syntax match CandelaLogEntityPath '\(^\|\s\|=\)\zs\(\.\{0,2}\|\~\)\/[^ \t\n\r]\+\ze']=],
        [=[syntax match CandelaLogEntityPath '\(^\|\s\|=\)\zs\a:\\[^ \t\n\r]\+\ze']=],
        [=[syntax match CandelaLogEntityPath '\(^\|\s\|=\)\zs\\\\[^ \t\n\r]\+\ze']=],

        -- Strings
        [=[syntax region CandelaLogTypeString start=/"/ end=/"/ end=/$/ skip=/\\./]=],
        [=[syntax region CandelaLogTypeString start=/`/ end=/`/ end=/$/ skip=/\\./]=],
        [=[syntax region CandelaLogTypeString start=/\(s\)\@<!'\(s \|t \)\@!/ end=/'/ end=/$/ skip=/\\./]=],

        -- Numbers
        [=[syntax match CandelaLogTypeInt '\<\d\+\>' contained]=],
        [=[syntax match CandelaLogTypeBin '\<0[bB][01]\+\>' contained]=],
        [=[syntax match CandelaLogTypeOct '\<0[oO]\o\+\>' contained]=],
        [=[syntax match CandelaLogTypeHex '\<0[xX]\x\+\>' contained]=],
        [=[syntax match CandelaLogTypeHex '\<\x\{4,}\>' contained]=],
        [=[syntax match CandelaLogTypeInt '\'\d\d\+\>' contained]=],
        [=[syntax match CandelaLogTypeBin '\'\b[01]\+\>' contained]=],
        [=[syntax match CandelaLogTypeOct '\'\o\o\+\>' contained]=],
        [=[syntax match CandelaLogTypeHex '\'\h\x\+\>' contained]=],
        [=[syntax match CandelaLogTypeFloat '\<\d\+\.\d\+\([eE][+-]\?\d\+\)\?\>' contained]=],

        -- Constants
        [=[syntax keyword CandelaLogTypeBool TRUE True true FALSE False false]=],
        [=[syntax keyword CandelaLogTypeNull NULL Null null]=],
    }

    local extensions = {}
    local types = {}
    local ext_regex = "^%.[%w%.]+$" -- matching file extension with one or more parts e.g. .log or .foo.bar
    local type_regex = "^%w+$" -- matching file type e.g. text or rust
    for _, filetype in ipairs(opts.file_types) do
        if filetype:match(ext_regex) ~= nil then
            table.insert(extensions, "*" .. filetype)
        elseif filetype:match(type_regex) ~= nil then
            table.insert(types, filetype)
        else
            vim.notify(
                string.format(
                    '[Candela] invalid file type "%s" in syntax_highlighting.file_types, must be in the form ".<ext>" or <filetype>',
                    filetype
                ),
                vim.log.levels.WARN
            )
        end
    end

    -- Apply based on file extension
    M.ext_autocmd = vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        group = CANDELA_AUGROUP,
        pattern = extensions,
        callback = function()
            vim.api.nvim_exec2("setlocal nospell", {})
            for name, link in pairs(M.syntax_groups) do
                vim.cmd(string.format("highlight default link %s %s", name, link))
            end
            apply()
        end,
    })

    M.type_autocmd = vim.api.nvim_create_autocmd("FileType", {
        group = CANDELA_AUGROUP,
        pattern = types,
        callback = function()
            vim.api.nvim_exec2("setlocal nospell", {})
            for name, link in pairs(M.syntax_groups) do
                vim.cmd(string.format("highlight default link %s %s", name, link))
            end
            apply()
        end,
    })

    M.enabled = true
end

return M
