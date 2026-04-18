=== Easy Win7 games patcher ===

- Installs and patches the Win7 classic games suite (from the Internet Archive / WinAero) for using it with Wine on Linux.
- Reproducible, hashes of the patched files are verified.
- Kron4ek Wine-11.6-amd64 build is used for running the windows executables.
- Adding desktop entries option.
- Automatic Lutris configuration possible (tested on Lutris Flatpak & native deb package for now).

I verified that the hashes using the GUI method and the CLI are stricly identical.

Run 
```bash
./install.sh
```

to install the games and patch them using ResourceHacker CLI.

The WINE prefix is installed at `~/win7-classic-games`.

For instance, to run chess :
```
WINEARCH=win64 WINEPREFIX="~/win7-classic-games" "wine-11.6-amd64/bin/wine" "~/win7-classic-games/drive_c/Program Files/Microsoft Games/Chess/Chess_patched.exe
```

=== Parser ===
- `generate_reshacker_lines.py` generates the lines of the actions needed to embed the MUI file into the EXE file. It requires `pe_tools` installed (available as pip package)
It is not required to run the script.

=== Disclaimer ===

All the above software is copyrighted by its respective copyright holders. We do not own it, or sell or license it to you. Use it under your own responsibility. This software is distributed 'as-is', without any express or implied warranty.
