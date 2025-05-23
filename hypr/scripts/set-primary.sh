#!/bin/bash

# Wait for 5 seconds
sleep 5

# Set DP-1 as the primary display
xrandr --output DP-1 --primary

# wait for 3 seconds
sleep 3

# reload waybar
killall -SIGUSR2 waybar