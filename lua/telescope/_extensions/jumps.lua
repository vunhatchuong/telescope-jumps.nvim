local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values

---@class configs
---@field max_results integer|nil
---@field line_distance integer | nil
local default_config = {
    max_results = nil,
    line_distance = nil,
}

local config = vim.deepcopy(default_config)

-- TODO maybe remove empty lines  and '-invalid-'
local function reverse(tab)
	for i = 1, #tab / 2, 1 do
		tab[i], tab[#tab - i + 1] = tab[#tab - i + 1], tab[i]
	end
	return tab
end

local function get_display(line, row)
	-- return vim.trim(line)
	return row .. ': ' .. line:sub(18)
end

---@param opts configs
---@return table
local function filter_jumplist(jumplist, opts)
	local result = {}

    if opts.line_distance then
        for _, jump in ipairs(jumplist) do
            local should_add = true

            for _, filtered_jump in ipairs(result) do
                if math.abs(jump.lnum - filtered_jump.lnum) <= opts.line_distance then
                    should_add = false
                    break
                end
            end

            if should_add then
                table.insert(result, jump)
            end
        end
    end

    if opts.max_results then
        result = vim.list_slice(result, 1, opts.max_results)
    end

    return result
end

---@param opts configs
---@return table
local function get_changes(opts)
	local last_changes = {}
	local changes = vim.api.nvim_command_output 'changes'
	local hash = {}

	for change in changes:gmatch '[^\r\n]+' do
		local match = change:gmatch '%d+'
		local nr = match()
		local row = match()
		local col = match()

		if row and not hash[row] then
			hash[row] = true -- remove duplicates
			table.insert(last_changes, { lnum = row, nr = nr, col = col, display = get_display(change, row) })
		end
	end

    last_changes = filter_jumplist(last_changes, opts)

	return reverse(last_changes)
end

---@param opts configs
local function show_changes(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	opts = opts or {}

	pickers.new(opts, {
			prompt_title = 'Changes',
			finder = finders.new_table {
				results = get_changes(config),
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.display,
						lnum = tonumber(entry.lnum),
						col = tonumber(entry.col),
						filename = filepath,
						bufnr = bufnr,
					}
				end,
			},
			previewer = conf.grep_previewer(opts),
			sorter = conf.generic_sorter(opts),
		}):find()
end

---@param opts configs
---@return table
local function get_jumplist(opts)
	local jumplist = vim.fn.getjumplist()[1]

	local current_buffer = vim.fn.winbufnr(vim.fn.win_getid())
	-- reverse the list
	local sorted_jumplist = {}
	for i = #jumplist, 1, -1 do
		if vim.api.nvim_buf_is_valid(jumplist[i].bufnr) and current_buffer == jumplist[i].bufnr then
			local text = vim.api.nvim_buf_get_lines(jumplist[i].bufnr, jumplist[i].lnum - 1, jumplist[i].lnum, false)[1]
			if text then
				jumplist[i].display = jumplist[i].lnum .. ': ' .. text
				table.insert(sorted_jumplist, jumplist[i])
			end
		end
	end

    sorted_jumplist = filter_jumplist(sorted_jumplist, opts)

	return sorted_jumplist
end

---@param opts configs
local function show_jumps(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	opts = opts or {}

	pickers.new(opts, {
			prompt_title = 'Jumpbuff',
			finder = finders.new_table {
				results = get_jumplist(config),
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.display,
						lnum = tonumber(entry.lnum),
						filename = filepath,
						bufnr = bufnr,
					}
				end,
			},
			previewer = conf.qflist_previewer(opts),
			sorter = conf.generic_sorter(opts),
		}):find()
end

return require('telescope').register_extension {
    ---@param ext_config configs
	setup = function(ext_config)
        config = vim.tbl_deep_extend('force', default_config, ext_config or {} )
	end,
	exports = {
		changes = show_changes,
		jumpbuff = show_jumps,
	},
}
