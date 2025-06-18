-- Define a hotkey to reload Hammerspoon configuration
hs.hotkey.bind({ "cmd", "alt" }, "R", function()
	hs.reload()
end)
hs.alert.show("Config loaded")

-- local modal = hs.hotkey.modal.new({}, "F17") -- An unused key to represent the layer
--
-- hs.hotkey.bind({ "ctrl", "alt" }, "space", function()
-- 	modal:enter()
-- 	hs.alert.show("Layer activated")
-- end)
--
-- modal:bind({}, "t", function()
-- 	hs.application.launchOrFocusByBundleID("com.mitchellh.ghostty")
-- 	modal:exit()
-- end)
--
-- modal:bind({}, "b", function()
-- 	hs.application.launchOrFocusByBundleID("company.thebrowser.Browser")
-- 	modal:exit()
-- end)
--
-- modal:bind({}, "m", function()
-- 	hs.application.launchOrFocusByBundleID("com.microsoft.teams2")
-- 	modal:exit()
-- end)
--
-- modal:bind({}, "g", function()
-- 	hs.application.launchOrFocusByBundleID("com.openai.chat")
-- 	modal:exit()
-- end)
