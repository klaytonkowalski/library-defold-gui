----------------------------------------------------------------------
-- LICENSE
----------------------------------------------------------------------

-- MIT License

-- Copyright (c) 2022 Klayton Kowalski

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- https://github.com/klaytonkowalski/defold-gui

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

local dgui = {}

local widgets = {}

local action_ids =
{
	mouse_button_left = hash("mouse_button_left"),
	mouse_wheel_up = hash("mouse_wheel_up"),
	mouse_wheel_down = hash("mouse_wheel_down"),
	text = hash("text"),
	key_backspace = hash("key_backspace")
}

local style_callbacks =
{
	idle = function(node) gui.set_color(node, vmath.vector4(1, 1, 1, 1)) end,
	over = function(node) gui.set_color(node, vmath.vector4(1, 1, 0, 1)) end,
	active = function(node) gui.set_color(node, vmath.vector4(0, 1, 0, 1)) end,
	disabled = function(node) gui.set_color(node, vmath.vector4(0.5, 0.5, 0.5, 1)) end
}

----------------------------------------------------------------------
-- CONSTANTS
----------------------------------------------------------------------

local widget_ids =
{
	button = 1,
	toggle = 2,
	text = 3
}

----------------------------------------------------------------------
-- OTHER FUNCTIONS
----------------------------------------------------------------------

local function toggle_family(family)
	for _, widget in pairs(widgets) do
		if widget.family == family then
			widget.selected = false
			style_callbacks.idle(widget.node)
		end
	end
end

local function text_unfocus(widget)
	widget.selected = false
	style_callbacks.idle(widget.node)
end

local function text_append(widget, text)
	local node_text = gui.get_text(widget.node)
	local truncated_text = string.sub(text, 0, widget.max_length and (widget.max_length - #node_text) or #node_text)
	gui.set_text(widget.node, node_text .. truncated_text)
	if #truncated_text > 0 then
		widget.callback(widget)
	end
end

local function text_erase(widget, node)
	local node_text = gui.get_text(widget.node)
	if #node_text > 0 then
		gui.set_text(widget.node, string.sub(node_text, 0, #node_text - 1))
		widget.callback(widget)
	end
end

----------------------------------------------------------------------
-- MAPPED FUNCTIONS
----------------------------------------------------------------------

local function button_over(widget)
	widget.over = true
	style_callbacks.over(widget.node)
end

local function button_idle(widget)
	widget.over = false
	widget.down = false
	style_callbacks.idle(widget.node)
end

local function button_down(widget)
	widget.down = true
	style_callbacks.active(widget.node)
	widget.callback(widget)
end

local function button_up(widget)
	widget.down = false
	style_callbacks.over(widget.node)
end

local function toggle_over(widget)
	widget.over = true
	if not widget.selected then
		style_callbacks.over(widget.node)
	end
end

local function toggle_idle(widget)
	widget.over = false
	widget.down = false
	if not widget.selected then
		style_callbacks.idle(widget.node)
	end
end

local function toggle_down(widget)
	widget.down = true
	if widget.selected then
		widget.selected = false
		style_callbacks.over(widget.node)
	else
		toggle_family(widget.family)
		widget.selected = true
		style_callbacks.active(widget.node)
	end
	widget.callback(widget)
end

local function toggle_up(widget)
	widget.down = false
end

local function text_over(widget)
	widget.over = true
	if not widget.selected then
		style_callbacks.over(widget.node)
	end
end

local function text_idle(widget)
	widget.over = false
	widget.down = false
	if not widget.selected then
		style_callbacks.idle(widget.node)
	end
end

local function text_down(widget)
	widget.down = true
	if not widget.selected then
		widget.selected = true
		style_callbacks.active(widget.node)
	end
end

local function text_up(widget)
	widget.down = false
end

local widget_maps =
{
	button = { id = 1, over = button_over, idle = button_idle, down = button_down, up = button_up },
	toggle = { id = 2, over = toggle_over, idle = toggle_idle, down = toggle_down, up = toggle_up },
	text = { id = 3, over = text_over, idle = text_idle, down = text_down, up = text_up }
}

----------------------------------------------------------------------
-- INPUT FUNCTIONS
----------------------------------------------------------------------

local function on_input_mouse_move(action)
	for _, widget in pairs(widgets) do
		if widget.enabled then
			if gui.pick_node(widget.node, action.x, action.y) then
				if not widget.over then
					widget.map.over(widget)
				end
			elseif widget.over then
				widget.map.idle(widget)
			end
		end
	end
end

local function on_input_mouse_button_left(action)
	for _, widget in pairs(widgets) do
		if widget.enabled then
			if widget.over then
				if action.pressed then
					widget.map.down(widget)
				else
					widget.map.up(widget)
				end
			elseif widget.map.id == widget_ids.text then
				if action.pressed then
					if widget.selected then
						text_unfocus(widget)
					end
				end
			end
		end
	end
end

local function on_input_mouse_wheel_up(action)
	
end

local function on_input_mouse_wheel_down(action)
	
end

local function on_input_text(action)
	for _, widget in pairs(widgets) do
		if widget.enabled then
			if widget.map.id == widget_ids.text then
				if widget.selected then
					text_append(widget, action.text)
				end
			end
		end
	end
end

local function on_input_key_backspace(action)
	for _, widget in pairs(widgets) do
		if widget.enabled then
			if widget.map.id == widget_ids.text then
				if widget.selected then
					text_erase(widget)
				end
			end
		end
	end
end

----------------------------------------------------------------------
-- ENGINE FUNCTIONS
----------------------------------------------------------------------

function dgui.add_button(id, callback, group, enabled)
	if widgets[id] then
		return
	end
	widgets[id] =
	{
		id = id,
		node = gui.get_node(id),
		map = widget_maps.button,
		callback = callback,
		group = group,
		enabled = enabled,
		over = false,
		down = false
	}
end

function dgui.add_toggle(id, callback, group, enabled, family)
	if widgets[id] then
		return
	end
	widgets[id] =
	{
		id = id,
		node = gui.get_node(id),
		map = widget_maps.toggle,
		callback = callback,
		group = group,
		enabled = enabled,
		family = family,
		selected = false,
		over = false,
		down = false
	}
end

function dgui.add_text(id, callback, group, enabled, max_length)
	if widgets[id] then
		return
	end
	widgets[id] =
	{
		id = id,
		node = gui.get_node(id),
		map = widget_maps.text,
		callback = callback,
		group = group,
		enabled = enabled,
		max_length = max_length,
		selected = false,
		over = false,
		down = false
	}
end

function dgui.remove_widget(id)
	if widgets[id] then
		widget.map.idle(widgets[id])
		widgets[id] = nil
	end
end

function dgui.clear_widgets()
	for _, widget in pairs(widgets) do
		widget.map.idle(widget)
	end
	widgets = {}
end

function dgui.set_action_ids(mouse_button_left, mouse_wheel_up, mouse_wheel_down, text, key_backspace)
	if mouse_button_left then
		action_ids.mouse_button_left = mouse_button_left
	end
	if mouse_wheel_up then
		action_ids.mouse_wheel_up = mouse_wheel_up
	end
	if mouse_wheel_down then
		action_ids.mouse_wheel_down = mouse_wheel_down
	end
	if text then
		action_ids.text = text
	end
	if key_backspace then
		action_ids.key_backspace = key_backspace
	end
end

function dgui.set_style_callbacks(idle, over, active, disabled)
	if idle then
		style_callbacks.idle = idle
	end
	if over then
		style_callbacks.over = over
	end
	if active then
		style_callbacks.active = active
	end
	if disabled then
		style_callbacks.disabled = disabled
	end
end

function dgui.set_selected(id, flag, callback)
	local widget = widgets[id]
	if not widget or widget.map.id ~= widget_ids.toggle or widget.selected == flag then
		return
	end
	if flag then
		widget.selected = true
		style_callbacks.active(widget.node)
	else
		widget.selected = false
		style_callbacks.idle(widget.node)
	end
	if callback then
		widget.callback(widget)
	end
end

function dgui.on_input(action_id, action)
	if not action_id then
		on_input_mouse_move(action)
	elseif action_id == action_ids.mouse_button_left then
		if action.pressed or action.released then
			on_input_mouse_button_left(action)
		end
	elseif action_id == action_ids.mouse_wheel_up then
		if action.pressed then
			on_input_mouse_wheel_up(action)
		end
	elseif action_id == action_ids.mouse_wheel_down then
		if action.pressed then
			on_input_mouse_wheel_down(action)
		end
	elseif action_id == action_ids.text then
		on_input_text(action)
	elseif action_id == action_ids.key_backspace then
		if action.pressed or action.repeated then
			on_input_key_backspace(action)
		end
	end
end

return dgui