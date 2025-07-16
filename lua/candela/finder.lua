local Finder = {}

function Finder.vim_match(regex)
    vim.fn.setreg("/", "\\v\\C" .. regex)
    vim.cmd("normal! n")
end

return Finder
