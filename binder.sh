#!/bin/bash
#Author: Natalie Niemeir

# Ensure that user enters something
validateInput() {
    if [ -z "$1" ]; then
        echo "Error: $2 cannot be empty."
        exit 1
    fi
}

# User input is taken for each field of a new entry in our collection
addGame() {
	echo "Enter the Game's title: "
	read -r newTitle
	validateInput "$newTitle" "Title"
	echo "Enter the Game's runner: "
	newRunner=$(echo -e "$SUPPORTED_RUNNERS" | fzf --delimiter , --with-nth -1 --height=80% --padding=5,40,0,40 --layout=reverse --cycle --preview='
file_path=images/runners/{}
file_name="${file_path%.*}"
preview_file="${file_name}.png"
if [ -e "$preview_file" ]; then
  kitty icat --clear --transfer-mode=stream --stdin=no --place=40x40@20x20 "$preview_file"
else
  kitty icat --clear --transfer-mode=stream --stdin=no --place=40x40@20x20 "images/error.png"
fi
' --preview-window noborder,up,30)
	kitty icat --clear
	validateInput "newRunner" "Runner"
	echo "Enter the Game's gameID or filename: "
	read -r newGameID
	validateInput "$newGameID" "ID/Filename"
	echo "$newTitle,$newRunner,$newGameID" >> collection.csv
	sort collection.csv -o collection.csv
	echo "Game added to collection"
	exit 0
}

# It is determined which supported runners are installed
enumerateRunners() {
	case $runner in
	BlastEm) flatpak list | grep "com.retrodev.blastem" ;;
	bsnes) flatpak list | grep "dev.bsnes.bsnes" ;;
	Citra) flatpak list | grep "org.citra_emu.citra" ;;
	DeSmuME) flatpak list | grep "org.desmume.DeSmuME" ;;
	Dolphin) flatpak list | grep "org.DolphinEmu.dolphin-emu" ;;
	Flycast) flatpak list | grep "org.flycast.Flycast" ;;
	Heroic) command -v heroic ;;
	Lutris) command -v lutris ;;
	Nestopia) flatpak list | grep "ca._0ldsk00l.Nestopia" ;;
	PCSX2) flatpak list | grep "net.pcsx2.PCSX2" ;;
	PPSSPP) flatpak list | grep "org.ppsspp.PPSSPP" ;;
	RPCS3) flatpak list | grep "net.rpcs3.RPCS3" ;;
	Steam) command -v steam ;;
	Yuzu) flatpak list | grep "org.yuzu_emu.yuzu" ;;
	*)
		echo "Error: Invalid Runner"
		exit 1
		;;
	esac
}

# An fzf search window is displayed. The line whose first field matches our selection is deleted from our collection
removeGame() {
	selection=$(awk 'BEGIN { FS = "," } { print $1}' collection.csv | fzf --delimiter , --with-nth -1 --height=80% --padding=5,40,0,40 --layout=reverse --cycle)
	read -p "Remove $selection from collection? (Press Y to confirm)" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		grep -v "$selection" collection.csv >tempCollection && mv tempCollection collection.csv
		echo "$selection removed from collection"
	fi
	exit 0
}

# The command used to launch the selected game is determined from the matching line's second field
launch() {
	case $runner in
	BlastEm)
		flatpak run com.retrodev.blastem "$MD_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	bsnes)
		flatpak run dev.bsnes.bsnes "$SNES_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	Citra)
		flatpak run org.citra_emu.citra "$TDS_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	DeSmuME)
		flatpak run org.desmume.DeSmuME "$DS_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	Dolphin)
		flatpak run org.DolphinEmu.dolphin-emu "$GAMECUBE_WII_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	Flycast)
		flatpak run org.flycast.Flycast "$DREAMCAST_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	Heroic)
		xdg-open heroic://launch/legendary/"$gameID" > /dev/null 2>&1 &
		;;
	Lutris)
		env LUTRIS_SKIP_INIT=1 lutris "lutris:rungameid/$gameID" > /dev/null 2>&1 &
		;;
	Nestopia)
		flatpak run ca._0ldsk00l.Nestopia "$NES_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	PCSX2)
		flatpak run net.pcsx2.PCSX2 "$PS2_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	PPSSPP)
		flatpak run org.ppsspp.PPSSPP "$PSP_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	RPCS3)
		flatpak run net.rpcs3.RPCS3 "$PS3_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	Steam)
		steam steam://rungameid/"$gameID" > /dev/null 2>&1 &
		;;
	Yuzu)
		flatpak run org.yuzu_emu.yuzu -u 1 -f -g "$SWITCH_ROMS/$gameID" > /dev/null 2>&1 &
		;;
	*)
		echo "The runner $runner is not currently supported"
		;;
	esac
}

promptFilter() {
while true; do
clear
echo "Select Runner(s) To Display Games From: "
# Create search and preview fzf windows for each available runner
# The user can choose to only view games from a single runner, selecting multiple runners is currently not supported
filter=$(echo -e "$availableRunnersDisplay" | fzf --delimiter , --with-nth -1 --height=80% --padding=5,40,0,40 --layout=reverse --cycle --preview='
file_path=images/runners/{}
file_name="${file_path%.*}"
preview_file="${file_name}.png"
if [ -e "$preview_file" ]; then
  kitty icat --clear --transfer-mode=stream --stdin=no --place=40x40@20x20 "$preview_file"
else
  kitty icat --clear --transfer-mode=stream --stdin=no --place=40x40@20x20 "images/error.png"
fi
' --preview-window noborder,up,30)

# If input not given for filter, exit script
if [ -z "$filter" ]; then
	clear
	exit 0
fi

# If filter is All, the variable is emptied
if [ "$filter" == "All" ]; then
	filter=""
fi

# Each line that fits our filter criteria is saved to this variable
filtered=$(awk -v filter="$filter" -v availableRunners="$availableRunners" 'BEGIN { FS = "," } {
	if (filter == "") {
		if (index(availableRunners, $2) > 0) {
		print $1;
	}
	}
else {
	split(filter, runners, /\n/);
	for (i in runners) {
		if ($2 == runners[i]) {
		print $1;
	   }
	}
}
}' collection.csv)


clear
break
done
}

promptGame() {
	while true; do
echo "Select Game To Launch: "
# Create search and preview fzf windows for each game fitting our criteria
selection=$(echo -e "$filtered" | fzf --delimiter , --with-nth -1 --height=80% --padding=5,40,0,40 --layout=reverse --cycle --preview='
file_path=images/games/{}
file_name="${file_path%.*}"
preview_file="${file_name}.png"
if [ -e "$preview_file" ]; then
  kitty icat --clear --transfer-mode=stream --stdin=no --place=40x40@20x20 "$preview_file"
else
  kitty icat --clear --transfer-mode=stream --stdin=no --place=40x40@20x20 "images/error.png"
fi
' --preview-window noborder,up,30)

# Clear image after selection is made
kitty icat --clear

# The loop breaks if no game is selected
if [ -z "$selection" ]; then
	break
fi

# Grab the other fields of the line in our collection whose first field is the same as the selected game
runner=$(awk 'BEGIN { FS = "," } /'"$selection"'/ { print $2 }' collection.csv)
gameID=$(awk 'BEGIN { FS = "," } /'"$selection"'/ { print $3 }' collection.csv)

# Launch the selected game
launch

clear

# Clear screen once game launches
sleep 1
exit 0
done
}



usage() {
	printf "
Usage:
./binder.sh [options]
  -a			  Add game to collection 
  -d			  Delete game from collection
  -h 			  Show help	
      	\n"
	exit 0
}

clear

# Ensure configuration file is present
source preferences.conf || {
	echo "Error: No configuration file found."
	exit 1
}

# Ensure script is being run in kitty
if [ "$TERM" != "xterm-kitty" ]; then
	echo "This script must be run in kitty terminal"
fi

# Ensure fzf is installed
command -v fzf >/dev/null 2>&1 || {
	echo >&2 "Error: fzf not found"
	exit 1
}


SUPPORTED_RUNNERS="BlastEm\nbsnes\nCitra\nDeSmuME\nDolphin\nFlycast\nHeroic\nLutris\nNestopia\nPCSX2\nPPSSPP\nRPCS3\nSteam\nYuzu"


while getopts "adh" flag; do
	case $flag in
	a) addGame ;;
	d) removeGame ;;
	h) usage ;;
	\?)
		echo "Error: Invalid flag"
		exit 1
		;;
	esac
done

unavailableRunners=""
for runner in $(echo -e "$SUPPORTED_RUNNERS"); do
	if [[ ! $(enumerateRunners "$runner") ]]; then
		unavailableRunners="$unavailableRunners$runner"
	fi
done

# If a runner in SUPPORTED_RUNNERS is installed, it is appended to availableRunners
availableRunners=""
for runner in $(echo -e "$SUPPORTED_RUNNERS"); do
	if [[ ! "$unavailableRunners" =~ "$runner" ]]; then
		availableRunners="$availableRunners$runner\n"
	fi
done

# Strip trailing newline and prepend "All" option before creating fzf windows
availableRunners=$(echo -e "$availableRunners" | sed -e '$!b' -e '/^\n*$/d')
availableRunnersDisplay="All\n$availableRunners"



while true; do
promptFilter

promptGame
done
