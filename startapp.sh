#!/bin/sh
echo "whoami"
whoami
mkdir /config/wine/
cd /config/wine/
curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe"
ls -la
wine64 "install_backblaze.exe"
#wine64 "$WINEPREFIX"/drive_c/Program\ Files/Backblaze/bzbui.exe -noqiet