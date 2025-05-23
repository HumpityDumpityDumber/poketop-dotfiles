#!/bin/bash

echo "Choose an action:"
echo "1) Logout"
echo "2) Shutdown"
echo "3) Restart"
echo -n "Enter your choice [1-3]: "
read CHOICE

case $CHOICE in
    1)
        hyprctl dispatch exit
        ;;
    2)
        shutdown now
        ;;
    3)
        systemctl reboot
        ;;
    *)
        echo "Invalid choice."
        ;;
esac
