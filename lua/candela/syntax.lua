-- Derived from log-highlight.nvim by Fei Shao (fei6409 on GitHub)
-- https://github.com/fei6409/log-highlight.nvim

local M = {}

function M.enable(opts)
    vim.cmd("syntax enable")

    M.syntax_groups = {
        -- Dates/Times
        ["CandelaLogDate"] = "Function",
        ["CandelaLogDay"] = "Function",
        ["CandelaLogTime"] = "Conditional",
        ["CandelaLogTimeAMPM"] = "Conditional",
        ["CandelaLogTimeZone"] = "Conditional",
        ["CandelaLogTimeDuration"] = "Conditional",

        -- System info
        ["CandelaLogHost"] = "Tag",
        ["CandelaLogFacility"] = "Winbar",
        ["CandelaLogProcess"] = "Title",

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

        -- Special
        ["CandelaLogSeparator"] = "Comment",
        ["CandelaLogSymbol"] = "Operator",
    }

    M.syntax_commands = {
        -- Dates
        [=[syntax match CandelaLogDate '\<\d\{2}[-/]\d\{2}\>']=],
        [=[syntax match CandelaLogDate '\<\d\{4}[-/]\d\{2}[-/]\d\{2}\>']=],
        [=[syntax match CandelaLogDate '\<\d\{2}[-/]\d\{2}[-/]\d\{4}\>']=],
        [=[syntax match CandelaLogDate '\<\d\{4}-\d\{2}-\d\{2}T']=],
        [=[syntax match CandelaLogDate '\<\a\{3} \d\{1,2}\(,\? \d\{4}\)\?\>']=],
        [=[syntax match CandelaLogDate '\<\d\{1,2}[- ]\a\{3}[- ]\d\{4}\>']=],
        -- Weekdays
        [=[syntax keyword CandelaLogDay Mon Tue Wed Thu Fri Sat Sun]=],

        -- Time
        [=[syntax match CandelaLogTime '\%(^\|\s\)\zs\d\{2}:\d\{2}:\d\{2}\(\.\d\{2,6}\)\?\ze\%(\s\|$\)' contains=CandelaLogTimeZone,CandelaLogTimeAMPM nextgroup=CandelaLogHost skipwhite]=],
        [=[syntax match CandelaLogTimeAMPM '\cAM\|\cPM\>' contained skipwhite nextgroup=CandelaLogHost]=],
        [=[syntax match CandelaLogTimeZone 'Z\|[+-]\d\{2}:\d\{2}\|\a\{3}\>' contained skipwhite nextgroup=CandelaLogHost]=],
        [=[syntax match CandelaLogTimeDuration '\(\(\(\d\+d\)\?\d\+h\)\?\d\+m\)\?\d\+\(\.\d\+\)\?[mun]\?s\>']=],

        -- System info
        [=[syntax match CandelaLogHost '\<[[:alnum:]\._-]\+\>' contained skipwhite nextgroup=CandelaLogFacility,CandelaLogProcess]=],
        [=[syntax match CandelaLogFacility '\<[[:alnum:]]\+\.[[:alnum:]]\+\>' contained skipwhite contains=CandelaLogLevels nextgroup=CandelaLogProcess]=],
        [=[syntax match CandelaLogProcess '\<[[:alnum:]\._-]\+\%(([^)]\+)\)\?\%(\[[[:digit:]]\+\]\)\?:' contained skipwhite contains=CandelaLogTypeInt nextgroup=CandelaLogMessage]=],

        -- Symbols/separators
        [=[syntax match CandelaLogSymbol '[!@#$%^&*;:?]']=],
        [=[syntax match CandelaLogSeparator '-\{3,}\|=\{3,}\|#\{3,}\|\*\{3,}\|<\{3,}\|>\{3,}']=],

        -- Log Levels
        [=[syntax keyword CandelaLogLevelFatal containedin=CandelaLogFacility FATAL Fatal fatal]=],
        [=[syntax keyword CandelaLogLevelError containedin=CandelaLogFacility E ERR[ORS] Err[ors] err[ors]]=],
        [=[syntax keyword CandelaLogLevelWarning containedin=CandelaLogFacility W WARN[ING] Warn[ing] warn[ing]]=],
        [=[syntax keyword CandelaLogLevelInfo containedin=CandelaLogFacility I INFO Info info]=],
        [=[syntax keyword CandelaLogLevelDebug containedin=CandelaLogFacility D DEBUG Debug debug DBG Dbg dbg]=],
        [=[syntax keyword CandelaLogLevelTrace containedin=CandelaLogFacility TRACE Trace trace]=],
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

    local filetypes = {}
    for _, ext in ipairs(opts.file_types) do
        table.insert(filetypes, "*." .. ext)
    end
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = filetypes,
        callback = function()
            vim.api.nvim_exec2("setlocal nospell", {})
            for name, link in pairs(M.syntax_groups) do
                vim.cmd(string.format("highlight default link %s %s", name, link))
            end
            M.apply()
        end,
    })
end

function M.apply()
    for _, cmd in ipairs(M.syntax_commands) do
        vim.api.nvim_exec2(cmd, {})
    end
end

return M
