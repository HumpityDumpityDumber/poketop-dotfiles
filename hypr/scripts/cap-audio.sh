#!/bin/bash

# The source name for your Elgato capture card (adjust if needed)
ELGATO_SOURCE="alsa_input.usb-Elgato_Elgato_HD60_X_A00XB422206D8Q-02.analog-stereo"

# Get source id of Elgato
source_id=$(pactl list sources short | awk -v src="$ELGATO_SOURCE" '$2 == src {print $1}')

if [ -z "$source_id" ]; then
  echo "Elgato source not found."
  exit 1
fi

# Loop through all source outputs and find ones attached to Elgato source
pactl list source-outputs | awk -v srcid="$source_id" '
  /^Source Output #/ { so_id = substr($3, 2) }
  /Source:/ { if ($2 == srcid) print so_id }
' | while read -r source_output_id; do
  echo "Setting volume of source output #$source_output_id to 60%"
  pactl set-source-output-volume "$source_output_id" 60%
done
