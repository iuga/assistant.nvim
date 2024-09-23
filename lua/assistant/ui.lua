local Popup = require("nui.popup")
local Layout = require("nui.layout")
local Input = require("nui.input")
local Text = require("nui.text")
local event = require("nui.utils.autocmd").event

---@class UI
local M = {}

-- Opens a floating window with a new buffer, returning the buffer and window IDs.
function M.open_chat(bufnr_chat, bufnr_input, on_submit)

    local prompt = "> "

    local popup_chat = Popup({
        border = {
            style = "rounded",
            text = {
                top = "",
                top_align = "left",
            },
        },
        focusable = true,
        buf_options = {
            modifiable = true,
            readonly = false,
        },
        bufnr = bufnr_chat,
    })

    local popup_input = Popup({
        relative = "cursor",
        position = {
            row = 1,
            col = 0,
        },
        size = 20,
        enter = true, -- If true, the popup is entered immediately after mount.
        focusable = true,
        border = {
            style = "rounded",
            text = {
                top = "",
                top_align = "left",
            },
        },
        bufnr = bufnr_input,
        win_options = {
            winhighlight = "Normal:Normal",
        },
    })

    local layout = Layout({
        position = "50%",
        size = {
            width = "90%",
            height = "80%",
        },
    },
        Layout.Box({
            Layout.Box(popup_chat, { size = "80%" }),
            Layout.Box(popup_input, { size = "20%" }),
        }, { dir = "col" })
    )
    layout:mount()

    before_on_submit = function()
        local msg = vim.api.nvim_buf_get_lines(bufnr_input, 0, -1, false)
        if M.is_message_empty(msg) then
            return
        end
        on_submit(msg)
        vim.api.nvim_buf_set_lines(bufnr_input, 0, -1, false, {}) -- clear  the input
    end

    popup_input:map("i", "<S-Enter>", before_on_submit, { noremap = true })

	return layout 
end

function M.table_concat(t1, t2)
   for i=1,#t2 do
      t1[#t1+1] = t2[i]
   end
   return t1
end

function M.is_message_empty(msg)
    -- First, check if the table (msg) is empty
    if #msg== 0 then
        return true
    end
    -- Then, check if all msg are empty (no characters)
    for _, line in ipairs(msg) do
        if line ~= "" then
            return false  -- If any line has characters, buffer is not empty
        end
    end

    return true  -- All msg are empty
end

return M

