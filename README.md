This Docker container runs the Backblaze personal backup client via WINE, so that you can back up your files with the separation and portability capabilities of Docker.

It runs the Backblaze client and starts a virtual X server with Openbox and a VNC server, so that you can interact with it.

## Installation:
````
docker run \
    -p 8080:5800 \
    --init \
    --name backblaze_personal_backup \
    -v "[backup folder]/:/drive_d/" \
    -v "[config folder]/:/config/" \
    tessypowder/backblaze-personal-wine
````

````
docker exec --user app backblaze_personal_backup ln -s /drive_d/ /config/wine/dosdevices/d:
````



Warning: The backblaze client is not an init system (who knew) and doesn't clean up its zombie children. This will cause it to fill up your system's PID limit within a few hours which prevents new processes from being created system-wide, would not recommend.  
The `--init` flag installs a tiny process that can actually do a few init things like wait()ing children in place of the backblaze client as PID 1.  
Info: Backblaze will create a `.bzvol` directory in the root of every hard drive it's configured to back up in which it'll store a full copy of files >100M split into 10M parts. Mount accordingly if you want to preserve SSD erase cycles.
