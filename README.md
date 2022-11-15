# TimeControlPlus

A mod for the fantastic colony sim [Sapiens](https://store.steampowered.com/app/1060230/Sapiens/).  This mod adds a new component to the Time Control HUD in the upper left-hand corner of the screen showing the current year, day of the year (1-8) and current season.

## Overview

Understanding how this mod works requires a brief explanation of how time progression is implemented in Sapiens.  Each game year is divided into 4 seasons, with each season having a duration of 2 game days, meaning a year is 8 game days.  From the control you will see the current Year, the current day of the year (day 1-8) as well as a graphical representation of the season. 

The year and day of the year are calculated by taking the age of the world in seconds and dividing by the configured length of a day.  When you begin a game, you will not necessarily start on day 1 as there are many factors that are considered: where on the globe you start, time passed once you have selected your world, time of day at the location you start a new world, and others.  The exact time that your day increments will be based on the time of day it was when you first started playing on a newly generated world.  This is an accurate definition of how many days you have been playing a world but doesn't match the real-world convention of the day incrementing at midnight.

More information about [Time](https://wiki.playsapiens.com/index.php/Time) can be found on the [Sapiens Official Wiki](https://wiki.playsapiens.com).

## Seasons

The Apple Tree is used as the season icon and will change based on the current season:

![Spring](/assets/spring.png) - Spring, pink blooms on the apple tree
![Summer](/assets/summer.png) - Summer, green leaves
![Autumn](/assets/autumn.png) - Autumn, the leaves are beginning to yellow
![Winter](/assets/winter.png) - Winter, no leaves

The season indicated by the icon is based only on the day of the year it is, so it is a meteorological season determination.  The Sapiens game is built on a planet renderer and the climate model is quite sophisticated.  Much like real life the plant foliage and ground cover will change gradually across seasonal boundaries - it is not a dramatic landscape change at the precise time a season changes.

## Known Issues

* Extreme FOV values will skew the apple tree icon.  I don't plan on doing anything about that at the moment.

## Future Enhancements
* The mod is currently not adjusting for southern hemisphere starts
* Tooltips on the items with additional statistics
* Possibly add a 24-hour clock

## Support

Please [raise an issue](https://github.com/ChillGenXer/TimeControlPlus/issues) for any bug reports or enhancement suggestions.

## Interested in creating a mod?

Sapiens was built from the ground up with modding in mind.  If you are interested in creating a mod for Sapiens check out the resources below.

* [Official Sapiens Modding Site](https://github.com/Majic-Jungle/sapiens-mod-creation)
* [Community Modding Site](https://wiki.sapiens.dev/)
