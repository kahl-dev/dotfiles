#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title iPad → Extended Display
# @raycast.mode silent
# @raycast.packageName Kahl-dev scripts
#
# Optional parameters:
# @raycast.icon 🖥️
#
# Documentation:
# @raycast.description Connect iPad as extended display (Sidecar mode)
# @raycast.author kahl.dev
# @raycast.authorURL https://raycast.com/kahl.dev

on run
    -- Set device name, allowing an override via environment variable
    set device to (system attribute "IPAD_NAME")
    if device is missing value or device is "" then
        set device to "iPad"
    end if

    -- Show reminder notification
    display notification "Please ensure your iPad is awake and nearby" with title "Sidecar Setup"
    delay 1

    try
        -- Open Displays settings
        do shell script "open -b com.apple.systempreferences /System/Library/PreferencePanes/Displays.prefPane"

        tell application "System Events"
            -- Wait for Displays window to appear
            repeat until (exists window "Displays" of application process "System Settings")
                delay 0.1
            end repeat

            tell process "System Settings"
                -- Find the AirPlay Display popup button
                set popUpButton to pop up button 1 of group 1 of group 2 of splitter group 1 of group 1 of window "Displays"

                -- Wait for popup button to be available
                repeat until exists popUpButton
                    delay 0.1
                end repeat

                -- Click to open the dropdown
                click popUpButton

                -- Wait for menu to appear
                repeat until exists menu 1 of popUpButton
                    delay 0.1
                end repeat

                tell menu 1 of popUpButton
                    -- Simple approach: Find ALL occurrences of device, use the SECOND one for Sidecar
                    set deviceMenuItems to {}
                    repeat with menuItem in menu items
                        set itemName to name of menuItem as string
                        if itemName contains device then
                            set deviceMenuItems to deviceMenuItems & {menuItem}
                        end if
                    end repeat

                    -- Use the second occurrence for Sidecar (first is Universal Control)
                    set deviceMenuItem to missing value
                    if (count of deviceMenuItems) >= 2 then
                        -- Use second occurrence (Sidecar)
                        set deviceMenuItem to item 2 of deviceMenuItems
                    else if (count of deviceMenuItems) = 1 then
                        -- Only one occurrence, use it (might be when Universal Control isn't available)
                        set deviceMenuItem to item 1 of deviceMenuItems
                    else
                        error "Device '" & device & "' not found in AirPlay Display menu"
                    end if

                    -- Check current connection state
                    set itemName to name of deviceMenuItem as string
                    set currentSelection to value of popUpButton as string

                    -- If device is already connected in extended mode, we're done
                    if itemName contains "Extended" or itemName contains "Extend" or itemName contains "erweitern" then
                        key code 53 -- ESC key
                        tell application "System Settings" to quit
                        return "✅ iPad already connected as extended display"
                    end if

                    -- If device appears to be connected (selected in dropdown) but not in extend mode
                    -- This happens when iPad is awake and connected via Universal Control
                    if currentSelection contains device or itemName contains "verknüpfen" or itemName contains "Link" then
                        -- Need to disconnect first, then reconnect with Sidecar

                        -- First, disconnect by selecting "Off" or similar
                        set disconnected to false
                        repeat with menuItem in menu items
                            set itemText to name of menuItem as string
                            if itemText contains "Off" or itemText contains "Aus" or itemText contains "None" then
                                click menuItem
                                set disconnected to true
                                exit repeat
                            end if
                        end repeat

                        if disconnected then
                            -- Wait for disconnection to complete
                            delay 1.5

                            -- Close and reopen menu to refresh state
                            key code 53 -- ESC
                            delay 0.5
                            click popUpButton

                            -- Wait for refreshed menu
                            repeat until exists menu 1 of popUpButton
                                delay 0.1
                            end repeat

                            -- Now find the device again in refreshed menu
                            tell menu 1 of popUpButton
                                set deviceMenuItem to missing value
                                repeat with menuItem in menu items
                                    if name of menuItem contains device then
                                        set deviceMenuItem to menuItem
                                        exit repeat
                                    end if
                                end repeat
                            end tell
                        end if
                    end if

                    -- Now click on the device to connect
                    if deviceMenuItem is not missing value then
                        click deviceMenuItem

                        -- Wait for submenu to appear
                        delay 0.8

                        -- Look for Sidecar Extended option in multiple languages
                        if exists menu 1 of deviceMenuItem then
                            tell menu 1 of deviceMenuItem
                                set extendedClicked to false

                                -- First try: Look for text patterns (English and German)
                                repeat with subItem in menu items
                                    set subItemName to name of subItem as string
                                    if subItemName contains "Extend" or subItemName contains "Extended" or subItemName contains "erweitern" then
                                        click subItem
                                        set extendedClicked to true
                                        exit repeat
                                    end if
                                end repeat

                                -- Fallback: If no text match found, look for second menu item (usually Extended)
                                -- In German: Item 1 = Mirror (Spiegeln), Item 2 = Extend (erweitern)
                                if not extendedClicked and (count of menu items) > 1 then
                                    click menu item 2
                                end if
                            end tell
                        else
                            -- No submenu appeared - might have connected directly
                            -- This can happen with different iPad states
                            delay 1
                        end if
                    end if
                end tell

                -- Wait for menu to close
                repeat while exists menu 1 of popUpButton
                    delay 0.1
                end repeat
            end tell
        end tell

        -- Close System Settings
        tell application "System Settings" to quit

        -- Success message
        set successMsg to "✅ iPad '" & device & "' connected as extended display"
        log successMsg
        display notification "Connected as extended display" with title "iPad Sidecar" subtitle device

        return successMsg

    on error errMsg
        try
            tell application "System Settings" to quit
        end try

        set errorMsg to "❌ Failed to connect iPad as extended display: " & errMsg
        log errorMsg
        display notification "Connection failed" with title "iPad Sidecar" subtitle errMsg

        return errorMsg
    end try
end run