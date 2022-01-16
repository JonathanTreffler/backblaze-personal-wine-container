#!/bin/sh
set -x
if [ -f "/config/wine/drive_c/Program Files (x86)/Backblaze/bzbui.exe" ]
then
    wine64 "/config/wine/drive_c/Program Files (x86)/Backblaze/bzbui.exe" -noqiet &
    sleep infinity
else
    mkdir /config/wine/
    cd /config/wine/
    curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe"
    ls -la
    wine64 "install_backblaze.exe" &
    #sleep 10
    #ln -s /drive_d/ /config/wine/dosdevices/d:
    sleep infinity
fi