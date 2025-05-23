from random import choice
from PIL import Image
from collections import Counter
from json import dump
from os import getenv
from subprocess import run
from argparse import ArgumentParser

# open file with all available pokemon names
with open('pokemon_names.txt', 'r') as names_file:
    pokemon_names = names_file.readlines()

# strip off newline characters
pokemon_names = [item[:-1] for item in pokemon_names]

# create parser instance
parser = ArgumentParser()

# create pokemon argument
parser.add_argument("-p", "--pokemon", help="name of pokemon", required=False)

# call parse_args
args = parser.parse_args()

if args.pokemon in pokemon_names:
    pokemon = args.pokemon
else:
    # pick a random pokemon from list
    pokemon = choice(pokemon_names)

# path to wallpaper of chosen pokemon
wallpaper_path = "poketop_wallpapers/" + pokemon + ".jpg"

# grab username
user = getenv('USER')

# create config using template
wpaperd_config = f'''
[default]
duration = "30m"
mode = "center"
sorting = "ascending"

[DP-1]
path = "/home/{user}/poketop/{wallpaper_path}"

[HDMI-A-1]
path = "/home/{user}/poketop/{wallpaper_path}"

[default.transition.film-burn]
'''
# write the wpaperd config to the toml file
with open('wpaperd_config.toml', 'w') as wpaperd_config_file:
    wpaperd_config_file.writelines(wpaperd_config)

# update wallpaper
result = run(['wpaperctl', 'next-wallpaper'])

# Open wallpaper image
img = Image.open(wallpaper_path)

# list out all pixels
pixels = list(img.getdata())

# Count colors
color_counts = Counter(pixels)
    
# Get the most common color
most_common_color = color_counts.most_common(1)[0][0]  # (R, G, B)

# Convert to hex
hex_color = '#{:02x}{:02x}{:02x}'.format(*most_common_color)

# format items for json
items = {
    "name": pokemon,
    "color": hex_color,
}

# write items to the pokemon json file
with open('pokemon.json', 'w') as pokemon_json:
    dump(items, pokemon_json, indent=4)