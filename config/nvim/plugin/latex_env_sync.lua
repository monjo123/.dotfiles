-- ~/.config/nvim/plugin/latex_env_sync.lua

local syncing = false

----------------------------------------------------------------------
-- Get the environment name from a begin/end node
----------------------------------------------------------------------

local function get_environment_name(node)
    if not node then
        return nil
    end

    local name_node = nil

    local function find_name(n)
        if n:type() == "curly_group_text" then
            name_node = n
            return
        end

        for child in n:iter_children() do
            if name_node then
                return
            end

            find_name(child)
        end
    end

    find_name(node)

    if not name_node then
        return nil
    end

    local text = vim.treesitter.get_node_text(name_node, 0)

    if not text then
        return nil
    end

    text = text:gsub("^%s*{%s*", "")
    text = text:gsub("%s*}%s*$", "")

    return text
end

----------------------------------------------------------------------
-- Collect all begin/end nodes
----------------------------------------------------------------------

local function collect_environment_nodes(root)
    local nodes = {}

    local function walk(node)
        local node_type = node:type()

        if node_type == "begin" or node_type == "end" then
            local row, col = node:start()

            table.insert(nodes, {
                node = node,
                type = node_type,
                name = get_environment_name(node),
                row = row,
                col = col,
            })
        end

        for child in node:iter_children() do
            walk(child)
        end
    end

    walk(root)

    table.sort(nodes, function(a, b)
        if a.row == b.row then
            return a.col < b.col
        end

        return a.row < b.row
    end)

    return nodes
end

----------------------------------------------------------------------
-- Check whether ALL begin/end are correctly matched
--
-- Return:
--   true  = everything is complete and correctly nested
--   false = missing begin/end or mismatched environment
----------------------------------------------------------------------

local function all_environments_complete(nodes)
    local stack = {}

    for _, item in ipairs(nodes) do
        -- Cannot reliably match an environment whose name is incomplete.
        if not item.name or item.name == "" then
            return false
        end

        if item.type == "begin" then
            table.insert(stack, item)

        elseif item.type == "end" then
            local last = stack[#stack]

            -- No corresponding begin
            if not last then
                return false
            end

            -- Wrong nesting / mismatched environment
            if last.name ~= item.name then
                return false
            end

            table.remove(stack)
        end
    end

    -- There are still unmatched begin environments
    if #stack > 0 then
        return false
    end

    return true
end

----------------------------------------------------------------------
-- Find matching begin/end
----------------------------------------------------------------------

local function find_matching_environment(nodes, index)
    local current = nodes[index]

    if not current then
        return nil
    end

    local depth = 0

    if current.type == "begin" then
        for i = index, #nodes do
            local item = nodes[i]

            if item.type == "begin" then
                depth = depth + 1

            elseif item.type == "end" then
                depth = depth - 1

                if depth == 0 then
                    return item
                end
            end
        end

    else
        for i = index, 1, -1 do
            local item = nodes[i]

            if item.type == "end" then
                depth = depth + 1

            elseif item.type == "begin" then
                depth = depth - 1

                if depth == 0 then
                    return item
                end
            end
        end
    end

    return nil
end

----------------------------------------------------------------------
-- Find the name node inside begin/end
----------------------------------------------------------------------

local function find_name_node(node)
    if not node then
        return nil
    end

    if node:type() == "curly_group_text" then
        return node
    end

    for child in node:iter_children() do
        local result = find_name_node(child)

        if result then
            return result
        end
    end

    return nil
end

----------------------------------------------------------------------
-- Replace environment name
----------------------------------------------------------------------

local function replace_environment_name(node, new_name)
    local name_node = find_name_node(node)

    if not name_node then
        return false
    end

    local start_row, start_col, end_row, end_col =
        name_node:range()

    if start_row ~= end_row then
        return false
    end

    local line =
        vim.api.nvim_buf_get_lines(
            0,
            start_row,
            start_row + 1,
            false
        )[1]

    if not line then
        return false
    end

    local before = line:sub(1, start_col)
    local after = line:sub(end_col + 1)

    local new_text = "{" .. new_name .. "}"

    local new_line = before .. new_text .. after

    if new_line == line then
        return false
    end

    vim.api.nvim_buf_set_lines(
        0,
        start_row,
        start_row + 1,
        false,
        { new_line }
    )

    return true
end

----------------------------------------------------------------------
-- Find begin/end node under cursor
----------------------------------------------------------------------

local function find_current_node(nodes)
    local cursor = vim.api.nvim_win_get_cursor(0)

    local cursor_row = cursor[1] - 1
    local cursor_col = cursor[2]

    for index, item in ipairs(nodes) do
        local start_row, start_col,
              end_row, end_col = item.node:range()

        if cursor_row >= start_row
            and cursor_row <= end_row then

            if cursor_row > start_row
                or cursor_col >= start_col then

                if cursor_row < end_row
                    or cursor_col < end_col then

                    return index
                end
            end
        end
    end

    return nil
end

----------------------------------------------------------------------
-- Synchronize
----------------------------------------------------------------------

local function sync_environment()
    if syncing then
        return
    end

    if vim.bo.filetype ~= "tex" then
        return
    end

    local parser = vim.treesitter.get_parser(0, "latex")

    if not parser then
        return
    end

    parser:parse()

    local tree = parser:trees()[1]

    if not tree then
        return
    end

    local root = tree:root()

    local nodes = collect_environment_nodes(root)

    ------------------------------------------------------------------
    -- IMPORTANT:
    -- Do not sync if ANY begin/end in the entire file is incomplete
    -- or incorrectly nested.
    ------------------------------------------------------------------

    if not all_environments_complete(nodes) then
        return
    end

    ------------------------------------------------------------------
    -- Everything is complete, so now find the environment under
    -- the cursor.
    ------------------------------------------------------------------

    local current_index = find_current_node(nodes)

    if not current_index then
        return
    end

    local current = nodes[current_index]

    if not current.name or current.name == "" then
        return
    end

    local matching =
        find_matching_environment(
            nodes,
            current_index
        )

    if not matching then
        return
    end

    syncing = true

    replace_environment_name(
        matching.node,
        current.name
    )

    syncing = false
end

----------------------------------------------------------------------
-- Autocommands
----------------------------------------------------------------------

local group = vim.api.nvim_create_augroup(
    "LatexEnvironmentSync",
    { clear = true }
)

vim.api.nvim_create_autocmd(
    "InsertLeave",
    {
        group = group,
        pattern = "*.tex",

        callback = function()
            vim.schedule(function()
                sync_environment()
            end)
        end,
    }
)
