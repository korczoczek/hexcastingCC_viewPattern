# hexcastingCC_viewPattern
Allows for inspecting iotas stored inside focuses without having to use tools outside the game.

## Features

Ability to read and display iotas imbued with:
 - Patterns
 - Pattern Lists
 - Vectors
 - Numbers
 - Entities
 - MoreIotas:
   - Matrixes
   - Strings

Located inside:
 - Slates
 - Focuses (Using a Focal Port)
 - Akashic Bookshelves

## Requirements
 - [Computercraft](https://modrinth.com/mod/cc-tweaked)
 - [Tom's Peripherals](https://modrinth.com/mod/toms-peripherals) (GPU, Monitor)
 - [Ducky Peripherals](https://modrinth.com/mod/ducky-periphs) (Focal Port, various hexcasting APIs)

## Setup
By default the script will attempt to read from the block above and display using the GPU placed below (see picture below), to change this behaviour by editing the `hex_location` and `gpu_location` variables found in the beggining of the script.

Recommended monitor size is 3x3 blocks, but the script will attempt to scale to any monitor size
![Screenshot of the recommended script setup, the focal port is above the computer with the GPU below and a 3x3 monitor with its bottom left corner adjacent to the GPU](/images/setup.png)

## Installation
Download the script file
```
wget https://raw.githubusercontent.com/korczoczek/hexcastingCC_viewPattern/main/viewPattern.lua
```
**(Optional)** Download the pattern list file, which will enable the script to display names of input patterns
```
wget https://raw.githubusercontent.com/korczoczek/hexcastingCC_viewPattern/main/patternList.lua
```

## Customization
Several variables located at the script's beginning allow for customization of script behaviour
```
hex_location - location of iota to be read
gpu_location - location of the GPU
background - background color
patternListLoc - location of the patternList.lua file
```

## Known Issues
 - when physically changing monitor size it's nessesary for the script to be run twice before the change is refreshed internally
 - crash when the pattern to be displayed is just too damn big

## TODO
 - add missing pattern names
 - add ability to display more iota types
