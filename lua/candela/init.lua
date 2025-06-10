local M = {
    patterns = {},
}

function M.setup()
    vim.api.nvim_create_user_command("Candela", function(opts)
        local args = vim.split(opts.args, " ")
        local subcommand = args[1]
        local tail = vim.fn.join(vim.list_slice(args, 2), " ")

        if subcommand == "add" then
            require("candela").add(tail)
        elseif subcommand == "clear" then
            require("candela").clear()
        elseif subcommand == "highlight" then
            require("candela").highlight()
        elseif subcommand == "lightroom" then
            require("candela").lightroom()
        else
            vim.notify("Candela: unsupported command: " .. subcommand,
                vim.log.levels.ERROR)
        end
    end, {
        nargs = "+",
        complete = function(_, line)
            local completions = { "add", "clear", "highlight", "lightroom" }
            local split = vim.split(line, " ")
            if #split == 2 then
                return vim.tbl_filter(function(c)
                    return vim.startswith(c, split[2])
                end, completions)
            end
            return {}
        end,
        desc = "Candela command parser (e.g. :Candela add <pattern>)",
    })

    print("Candela loaded")
end

function M.add(regex)
    table.insert(M.patterns, {
        pattern = regex,
        highlight_color = "#131313",
        enable_highlight = true,
        enable_lightroom = true,
    })
    vim.notify("Candela: added pattern: " .. regex)
end

function M.clear()
    M.patterns = {}
    vim.notify("Candela: cleared all patterns")
end

function M.highlight()
  local bufnr = vim.api.nvim_get_current_buf()
  for lnum = 0, vim.api.nvim_buf_line_count(bufnr)-1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum+1, false)[1]
    for _, pat in ipairs(M.patterns) do
      if pat.enable_highlight and line:find(pat.pattern) then
        vim.api.nvim_buf_add_highlight(bufnr, -1, pat.highlight_color, lnum, 0, -1)
      end
    end
  end
end

function M.lightroom()
  local lines = {}
  local bufnr = vim.api.nvim_get_current_buf()
  for lnum = 0, vim.api.nvim_buf_line_count(bufnr)-1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum+1, false)[1]
    for _, pat in ipairs(M.patterns) do
      if pat.enable_lightroom and line:find(pat.pattern) then
        table.insert(lines, line)
        break
      end
    end
  end
  vim.cmd("new")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

return M
