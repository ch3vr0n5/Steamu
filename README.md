# Steamu
This project is based on the idea and methodology of [EmuDeck](https://github.com/dragoonDorise/EmuDeck). It was originally a fork but being based on a different OS and different scripting language it has since be re-imported.

# <img src="https://i.ibb.co/HT2DdDC/Screenshot-BP.png">

Steamu is a collection of scripts for Windows that automatically downloads, installs, and configures popular emulators for painless integration within the Steam library whether you use it exclusively on the desktop or prefer Big Picture Mode. It creates your roms directory structure and downloads all of the needed Emulators for you along with the recommended configurations for each of them. Steamu uses [Steam Rom Manager](https://github.com/SteamGridDB/steam-rom-manager) for this integration but is configured "out of the box" to work with [EmulationStation Desktop Edition (ES-DE)](https://es-de.org/) as well.

There are two ways of using Steamu:

## Using Steam Rom Manager

<img src="https://i.ibb.co/8dz5zQj/Screenshot-SRM.png">

This option gives you all your games presented with their box arts as if they were a regular Steam Game.
Steamu has preloaded configurations for Steam Rom Manager for the following systems:

PLEASE NOTE: Emulators listed below with an asterisk* have not yet been configured but may download. This are currently being worked on.

| System                    | Emulator                             | Roms format                                                          |
| ------------------------- | ------------------------------------ | -------------------------------------------------------------------- |
| Atari 2600                | Retroarch Stella core                | .7z .a26 .bin .zip                                                   |
| Atari Lynx                | Retroarch Beetle Lynx core           | .7z .lnx .bin .zip                                                   |
| GameBoy                   | Retroarch Gambatte core              | .7z .gb .dmg .zip                                                    |
| GameBoy Color             | Retroarch Gambatte core              | .7z .gb .gbc .dmg .zip                                               |
| GameBoy Advance           | Retroarch mGBA core                  | .7z .gba .zip                                                        |
| Dreamcast                 | Retroarch FlyCast Core               | .7z, .cdi, .chd, .cue, .gdi                                          |
| Final Burn Neo            | Retroarch Fbn core                   | .zip .7z                                                             |
| Mame 2003 Plus            | Retroarch Mame 2003 Plus core        | .zip                                                                 |
| Mame 2010                 | Retroarch Mame 2010 core             | .zip                                                                 |
| Mame Current              | Retroarch Mame Current core          | .zip                                                                 |
| Neo Geo Pocket & Color    | Retroarch Beetle NeoPop              | .7z .ngp .ngc .bin .zip                                              |
| Nintendo GameCube         | Dolphin Standalone*                  | .ciso .dol .elf .gcm .gcz .iso .nkit .iso .rvz .wad .wia             |
| Nintendo DS               | Retroarch melonDS core               | .7z .nds .zip                                                        |
| Nintendo 3DS              | Citra*                               | .3ds .3dsx .app .axf .cii .cxi .elf .cia                             |
| Nintendo NES              | Retroarch Nestopia core              | .7z .nes .fds .unf .unif .zip                                        |
| Nintendo 64               | Retroarch Mupen64plus core           | .7z .bin .n64 .ndd u1 .v64 .z64 .zip                                 |
| Nintendo GameCube         | Dolphin Standalone*                  | .ciso .dol .elf .gcm .gcz .iso .nkit .iso .rvz .wad .wia .wbfs       |
| Nintendo Wii              | Dolphin Standalone*                  | .ciso .dol .elf .gcm .gcz .iso .json .nkit .iso .rvz .wad .wia .wbfs |
| Nintendo Wii U            | Cemu                                 | .rpx .wud .wux .elf .iso .wad                                        |
| Nintendo Switch           | Yuzu*                                | .kp .nca .nro .nso .nsp .xci                                         |
| Super Nintendo            | Retroarch Snes9x Current core        | .7z .bs .fig .sfc .smc .swx .zip                                     |
| Super Nintendo Widescreen | Retroarch bsnes hd beta Current core | .7z .bs .fig .sfc .smc .swx .zip                                     |
| PrimeHacks                | Dolphin PrimeHacks*                  | .ciso .dol .elf .gcm .gcz .iso .json .nkit .iso .rvz .wad .wia .wbfs |
| Playstation               | DuckStation*                         | .cue .chd .ecm .iso .m3u .mds .pbp                                   |
| Playstation 2             | PCSX2                                | .bin chd .cso .dump .gz .img .iso .mdf .nrg                          |
| Playstation 3             | RPCS3*                               | /PS3_GAME/USRDIR/eboot.bin                                           |
| PSP                       | PPSSPP & PPSSPP Retroarch core       | .7z .elf .cso .iso .pbp .prx                                         |
| Sega 32X                  | Retroarch PicoDrive core             | .7z .32x .bin .zip                                                   |
| Sega CD                   | Retroarch Genesis Plus GX core       | .7z .32x .cue .chd .iso .zip                                         |
| Sega Game Gear            | Retroarch Genesis Plus GX core       | .7z .gg .zip                                                         |
| Sega Genesis / Mega Drive | Retroarch Genesis Plus GX core       | .7z .gen .md .smd .zip                                               |
| Sega Genesis Widescreen   | Retroarch Genesis Plus GX Wide core  | .7z .gen .md .smd .zip                                               |
| Sega Master System        | Retroarch Genesis Plus GX core       | .7z .gen .sms .zip                                                   |
| Sega Saturn               | Retroarch Yabause core               | .7z .cue .iso .chd .zip                                              |
| Wonderswan & Color        | Retroarch Beetle Cygne core          | .7z .pc2 .ws .wsc .zip                                               |

## Using EmulationStation DE

<img src="https://es-de.org/____impro/1/onewebmedia/ES-DE_logo.png?etag=%226071-6041244a%22&sourceContentType=image%2Fpng&ignoreAspectRatio&resize=240%2B168">

Steamu configures EmulationStation DE to use the same rom folders that Steamu creates for you and it even downloads all the emulators and cores that EmulationStation DE needs. All configurations that Steamu installs are carried over when using EmulationStation DE. For a comprehensive list of all the systems that EmulationStation DE supports go to [EmulationStation DE](https://es-de.org/)

# Hotkeys

We try to use the same hotkeys for every emulator but some of them have their own that cannot be changed. Not all hotkeys are currently configured. This is being worked on.

|  Hotkey         | RetroArch      | Dolphin        | Citra \* | Cemu \*        | Yuzu           | PCSX2 \*     | RPCS3        |
| --------------- | -------------- | -------------- | -------- | -------------- | -------------- | ------------ | ------------ |
| Menu            | L3 + R3        | -              | -        | -              | -              | -            | -            |
| Exit            | Select + Start | Select + Start |          | Select + Start | Select + Start | Home Button  | Home Button  |
| Pause Emulation | Select + A     | Select + A     | -        | -              | Select + A     |              | -            |
| Fast Forward    | Select + R2    | Select         | -        | -              | Select + R2    | Select + R2  | -            |
| Load State      | Select + L1    | Select + L1    | -        | -              | -              | Select + L1  | -            |
| Save State      | Select + R1    | Select + R1    | -        | -              | -              | Select + R1  | -            |
| Full Screen     | -              | -              |          | -              | -              | -            | -            |
| Swap Screens    | -              | -              |          |                | -              | -            | -            |
| Toggle Layout   | -              | -              |          | -              | -              | -            | -            |

\* You need to activate Steam Input to get those hotkeys to work https://www.emudeck.com/#steam_input

# Want to contribute?

Feel free to submit Pull Requests. Steamu follows the same philosophy as EmuDeck; therefore, you should keep in mind that this is developed to be very hands off for end users.
