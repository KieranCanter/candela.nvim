local Finder = {}

function Finder.vim_match(regex)
    vim.fn.setreg("/", "\\v" .. regex)
    vim.cmd("normal! n")
end

return Finder
