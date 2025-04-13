-- mod-version:3

-----------------------------------------------------------------------
-- NAME       : wwhelix
-- DESCRIPTION: A minimal Helix-inspired plugin for Pragtical
-- AUTHOR     : Wojciech Woźniak
-- GOALS      : Basic helix-like movement and editing
-----------------------------------------------------------------------

local core = require "core"
local command = require "core.command"
local style = require "core.style"
local config = require "core.config"
local keymap = require "core.keymap"
local DocView = require "core.docview"
local StatusView = require "core.statusview"

config.plugins.minimalhelix = {
  enabled = true,
  mode = "normal",
  cursor_colors = {
    normal = {200, 200, 200},
    insert = {50, 200, 100}
  },
  mode_indicators = {
    normal = "NORMAL",
    insert = "INSERT"
  }
}

local original = {
  keymap_on_key_pressed = keymap.on_key_pressed,
  docview_update = DocView.update,
  statusview_get_items = StatusView.get_items
}

local function is_enabled()
  return config.plugins.minimalhelix.enabled
end

local function get_mode()
  return config.plugins.minimalhelix.mode
end

local function set_mode(mode)
  config.plugins.minimalhelix.mode = mode
  style.caret_color = config.plugins.minimalhelix.cursor_colors[mode]
end

local function enter_normal_mode()
  set_mode("normal")
end

local function enter_insert_mode()
  set_mode("insert")
end

local function move_left()
  command.perform("doc:move-to-previous-char")
end

local function move_right()
  command.perform("doc:move-to-next-char")
end

local function move_up()
  command.perform("doc:move-to-previous-line")
end

local function move_down()
  command.perform("doc:move-to-next-line")
end

local function move_word_forward()
  command.perform("doc:move-to-next-word-end")
end

local function move_word_start()
  command.perform("doc:move-to-previous-word-start")
end

function DocView:update(...)
  original.docview_update(self, ...)
  
  if is_enabled() and self.doc == core.active_view.doc then
    self.blink_timer = 0
  end
end

local mode_key_handlers = {
  normal = function(key)
    if key == "i" then
      enter_insert_mode()
      return true
    elseif key == "h" then
      move_left()
      return true
    elseif key == "j" then
      move_down()
      return true
    elseif key == "k" then
      move_up()
      return true
    elseif key == "l" then
      move_right()
      return true
    elseif key == "w" then
      move_word_forward()
      return true
    elseif key == "b" then
      move_word_start()
      return true
    end
    return false
  end,
  
  insert = function(key)
    if key == "escape" then
      enter_normal_mode()
      return true
    end
    return false
  end
}

function keymap.on_key_pressed(key, ...)
  if is_enabled() and core.active_view:is(DocView) then
    local mode = get_mode()
    local handler = mode_key_handlers[mode]
    
    if handler and handler(key) then
      return true
    end
  end
  
  return original.keymap_on_key_pressed(key, ...)
end

command.add(nil, {
  ["wwhelix:toggle"] = function()
    config.plugins.minimalhelix.enabled = not config.plugins.minimalhelix.enabled
    if config.plugins.minimalhelix.enabled then
      core.log("MinimalHelix plugin enabled")
      enter_normal_mode()
    else
      core.log("MinimalHelix plugin disabled")
      style.caret_color = {255, 255, 255}
    end
  end,
  
  ["wwhelix:normal-mode"] = enter_normal_mode,
  ["wwhelix:insert-mode"] = enter_insert_mode
})

keymap.add {
  ["ctrl+alt+h"] = "wwhelix:toggle",
  ["ctrl+\\"] = "wwhelix:normal-mode"
}

enter_normal_mode()
core.log("wwhelix plugin loaded. Use Ctrl+Alt+H to toggle.")
