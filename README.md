# TimeControlPlus

A mod for the game Sapiens.  This mod adds a calendar to the Time Control HUD to add seasons, day and year counters.  Currently under development so it's not stable.

## Overview

The year and day of the year are calculated by taking the age of the world in seconds and dividing by the length of a day, both attributes are provided by the world object.

## Behavior

The season is calculated simply by what day of the year it is, though the game engine does seem to have
a more complicated determination of what season it is. However, for the purpose of showing the player the season it seems to be a reasonably good guide.

