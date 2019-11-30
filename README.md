This Docker container runs the Backblaze personal backup client via WINE, so that you can back up your files with the separation and portability capabilities of Docker.

It runs the Backblaze client and starts a virtual X server with Openbox and a VNC server, so that you can interact with it.
You need to open up port 5900 for VNC and mount a WINE prefix with pre-installed Backblaze client at `/wine/` for this to work.  
You can install it using this container too (if you can somehow get your BZ credetials to go through the VNC properly that is), just mount the installer somewhere, mount your persistent storage at `/wine/`, override the container's CMD with `winefile`, connect via VNC, run the installer exe and click through the menus.

Example `docker run`:

    docker run \
    --rm \
    --init \
    -p '5900:5900' \
    -v 'backblaze:/wine/' \
    -v '/dir/you/want/to/back/up/:/wine/drive_d/' \
    atemu12/backblaze-personal-wine

I have my WINE prefix set up in a way that `dosdrives/d:` is a symlink to `drive_d` and told backblaze to back up "D:\\" and ignore everything on "C:\\".

Warning: The backblaze client is not an init system (who knew) and doesn't clean up its zombie children. This will cause it to fill up your system's PID limit within a few hours which prevents new processes from being created system-wide, would not recommend.  
The `--init` flag installs a tiny process that can actually do a few init things like wait()ing children in place of the backblaze client as PID 1.  
Info: Backblaze will create a `.bzvol` directory in the root of every hard drive it's configured to back up in which it'll store a full copy of files >100M split into 10M parts. Mount accordingly if you want to preserve SSD erase cycles.
