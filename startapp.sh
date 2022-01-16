#!/bin/sh
set -x
whoami
mkdir /config/wine/
#mkdir -p /config/wine/dosdevices/
cd /config/wine/
wineboot --init
curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe"
ls -la
wine64 "install_backblaze.exe" &
#sleep 10
#ln -s /drive_d/ /config/wine/dosdevices/d:
sleep infinity
#wine64 "$WINEPREFIX"/drive_c/Program\ Files/Backblaze/bzbui.exe -noqiet