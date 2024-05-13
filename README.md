# TimeControlPlus

A mod for the fantastic colony sim [Sapiens](https://store.steampowered.com/app/1060230/Sapiens/).  This mod adds a new component to the Time Control HUD in the upper left-hand corner of the screen showing the current year, day of the year (1-8), UTC time and current season as an icon.

## Overview

First a brief explanation of how time progression works in Sapiens.  The default game year is divided into 4 seasons, with each season having a duration of 2 game days, meaning a game year is 8 game days.  The new control provides the current Year, the current day of the year (day 1-8), world time, as well as a graphical representation of the season. 

When you begin a game, you will not necessarily start on day 1 as there are many factors that are considered: where on the globe you start, time passed once you have selected your world, time of day at the location you start a new world, and others.  The exact spot on the original sundial that a game day changes will be based on the clock marker position when you first started playing a newly generated world.  However the day will change at 00:00 UTC on the mod's digital clock, it just won't line up on the sundial to midnight.

More information about [Time](https://wiki.playsapiens.com/index.php/Time) in Sapiens can be found on the [Sapiens Official Wiki](https://wiki.playsapiens.com).

## Seasons

An Apple Tree is used as the season icon and will change based on the current season.  A notification will also appear on the screen, however on the notification it is always the summer tree.

**Spring**, pink blooms on the apple tree<br>
![Spring](/assets/spring.png)

**Summer**, green leaves<br>
![Summer](/assets/summer.png)

**Autumn**, the leaves are beginning to yellow<br>
![Autumn](/assets/autumn.png)

**Winter**, no leaves<br>
![Winter](/assets/winter.png)

The season indicated by the icon is based only on the day of the year it is, so it is a meteorological season determination.  The Sapiens game is built on a planet renderer and the climate model is quite sophisticated.  Much like real life the plant foliage and ground cover will change gradually as you approach seasonal boundaries - it is not a dramatic landscape change at the precise time the season changes.

## Known Issues

* None

## Future Enhancements

* Tooltips on the items with additional statistics
* New year notification

## Support

Please [raise an issue](https://github.com/ChillGenXer/TimeControlPlus/issues) for any bug reports or enhancement suggestions.

## Interested in creating your own mod?

Sapiens was built from the ground up with modding in mind.  If you are interested in creating a mod for Sapiens check out the resources below.

* [Official Sapiens Modding Site](https://github.com/Majic-Jungle/sapiens-mod-creation)
* [Community Modding Site](https://wiki.sapiens.dev/)
