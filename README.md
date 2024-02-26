# Stoic Range Finder

![STOIC (1)](https://github.com/TheStoicBear/Stoic-RangeFinder/assets/112611821/29e1effa-80ad-44b7-9695-f6ecba8f29c9)



A Simple RangeFinder with Binocular animation, compass, and Rangefinder distance.

This script adds binoculars and a rangefinder functionality to your FiveM server. Players can use these tools to observe distant locations and measure distances.

## Features
- Zoom in/out with binoculars
- Pan left/right and up/down with binoculars
- Display distance to the target
- Display compass heading to the target
- Option to enable/disable marker display on the target

## Installation

1. Copy the script files into your FiveM server resources folder.

2. Add `ensure codex-rangefinder` to your server.cfg file.

3. Configure the script by editing the `config.lua` file.

## Configuration

Edit the `config.lua` file to customize various settings:

```lua
Config = {}

-- Binoculars/Rangefinder Configuration
Config.markerUse = true           -- Set to true to display the marker, false to hide it
Config.markerType = 0             -- Marker type (0: standard, 1: upsidedown cone, 2: vertical cylinder, 3: horizontal cylinder, 4: circle, 5: square, 6: vertical cylinder (upside down))
Config.markerSize = vector3(1.0, 1.0, 1.0) -- Marker size (X, Y, Z)
Config.markerColor = {255, 0, 0, 200}       -- Marker color (R, G, B, Alpha)
Config.textSize = 0.4             -- Text size
Config.textColor = {255, 255, 255, 255}    -- Text color (R, G, B, Alpha)
Config.textLocation = {0.5, 0.02}          -- Text location (X, Y)
```

## Commands
/startbinoculars: Activate binoculars.
/stopbinoculars: Deactivate binoculars.


### Credits
Some binocular code comes from 
https://forum.cfx.re/t/release-binoculars/84325

Credits to https://forum.cfx.re/t/release-binoculars/84325
For some of the camera script.
