#!/bin/bash

# Name of your main monitor
MONITOR="DP-1"

# Disable the monitor using hyprctl
hyprctl keyword monitor "$MONITOR,disable"

# Optional: Feedback
echo "Monitor $MONITOR has been disabled."
