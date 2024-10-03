local Popup = require("nui.popup")
local Layout = require("nui.layout")
local Input = require("nui.input")
local Text = require("nui.text")
local event = require("nui.utils.autocmd").event

local chars = {
  first = '┍',
  mid = '│',
  last = '┕',
  single = '╺',
}

local colors = {
    user = "#E4609B",
    assistant = "#47BAC0"
}
local colors_cache = {} --- @type table<integer,string>

local ns = vim.api.nvim_create_namespace('assistant_blocks')

local model = ""

---@class UI
local M = {}

function M.set_model(cmodel)
    model = cmodel
end

-- Opens a floating window with a new buffer, returning the buffer and window IDs.
function M.open_chat(bufnr_chat, bufnr_input, on_submit)
    local popup_chat = Popup({
        border = {
            style = "rounded",
            -- text = {
            --     top = "",
            --     top_align = "left",
            -- },
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
                bottom = " Send:S+Enter ",
                bottom_align = "right",
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

function M.format_conversation(history)
    local ctx = {}
    for _, msg in ipairs(history) do
        local fmsg = M.format_message(msg)
        for x, l in ipairs(fmsg) do
            table.insert(ctx,  l)
        end
    end
    return ctx
end

function M.format_message(msg)
    local fmsg = {}
    for x, l in ipairs(msg.message) do
        if msg.role == "user" then
            if x == 1 then
                table.insert(fmsg, "┍ User")
            end
            table.insert(fmsg,  "│ " .. l)
        else
            if x == 1 then
                table.insert(fmsg, "┍ Assistant: " .. model)
            end
            table.insert(fmsg, "│ " .. l)
        end
    end
    table.insert(fmsg, "┕")
    -- table.insert(fmsg, "")
    return fmsg
end

function M.highlight(bufnr)

    local ctx = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local crole = ""
    local lbegin = false
    for l, msg in ipairs(ctx) do
        lbegin = false
        if string.starts(msg, "┍ User") then
            crole = "user"
            lbegin = true
        end
        if string.starts(msg, "┍ Assistant") then
            crole = "assistant"
            lbegin = true
        end

        local endcol = 2
        if lbegin then
            endcol = #msg
        end

        local hash_color = M.get_color(crole)
        vim.api.nvim_buf_set_extmark(bufnr, ns, l - 1, 0, {
            end_col = endcol,
            hl_group = hash_color,
        }) 
    end

end


function M.get_color(role)
  if colors_cache[role] then
    return colors_cache[role]
  end

  local hl_name = string.format('AssistantBlameColor.%s', role)
  vim.api.nvim_set_hl(0, hl_name, { fg = colors[role] })
  colors_cache[role] = hl_name

  return hl_name
end

function string.starts(str, start)
    return string.sub(str, 1, #start) == start
end

return M

