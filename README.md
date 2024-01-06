# Game Binder
The purpose of this script is to allow the user to consolidate their game shortcuts from various runners into a set of easily maintainable plain text files and filter/search this collection. The script currently supports showing preview images for the highlighted runner/game through the kitty terminal graphics protocol.  

#### **Supported Runners:**
  * **Citra -** 3DS Emulation
  * **DeSmuME -** DS Emulation
  * **Dolphin -** GameCube/Wii Emulation
  * **Flycast -** Dreamcast Emulation
  * **Heroic -** Epic, GOG, & Amazon Prime Games
  * **Lutris -** Game Manager
  * **PCSX2 -** PS2 Emulation
  * **PPSSPP -** PSP Emulation
  * **RPCS3 -** PS3 Emulation
  * **Steam -** PC Games
  * **Yuzu -** Nintendo Switch Emulation 

## **Configuration**
Game Binder must be configured before it can function as intended.

#### **Managing Your Collection**
The file *collection.csv* holds each game that we want to manage with this script. Entries in this file are formatted like so:

    GameTitle,Runner,GameID or ExecutableFilename

Games can be added manually or by using the -a or -d flag for interactive addition or removal respectively.

#### **Managing Preview Images**
Game Binder looks for a PNG file that has the same basename as the currently highlighted entry in the appropriate subdirectory of the images directory.

#### **Setting ROM paths**
The file *preferences.conf* contains variables that hold the ROM path for each supported emulator (e.g. "/mnt/games/ROMS/PSP").

## **Dependencies**
* [fzf](https://github.com/junegunn/fzf)
* [kitty](https://github.com/kovidgoyal/kitty)

## Planned Enhancements
* Expand the list of supported runners
* Improve error handling
* Support fzf's multi-mode when creating filter
* Support filtering by genre
* Support other common image protocols
