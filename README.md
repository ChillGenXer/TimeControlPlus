# TimeControlPlus

A mod for the colony simulation game [Sapiens](https://store.steampowered.com/app/1060230/Sapiens/) that expands the Time Control HUD with useful calendar and seasonal information.

TimeControlPlus displays the current **Year**, **World Time (WT)** and **Season**, while fitting alongside Sapiens' existing time controls.

It supports both current Sapiens release lines:

- **Public Version (0.6.1.3):** TimeControlPlus provides its classic Day display.
- **public-beta-unstable (0.7.0.2 - Conflict Update):** Sapiens provides its own native Day and Population display, so TimeControlPlus leaves it intact and adds its information alongside it.

## Overview

Sapiens has both a world calendar and a local day/night cycle.

By default, a game year contains four seasons, with each season lasting two game days for a total of eight days per year. TimeControlPlus reads Sapiens' own world clock and year settings rather than assuming the default values, so the calendar will continue to work correctly if you customize the day or year length in the world's configuration file.

The HUD provides:

- **Year:** the current year in the Sapiens world calendar.
- **Day:** in the **Public Version (0.6.1.3)**, TimeControlPlus shows the age of your tribe in days, beginning with Day 1. The **public-beta-unstable (0.7.0.2 - Conflict Update)** provides this information natively.
- **World Time (WT):** a digital representation of the global Sapiens world clock.
- **Season:** represented by an apple tree that changes appearance as the seasons progress.

World Time is a global game clock, so it should not be confused with the local solar time at your tribe's position on the planet. Depending on where you are located, the sun and sundial will not necessarily line up with `00:00 WT`.

More information about [Time](https://wiki.playsapiens.com/index.php/Time) in Sapiens can be found on the [Sapiens Official Wiki](https://wiki.playsapiens.com).

## Seasons

TimeControlPlus uses an Apple Tree to represent the current season. The displayed season follows the Sapiens seasonal cycle and also accounts for whether your tribe is in the northern or southern hemisphere.

A notification is displayed when the season changes. These notifications use Sapiens' standard apple-tree notification image.

**Spring:** pink blooms on the apple tree

![Spring](/assets/spring.png)

**Summer:** green leaves

![Summer](/assets/summer.png)

**Autumn:** leaves beginning to yellow

![Autumn](/assets/autumn.png)

**Winter:** no leaves

![Winter](/assets/winter.png)

The season icon changes at the calendar boundary, but the Sapiens environment does not instantly change with it. The game's climate and vegetation systems transition gradually, much like seasons in the real world, so foliage and ground cover may begin changing before or after the calendar moves into the next season.

## Support

If you encounter a problem or have an enhancement suggestion, please [raise an issue on GitHub](https://github.com/ChillGenXer/TimeControlPlus/issues).

## Interested in modding Sapiens?

Sapiens was designed from the beginning with modding support built in. Installing a mod does not mean altering or hacking the game's original files. Mods are a normal part of the Sapiens ecosystem and can be added or removed without changing the base game.

If you enjoy TimeControlPlus and want to explore what else the community has created, or perhaps try building a mod of your own, these resources are good places to start:

- [Official Sapiens Modding Site](https://github.com/Majic-Jungle/sapiens-mod-creation)
- [Community Modding Site](https://wiki.sapiens.dev/)
