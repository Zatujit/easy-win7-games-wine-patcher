#!/bin/bash

WINE_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/11.6/wine-11.6-amd64.tar.xz"
WINE_TAR_FILE="wine-11.6-amd64.tar.xz"

WIN7GAMES_URL="https://archive.org/download/windows7games-for-windows-11-10-8/Windows7Games_for_Windows_11_10_8.zip"
WIN7GAMES_ZIP="Windows7Games_for_Windows_11_10_8.zip"
WIN7GAMES_EXE="Windows7Games_for_Windows_11_10_8.exe"

WINE_EXEC="wine-11.6-amd64/bin/wine"
WINE_BOOT="wine-11.6-amd64/bin/wineboot"
WINE_PREFIX="$HOME/win7-classic-games"

RESHACKER_URL="https://www.angusj.com/resourcehacker/resource_hacker.zip"
RESHACKER_ZIP="resource_hacker.zip"
RESHACKER_EXE="ResourceHacker.exe"

RESHACKER_SCRIPTS_DIR="reshacker_scripts"
HASHES_DIR="hashes"

MICROSOFT_GAMES_WIN="C:\\Program Files\\Microsoft Games"
MICROSOFT_GAMES_LINUX="$WINE_PREFIX/drive_c/Program Files/Microsoft Games"

declare -A GAMES=(
  [CHESS]="Chess"
  [FREECELL]="FreeCell"
  [HEARTS]="Hearts"
  [MAHJONG]="Mahjong"
  [MINESWEEPER]="Minesweeper"
  [PURBLEPLACE]="PurblePlace"
  [SOLITAIRE]="Solitaire"
  [SPIDER_SOLITAIRE]="SpiderSolitaire"
)

# 1 -- Download Wine

echo "===== Downloading wine-11... ====="

# Download wine from the Kron4ek repository
if [ ! -f "$WINE_TAR_FILE" ]; then
    wget -O "$WINE_TAR_FILE" "$WINE_URL"
fi

if [ ! -f "$WINE_TAR_FILE" ]; then
    echo "$WINE_TAR_FILE not found. Aborting."

    exit 1
fi

tar -xvf "$WINE_TAR_FILE"

echo "===== Downloading win7games aero from Internet Archive ====="

# Download win7games
if [ ! -f "$WIN7GAMES_ZIP" ]; then
    wget -O "$WIN7GAMES_ZIP" "$WIN7GAMES_URL"
fi

if [ ! -f "$WIN7GAMES_ZIP" ]; then
    echo "$WIN7GAMES_ZIP not found. Aborting."

    exit 1
fi

unzip "$WIN7GAMES_ZIP"

echo "===== Downloading ResourceHacker... ====="

# Download ResourceHacker

if [ ! -f "$RESHACKER_ZIP" ]; then
    wget -O "$RESHACKER_ZIP" "$RESHACKER_URL"
fi

if [ ! -f "$RESHACKER_ZIP" ]; then
    echo "$RESHACKER_ZIP not found. Aborting."

    exit 1
fi

unzip "$RESHACKER_ZIP"

# Install win7games in headless mode

echo "===== Downloading win7games aero headlessly ====="
WINEARCH=win64 WINEPREFIX="$WINE_PREFIX" "$WINE_BOOT"
WINEARCH=win64 WINEPREFIX="$WINE_PREFIX" "$WINE_EXEC" "Windows7Games_for_Windows_11_10_8.exe" /S

for game in "${!GAMES[@]}"; do
  name="${GAMES[$game]}"
  
  echo "===== Patching $name ====="

  if [ "$game" = "PURBLEPLACE" ]; then
    WIN_PATH="$MICROSOFT_GAMES_WIN\\Purble Place"
    LINUX_PATH="$MICROSOFT_GAMES_LINUX/Purble Place"
  else
    WIN_PATH="$MICROSOFT_GAMES_WIN\\$name"
    LINUX_PATH="$MICROSOFT_GAMES_LINUX/$name"
  fi

  EXE_PATCHED_WIN="$WIN_PATH\\${name}_patched.exe"
  RSC_WIN="$WIN_PATH\\${name}_resources.res"
  RSC_LINUX="$LINUX_PATH/${name}_resources.res"

  SCRIPT_PATH="$RESHACKER_SCRIPTS_DIR/${name}-script.txt"

  if [ "$game" = "CHESS" ]; then
    MUI_FILE="$WIN_PATH\\en-US\\chess.exe.mui"
  else
    MUI_FILE="$WIN_PATH\\en-US\\${name}.exe.mui"
  fi

  # Extract resources
  WINEARCH=win64 WINEPREFIX="$WINE_PREFIX" "$WINE_EXEC" "$RESHACKER_EXE" -open "$MUI_FILE" -save "$RSC_WIN" -action extract -mask ",,," -log "$WIN_PATH\\extract-res.log"

  # Patch
  cp "$SCRIPT_PATH" "$LINUX_PATH/script.txt"

  # Execute script
  WINEARCH=win64 WINEPREFIX="$WINE_PREFIX" "$WINE_EXEC" "$RESHACKER_EXE" -script "$WIN_PATH\\script.txt"
done

echo "===== Verifying hashes ====="

for game in "${!GAMES[@]}"; do
  name="${GAMES[$game]}"
  
  if [ "$game" = "PURBLEPLACE" ]; then
    WIN_PATH="$MICROSOFT_GAMES_WIN\\Purble Place"
    LINUX_PATH="$MICROSOFT_GAMES_LINUX/Purble Place"
  else
    WIN_PATH="$MICROSOFT_GAMES_WIN\\$name"
    LINUX_PATH="$MICROSOFT_GAMES_LINUX/$name"
  fi

  EXE_PATCHED_LINUX="$LINUX_PATH/${name}_patched.exe"
  RSC_WIN="$WIN_PATH\\${name}_resources.res"
  RSC_LINUX="$LINUX_PATH/${name}_resources.res"

  actual=$(md5sum "$EXE_PATCHED_LINUX" | awk '{print $1}')
  expected=$(awk '{print $1}' "$HASHES_DIR/$name.md5sum")

  if [ "$actual" = "$expected" ]; then
    printf "%-20s [V] $name\n"
  else
    echo "$actual $expected"
    printf "%-20s [X] $name      !!! Hash mismatch\n"
  fi
done

read -p "Lutris config? [Y/n]: " answer

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
   exit 0
fi

if command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q net.lutris.Lutris; then
  LUTRIS_CMD="flatpak run net.lutris.Lutris"
  LUTRIS_DIR="$HOME/.var/app/net.lutris.Lutris/data"
elif command -v snap >/dev/null 2>&1 && snap list lutris >/dev/null 2>&1; then
  LUTRIS_CMD="lutris"
  LUTRIS_DIR="$HOME/snap/lutris/common"
elif command -v lutris >/dev/null 2>&1; then
  LUTRIS_CMD="lutris"
  LUTRIS_DIR="/tmp"
else
  echo "No Lutris found"
  exit 1
fi

for game in "${!GAMES[@]}"; do
  name="${GAMES[$game]}"

  read -p "Add $name to Lutris? [Y/n]: " answer
  answer=${answer:-Y}

  if [[ "$answer" =~ ^[Yy]$ ]]; then
    TMP_YML="$LUTRIS_DIR/lutris-install-$name.yml"
    cat > "$TMP_YML" <<EOF
name: "$name"
slug: "win7-classic-games-$name"
game_slug: "win7-classic-games-$name"
version: "Local"
runner: wine
script:
  game:
    exe: "$MICROSOFT_GAMES_LINUX/$name/${name}_patched.exe"
    working_dir: "$MICROSOFT_GAMES_LINUX/$name"
    prefix: "$WINE_PREFIX"
  installer: []
EOF

    $LUTRIS_CMD -i "$TMP_YML" &
  else
    echo "Skipping Lutris entry"
  fi
done

