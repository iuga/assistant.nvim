-- main module file
local client = require("assistant.client")
local ui = require("assistant.ui")

---@class MyModule
local M = {}

---@class Config
---@field opt string Your config option
function M.default_config()
    return {
        model = "llama3.1",
        url = "http://127.0.0.1:11434"
    }
end

---@type Config
M.config = M.default_config()

---@type Table
---@example [{role = "assistant", message = "..."},...]
M.history = {}

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
    M.config = vim.tbl_deep_extend("force", M.config, args or {})
    -- add commands
    vim.api.nvim_create_user_command("AssistantChooseModel", M.choose_model, {
        desc = "List and select from available ollama models",
    })
    vim.api.nvim_create_user_command("AssistantChat", M.chat, {
        desc = "Chat with the assistant",
    })
end

-- Method for choosing models
function M.choose_model()
	local models = client.query_models(M.config)

	if #models < 1 then
		vim.api.nvim_notify(
			"No models found. Is the ollama server running?",
			vim.log.levels.ERROR,
			{ title = "Ollama" }
		)
		return

	end

	vim.ui.select(models, {
		prompt = "Select a model:",
		format_item = function(item)
			if item == M.config.model then
				return item .. " (current)"
			end
			return item
		end,
	}, function(selected)
		if not selected then
			return
		end
		M.config.model = selected
		vim.api.nvim_notify(("Selected model '%s'"):format(selected), vim.log.levels.INFO, { title = "Ollama" })
	end)
end

function M.chat()
    local bufrnout = vim.api.nvim_create_buf(false, true)
    M.set_bufnr_options(bufrnout)
    local bufrnin = vim.api.nvim_create_buf(false, true)
    M.set_bufnr_options(bufrnout)

    local on_response = function(body, done)
        print("on response~>", body, done)
        local ctx = {}
        -- Insert all lines from the current buffer content (ctx)
        for _, msg in ipairs(M.history) do
            for i, l in ipairs(msg.message) do
                if msg.role == "user" then
                    table.insert(ctx, "> " .. l)
                else
                    table.insert(ctx, l)
                end
            end
            table.insert(ctx, "")
        end
        -- Insert all lines from the response body
        for i, line in ipairs(body.message) do
            if body.role == "user" then
                table.insert(ctx, "> " .. line)
            else
                table.insert(ctx, line)
            end
        end

        if done == true then
            M.add_to_history(body)
        else
            vim.api.nvim_buf_set_lines(bufrnout, 0, -1, false, ctx)
        end
    end

    local on_submit = function(value)
        print("on_submit", value)
        local message = {role = "user", message = value}
        M.add_to_history(message)
        M.flush_history(bufrnout)
        local prompt = table.concat(value, "\n")
        client.chat(M.config, M.history, on_response)
    end

    ui.open_chat(bufrnout, bufrnin, on_submit) 

    if not M.is_history_empty() then
        M.flush_history(bufrnout)
    end
    
end

-- message ~> {role = "assistant", message = "..."} 
function M.add_to_history(message)
    print("add to history", message, message.role, table.concat(message.message, " "))
    if message ~= nil then
        table.insert(M.history, message)
    end
end

function M.flush_history(bufnr)
    local ctx = {}
    for _, msg in ipairs(M.history) do
        -- print("history entry~>", msg, msg.role, table.concat(msg.message, ""))
        for _, l in ipairs(msg.message) do
            if msg.role == "user" then
                table.insert(ctx, "> " .. l)
            else
                table.insert(ctx, l)
            end
        end
        table.insert(ctx, "")
        -- local lines = {}
        -- if msg.role == "user" then
        --     table.insert(ctx, "[user] ~> " .. msg.message)
        -- else
        --     table.insert(ctx, "[assistant] ~> " .. msg.message)
        -- end
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, ctx)
end

function M.set_bufnr_options(bufnr)
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
end

function M.is_history_empty()
    -- Iterate over the table
    for _ in pairs(M.history) do
        return false  -- If any key exists, the table is not empty
    end
    return true  -- If no keys exist, the table is empty
end

return M
