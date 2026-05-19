-- Presence Keeper
-- F15-pulse toggle to prevent Teams/Slack from going idle-yellow.
-- Auto-enables when a video plays (VTDecoderXPCService detected via pmset).
-- Manual override via Raycast (presence-toggle.sh) -> hs -c "require('modules.presence-keeper').toggle()"

local M = {}

M.INTERVAL_SECONDS = 240
M.AUTO_CHECK_INTERVAL = 30

M.state = {
    active = false,
    timer = nil,
    watcher = nil,
    autoTimer = nil,
    activatedBy = nil,
    manualOverride = false,
    wasPlaying = false,
}

local function fire()
    hs.eventtap.event.newKeyEvent("f15", true):post()
    hs.eventtap.event.newKeyEvent("f15", false):post()
end

local function videoIsPlaying()
    local output = hs.execute("/usr/bin/pmset -g assertions")
    if not output then return false end
    return output:find("Video Wake Lock") ~= nil
        or output:find("VTDecoderXPCService") ~= nil
end

function M.on(activatedBy)
    activatedBy = activatedBy or "manual"
    if M.state.active then return end
    M.state.active = true
    M.state.activatedBy = activatedBy
    fire()
    M.state.timer = hs.timer.doEvery(M.INTERVAL_SECONDS, fire)
    local suffix = activatedBy == "auto" and " (auto)" or ""
    hs.alert.show("Presence: ON" .. suffix, 2)
    print("Presence: ON")
end

function M.off()
    if not M.state.active then return end
    M.state.active = false
    M.state.activatedBy = nil
    if M.state.timer then
        M.state.timer:stop()
        M.state.timer = nil
    end
    hs.alert.show("Presence: OFF", 2)
    print("Presence: OFF")
end

function M.toggle()
    if M.state.active then
        M.state.manualOverride = true
        M.off()
    else
        M.state.manualOverride = false
        M.on("manual")
    end
end

local function autoCheck()
    local isPlaying = videoIsPlaying()

    if isPlaying and not M.state.wasPlaying then
        if not M.state.active and not M.state.manualOverride then
            M.on("auto")
        end
    elseif not isPlaying and M.state.wasPlaying then
        M.state.manualOverride = false
        if M.state.active and M.state.activatedBy == "auto" then
            M.off()
        end
    end

    M.state.wasPlaying = isPlaying
end

function M.init()
    if M.state.watcher then M.state.watcher:stop() end
    if M.state.autoTimer then M.state.autoTimer:stop() end

    -- Force-load lazy HS extensions so the first toggle from Raycast
    -- doesn't print "Loading extension: ..." into the HUD.
    local _eventtap = hs.eventtap.event.types
    local _timer = hs.timer.secondsSinceEpoch
    local _alert = hs.alert.show

    M.state.watcher = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.screensDidLock
            or event == hs.caffeinate.watcher.systemWillSleep then
            if M.state.active then
                M.off()
            end
        end
    end)
    M.state.watcher:start()

    M.state.autoTimer = hs.timer.doEvery(M.AUTO_CHECK_INTERVAL, autoCheck)
end

return M
