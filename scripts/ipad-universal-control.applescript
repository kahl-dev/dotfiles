#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title iPad → Universal Control
# @raycast.mode silent
# @raycast.packageName Kahl-dev scripts
#
# Optional parameters:
# @raycast.icon 🖱️
#
# Documentation:
# @raycast.description Connect iPad for Universal Control (shared keyboard & mouse)
# @raycast.author kahl.dev
# @raycast.authorURL https://raycast.com/kahl.dev

on run
    -- Set device name, allowing an override via environment variable
    set device to (system attribute "IPAD_NAME")
    if device is missing value or device is "" then
        set device to "iPad"
    end if

    try
        -- Check if iPad is awake/available first
        display notification "Please ensure your iPad is awake and nearby" with title "Universal Control Setup"
        delay 2

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
                    -- Wait a bit longer for iPad to appear in menu (up to 5 seconds)
                    set deviceMenuItem to missing value
                    set waitCount to 0
                    repeat while deviceMenuItem is missing value and waitCount < 50
                        repeat with menuItem in menu items
                            if name of menuItem contains device then
                                set deviceMenuItem to menuItem
                                exit repeat
                            end if
                        end repeat
                        if deviceMenuItem is missing value then
                            delay 0.1
                            set waitCount to waitCount + 1
                        end if
                    end repeat

                    if deviceMenuItem is missing value then
                        error "Device '" & device & "' not found in AirPlay Display menu. Make sure your iPad is awake and nearby."
                    end if

                    -- Check if device is already connected in Universal Control mode
                    -- Support both English and German text
                    set itemName to name of deviceMenuItem as string
                    if itemName contains "Link" or itemName contains "Control" or itemName contains "verknüpfen" or itemName contains "Tastatur" then
                        -- Already in Universal Control mode, just close menu
                        key code 53 -- ESC key
                        tell application "System Settings" to quit
                        return "✅ iPad already connected via Universal Control"
                    end if

                    -- Click on the device
                    click deviceMenuItem

                    -- Wait for submenu if it exists
                    delay 0.5

                    -- Look for Universal Control option in multiple languages
                    if exists menu 1 of deviceMenuItem then
                        tell menu 1 of deviceMenuItem
                            set universalControlClicked to false

                            -- First try: Look for text patterns (English and German)
                            repeat with subItem in menu items
                                set subItemName to name of subItem as string
                                if subItemName contains "Link" or subItemName contains "Keyboard" or subItemName contains "Mouse" or subItemName contains "verknüpfen" or subItemName contains "Tastatur" or subItemName contains "Maus" then
                                    click subItem
                                    set universalControlClicked to true
                                    exit repeat
                                end if
                            end repeat

                            -- Fallback: If no text match found, try first menu item (usually Universal Control)
                            if not universalControlClicked and (count of menu items) > 0 then
                                click menu item 1
                            end if
                        end tell
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
        set successMsg to "✅ iPad '" & device & "' connected via Universal Control"
        log successMsg
        display notification "Connected via Universal Control" with title "iPad Control" subtitle device

        return successMsg

    on error errMsg
        try
            tell application "System Settings" to quit
        end try

        set errorMsg to "❌ Failed to connect iPad via Universal Control: " & errMsg
        log errorMsg
        display notification "Connection failed" with title "iPad Control" subtitle errMsg

        return errorMsg
    end try
end run