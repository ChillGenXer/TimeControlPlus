# TimeControlPlus

A mod for the game Sapiens.  This mod adds a calendar to the Time Control HUD to add seasons, day and year counters.  Currently under development so it's not stable.

## Overview

The year and day of the year are calculated by taking the age of the world in seconds and dividing by the length of a day, both attributes are provided by the world object.

## Behavior

The season is calculated simply by what day of the year it is, though the game engine does seem to have
a more complicated determination of what season it is. However, for the purpose of showing the player the season it seems to be a reasonably good guide.

## Stuff to figure out

* Not currently taking into account a southern hemisphere start.  Need to figure out where in the lua code to get the southern hemisphere state.
* Need to clean up the actual panel and seamlessly integrate it with the existing timeControls.
* Try to add a ModelImageView at the end to show the changing model of an apple tree through the seasons.
* The day currently changes at noon in my test world.  I am not sure if that would change based on where you started on the globe or when you created the new world in the main menu? I'm suspicious there is more to know here. 
