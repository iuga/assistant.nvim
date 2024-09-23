---@class Client
local M = {}

-- Query the ollama server for available models
function M.query_models(cfg)
	local res = require("plenary.curl").get(cfg.url .. "/api/tags")

	local _, body = pcall(function()
		return vim.json.decode(res.body)
	end)

	if body == nil then
		return {}
	end

	local models = {}
	for _, model in pairs(body.models) do
		table.insert(models, model.name)
	end

	return models
end

function M.generate(cfg, input, on_response)
    print("generate", cfg, input, on_response)
    local tokens = {}
    local cb = function(body, job)
        print("callback", body, job)
        if job == nil and _job ~= nil then
            job:shutdown()
        end
        table.insert(tokens, body.response)
        local lines = vim.split(table.concat(tokens), "\n")
        on_response(lines, body.done)
    end
    local job = require("plenary.curl").post(cfg.url .. "/api/generate", {
        body = vim.json.encode({
            model = cfg.model,
            prompt = input,
            stream = true,
        }),
        stream = function(err, chunk, job)
            print("handle stream", err, chunk, job)
            M.handle_stream(cb)(err, chunk, job)
        end,
    }) 
    print("plenary job", job)

    if not response then
        print("Error: No response received. Possible network error.")
        return
    end

end

---@param cb fun(body: table, job: Job?)
function M.handle_stream(cb)
	---@param job Job?
	return function(_, chunk, job)
        print("handle_stream", _, chunk, job)
		vim.schedule(function()
			local _, body = pcall(function()
				return vim.json.decode(chunk)
			end)
			if type(body) ~= "table" or body.response == nil then
				if body.error ~= nil then
					vim.api.nvim_notify("Error: " .. body.error, vim.log.levels.ERROR, { title = "Ollama" })
				end
				return
			end
			cb(body, job)
		end)
	end
end

return M
