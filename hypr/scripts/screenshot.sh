#!/bin/bash

directory="$HOME/Pictures/Screenshots"
temp_svg="/home/knee/.config/swaync/icons/screenshot.svg"  # Use your preferred static SVG path

# Ensure screenshot directory exists
mkdir -p "$directory"

# Function to send a notification with an action
send_notification() {
    action=$(notify-send -a screenshot -i "$temp_svg" "Screenshot copied" "Screenshot saved under ~/Pictures/Screenshots/screenshot_$timestamp.png" -t 5000 -A "pinta=Edit Screenshot")
    [[ "$action" == "pinta" ]] && pinta "$directory/screenshot_$timestamp.png"
}

# Function to save the screenshot
save_screenshot() {
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    mv /tmp/screenshot.png "$directory/screenshot_$timestamp.png"
}

# Function to handle screenshot actions
take_screenshot() {
    local type="$1"
    grimblast copysave "$type" /tmp/screenshot.png
    save_screenshot
    send_notification
}

# Main script execution
case "$1" in
    --current-monitor) take_screenshot output ;;
    --all-monitors) take_screenshot screen ;;
    --area) take_screenshot area ;;
    --frozen-area) grimblast --freeze copysave area /tmp/screenshot.png; save_screenshot; send_notification ;;
    *) echo "Usage: $0 {--current-monitor|--all-monitors|--area|--frozen-area}" ;;
esac
