[![Github License](https://img.shields.io/github/license/JonathanTreffler/backblaze-personal-wine-container?style=flat-square)](https://github.com/JonathanTreffler/backblaze-personal-wine-container/blob/main/LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/tessypowder/backblaze-personal-wine?style=flat-square)](https://hub.docker.com/r/tessypowder/backblaze-personal-wine)
[![Docker Image Size](https://img.shields.io/docker/image-size/tessypowder/backblaze-personal-wine/latest?style=flat-square)](https://hub.docker.com/r/tessypowder/backblaze-personal-wine/tags)
![Maintenance](https://img.shields.io/maintenance/yes/2024?style=flat-square)
[![GitHub last commit](https://img.shields.io/github/last-commit/JonathanTreffler/backblaze-personal-wine-container?style=flat-square)](https://github.com/JonathanTreffler/backblaze-personal-wine-container/commits/main/)
[![GitHub contributors](https://img.shields.io/github/contributors/JonathanTreffler/backblaze-personal-wine-container?style=flat-square)](https://github.com/JonathanTreffler/backblaze-personal-wine-container/graphs/contributors)
[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://stand-with-ukraine.pp.ua)

# Backblaze Personal Wine Community Container

This Docker container runs the Backblaze personal backup client via [WINE](https://www.winehq.org), so that you can back up your files with the separation and portability capabilities of Docker on Linux.

It runs the Backblaze client and starts a virtual X server and a VNC server with Web GUI, so that you can interact with it.

⚠️ This project is not affiliated with Backblaze Inc. ⚠️

## Table of Content

   * **[Backblaze Personal Wine Container](#backblaze-personal-wine-container)**
      * [Table of Content](#table-of-content)
      * [Project Status](#project-status)
      * [Docker Images](#docker-images)
         * [Content](#content)
         * [Tags](#tags)
         * [Platforms](#platforms)
      * [Environment Variables](#environment-variables)
      * [Config Directory](#config-directory)
      * [Ports](#ports)
      * [Volumes](#volumes)
      * [Accessing the GUI](#accessing-the-gui)
      * [Security](#security)
         * [SSVNC](#ssvnc)
         * [Certificates](#certificates)
         * [VNC Password](#vnc-password)
         * [DH Parameters](#dh-parameters)
      * **[Installation](#installation)**
      * [Additional Information](#additional-information)
      * [Credits](#credits)

## Project Status

This docker should just work for most people. But if you for example have a complex permissions setup in the filesystem you are trying to back up you will need good knowledge of docker to get it set up.

Still please be attentive during the install process: The docker by design has read/write access to all the data you are trying to back up and if you make a grave mistake you could delete stuff.

## Docker Images
### Content
Here are the main components of this image:
  * [S6-overlay], a process supervisor for containers.
  * [x11vnc], a X11 VNC server.
  * [xvfb], a X virtual framebuffer display server.
  * [openbox], a windows manager.
  * [noVNC], a HTML5 VNC client.
  * [NGINX], a high-performance HTTP server.
  * [stunnel], a proxy encrypting arbitrary TCP connections with SSL/TLS.
  * [WINE], a compatibility layer for windows applications on Linux
  * [Winetricks] is a helper script to download and install various redistributable runtime libraries needed to run some programs in Wine
  * [Backblaze Personal Backup]

[S6-overlay]: https://github.com/just-containers/s6-overlay
[x11vnc]: http://www.karlrunge.com/x11vnc/
[xvfb]: http://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml
[openbox]: http://openbox.org
[noVNC]: https://github.com/novnc/noVNC
[NGINX]: https://www.nginx.com
[stunnel]: https://www.stunnel.org
[WINE]: https://www.winehq.org/
[Winetricks]: https://wiki.winehq.org/Winetricks
[Backblaze Personal Backup]: https://www.backblaze.com/cloud-backup.html

### Tags

| Tag | Description |
|-----|-------------|
| latest | Latest stable version of the image based on ubuntu 22 |
| ubuntu22 | Latest stable version of the image based on ubuntu 22 |
| ubuntu20 | Latest stable version of the image based on ubuntu 20 |
| ubuntu18 | Latest stable version of the image based on ubuntu 18 **(End of Life - unmaintained)** |
| v1.x | Versioned stable releases based on ubuntu 22 |
| main | Automatic build of the main branch (may be unstable) based on ubuntu 22 |

There are no versioned ubuntu20 or ubuntu18 builds.

### Platforms

| Platform | Support |
|-----|-------------|
| linux/amd64 | Fully supported |
| linux/arm64 | Currently no support (maybe in the future) |
| linux/arm/v7 | No support |
| linux/arm/v6 | No support |
| linux/riscv64 | Currently no support (maybe in the future) |
| linux/s390x | No support |
| linux/ppc64le | No support |
| linux/386 | No support |

As Backblaze runs on Windows and MacOS, there is no point in supporting these platforms.

## Environment Variables

Environment variables can be set by adding one or more arguments `-e "<VAR>=<VALUE>"` to the `docker run` command.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`DISABLE_VIRTUAL_DESKTOP` | Disables Wine's Virtual Desktop Mode | false |
|`DISABLE_AUTOUPDATE` | Disables the auto-update of the backblaze client to the latest known-good version at the time of the docker version release | true |
|`FORCE_LATEST_UPDATE`| Forces the auto updater to download the newest version of the backblaze client from the backblaze servers instead of a known-good version from the Internet Archive | true |
|`UMASK`| Mask that controls how file permissions are set for newly created files. The value of the mask is in octal notation.  By default, this variable is not set and the default umask of `022` is used, meaning that newly created files are readable by everyone, but only writable by the owner. See the following online umask calculator: http://wintelguy.com/umask-calc.pl | (unset) |
|`TZ`| [TimeZone] of the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`APP_NICENESS`| Priority at which the application should run.  A niceness value of -20 is the highest priority and 19 is the lowest priority.  By default, niceness is not set, meaning that the default niceness of 0 is used.  **NOTE**: A negative niceness (priority increase) requires additional permissions.  In this case, the container should be run with the docker option `--cap-add=SYS_NICE`. | (unset) |
|`USER_ID`| When mounting docker-volumes, permission issues can arise between the docker host and the container. You can pass the User_ID permissions to the container with this variable. | `1000` |
|`GROUP_ID`| When mounting docker-volumes, permission issues can arise between the docker host and the container. You can pass the Group_ID permissions to the container with this variable. | `1000` |
|`CLEAN_TMP_DIR`| When set to `1`, all files in the `/tmp` directory are deleted during the container startup. | `1` |
|`DISPLAY_WIDTH`| Width (in pixels) of the virtual screen's window. (Has to be divisible by 4) | `900` |
|`DISPLAY_HEIGHT`| Height (in pixels) of the virtual screen's window. (Has to be divisible by 4) | `700` |
|`SECURE_CONNECTION`| When set to `1`, an encrypted connection is used to access the application's GUI (either via a web browser or VNC client).  See the [Security](#security) section for more details. | `0` |
|`VNC_PASSWORD`| Password needed to connect to the application's GUI.  See the [VNC Password](#vnc-password) section for more details. | (unset) |
|`X11VNC_EXTRA_OPTS`| Extra options to pass to the x11vnc server running in the Docker container.  **WARNING**: For advanced users. Do not use unless you know what you are doing. | (unset) |
|`ENABLE_CJK_FONT`| When set to `1`, open-source computer font `WenQuanYi Zen Hei` is installed.  This font contains a large range of Chinese/Japanese/Korean characters. | `0` |
|`STARTUP_LOGFILE`| The location for writing logs of the startup script, responsible for installing and starting the Backblaze app.  The default path is also backed up to Backblaze. | `/config/wine/dosdevices/c:/backblaze-wine-startapp.log` |

## Config Directory
Inside the container, wine's configuration and with it Backblaze's configuration is stored in the
`/config/wine/` directory.

This directory is also used to store the VNC password.  See the
[VNC Pasword](#vnc-password) section for more details.

## Ports

Here is the list of ports used by container.  They can be mapped to the host
via the `-p <HOST_PORT>:<CONTAINER_PORT>` parameter.  The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port | Mapping to host | Description |
|------|-----------------|-------------|
| 5800 | Mandatory | Port used to access the application's GUI via the web interface. |
| 5900 | Optional | Port used to access the application's GUI via the VNC protocol.  Optional if no VNC client is used. |

## Volumes

A minimum of 2 volumes need to be mounted to the container

  * /config - This is where Wine and Backblaze will be installed
  * Backup drives - these are the locations you wish to backup, any volume that is mounted as /drive_**driveletter** (from d up to z) will be mounted automatically for use in Backblaze with their equivalent letter, for example /drive_d will be mounted as D:

You can mount drives with different paths, but these will need to be mounted manually within wine using the following method

1. Add your storage path as a wine drive, so Backblaze can access it

    ````shell
    docker exec --user app backblaze_personal_backup ln -s /backup_volume/ /config/wine/dosdevices/d:
    ````

1. Restart the docker to get Backblaze to recognize the new drive

    ````shell
    docker restart backblaze_personal_backup
    ````

1. Reload the Web Interface

    ![Bildschirmfoto von 2022-01-16 14-49-45](https://user-images.githubusercontent.com/28999431/149662817-27f3c9e8-12ba-494c-898d-d9492541a5fb.png)

## Accessing the GUI

Assuming that container's ports are mapped to the same host's ports, the
graphical interface of the application can be accessed via:

  * A web browser:
```
http://<HOST IP ADDR>:5800
```

  * Any VNC client:
```
<HOST IP ADDR>:5900
```

## Security

By default, access to the application's GUI is done over an unencrypted
connection (HTTP or VNC).

Secure connection can be enabled via the `SECURE_CONNECTION` environment
variable.  See the [Environment Variables](#environment-variables) section for
more details on how to set an environment variable.

When enabled, application's GUI is performed over an HTTPs connection when
accessed with a browser.  All HTTP accesses are automatically redirected to
HTTPs.

When using a VNC client, the VNC connection is performed over SSL.  Note that
few VNC clients support this method.  [SSVNC] is one of them.

### SSVNC

[SSVNC] is a VNC viewer that adds encryption security to VNC connections.

While the Linux version of [SSVNC] works well, the Windows version has some
issues.  At the time of writing, the latest version `1.0.30` is not functional,
as a connection fails with the following error:
```
ReadExact: Socket error while reading
```
However, for your convienence, an unoffical and working version is provided
here:

https://github.com/jlesage/docker-baseimage-gui/raw/master/tools/ssvnc_windows_only-1.0.30-r1.zip

The only difference with the offical package is that the bundled version of
`stunnel` has been upgraded to version `5.49`, which fixes the connection
problems.

### Certificates

Here are the certificate files needed by the container.  By default, when they
are missing, self-signed certificates are generated and used.  All files have
PEM encoded, x509 certificates.

| Container Path                  | Purpose                    | Content |
|---------------------------------|----------------------------|---------|
|`/config/certs/vnc-server.pem`   |VNC connection encryption.  |VNC server's private key and certificate, bundled with any root and intermediate certificates.|
|`/config/certs/web-privkey.pem`  |HTTPs connection encryption.|Web server's private key.|
|`/config/certs/web-fullchain.pem`|HTTPs connection encryption.|Web server's certificate, bundled with any root and intermediate certificates.|

**NOTE**: To prevent any certificate validity warnings/errors from the browser
or VNC client, make sure to supply your own valid certificates.

**NOTE**: Certificate files are monitored and relevant daemons are automatically
restarted when changes are detected.

### VNC Password

To restrict access to your application, a password can be specified.  This can
be done via two methods:
  * By using the `VNC_PASSWORD` environment variable.
  * By creating a `.vncpass_clear` file at the root of the `/config` volume.
    This file should contains the password in clear-text.  During the container
    startup, content of the file is obfuscated and moved to `.vncpass`.

The level of security provided by the VNC password depends on two things:
  * The type of communication channel (encrypted/unencrypted).
  * How secure access to the host is.

When using a VNC password, it is highly desirable to enable the secure
connection to prevent sending the password in clear over an unencrypted channel.

Access to the host by unexpected users with sufficient privileges can be
dangerous as they can retrieve the password with the following methods:
  * By looking at the `VNC_PASSWORD` environment variable value via the
    `docker inspect` command.  By defaut, the `docker` command can be run only
    by the root user.  However, it is possible to configure the system to allow
    the `docker` command to be run by any users part of a specific group.
  * By decrypting the `/config/.vncpass` file.  This requires the user to have
    the appropriate permission to read the file:  it has to be root or be the
    user defined by the `USER_ID` environment variable.  Also, to be able to
    retrieve the correct decryption key, one needs to know that the content of
    the file was generated by `x11vnc`.

### DH Parameters

Diffie-Hellman (DH) parameters define how the [DH key-exchange] is performed.
More details about this algorithm can be found on the [OpenSSL Wiki].

DH Parameters are saved into the PEM encoded file located inside the container
at `/config/certs/dhparam.pem`.  By default, when this file is missing, 2048
bits DH parameters are automatically generated.  Note that this one-time
operation takes some time to perform and increases the startup time of the
container.

[SSVNC]: http://www.karlrunge.com/x11vnc/ssvnc.html
[DH key-exchange]: https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange
[OpenSSL Wiki]: https://wiki.openssl.org/index.php/Diffie_Hellman

## Installation:
1. Check for yourself if using this docker complies with the Backblaze [terms of service](https://www.backblaze.com/company/terms.html)
1. Modify the following for your setup (in terms of [ports](#ports), [volumes](#volumes) and [environment variables](#environment-variables)) and run it
   
    **(for Unraid users, instead of running this command navigate to the Apps tab, search for this docker and install it)**
   
    **NOTE**: root priviliges may be needed
    ````shell
    docker run \
        -p 8080:5800 \
        --init \
        --name backblaze_personal_backup \
        -v "[backup folder]/:/drive_d/" \
        -v "[config folder]/:/config/" \
        tessypowder/backblaze-personal-wine:latest
    ````

1. Open the Web Interface (on the port you specified in the docker run command, in this example 8080):
2. You may see wine being updated, this will take a couple of minutes
   
   ![image](https://github.com/xela1/backblaze-personal-wine-container/assets/357319/4f401b31-8d1d-40fe-85a3-ec4637c23bf5)

1. The UI of the first step of the Backblaze installer is broken on wine, but it doesn't matter, just insert the email to your backblaze account into the input field

    ![Bildschirmfoto von 2022-01-16 14-51-16](https://user-images.githubusercontent.com/28999431/149662881-b8527b31-e837-4982-91db-b0a3df6cc379.png)

1. Press Enter

    ![Bildschirmfoto von 2022-01-16 14-52-27](https://user-images.githubusercontent.com/28999431/149662922-b637e0e5-7932-4e5e-bf14-1e7a6678311c.png)

1. Insert your password (important: keyboard locale mismatches can mess up your inputs)

    - **TIP**: You can use the clipboard function of the web interface, but some passwords will still not get transferred correctly, i would reccommend setting your backblaze password to a long string without special characters

    ![Bildschirmfoto von 2022-01-16 14-57-31](https://user-images.githubusercontent.com/28999431/149663068-80b17726-860a-4614-abc3-e1dba7b1674e.png)

1. Press Enter

    ![Bildschirmfoto von 2022-01-16 15-00-44](https://user-images.githubusercontent.com/28999431/149663220-625a74f7-f59c-40a4-83fc-992d039896b8.png)

1. Wait for Backblaze to analyze your drives

    ![Bildschirmfoto von 2022-01-16 15-00-49](https://user-images.githubusercontent.com/28999431/149663225-dc2f7209-2c57-4c3a-8f87-50750957cd69.png)

1. Click Ok

    ![Bildschirmfoto von 2022-01-16 15-01-00](https://user-images.githubusercontent.com/28999431/149663289-d53c7241-5856-4032-af41-66a3fa513b36.png)

1. If your [config folder] is somewehere inside the [backup folder] on the docker host side (which is the case for the Unraid template) in order to prevent an infinite loop of config file uploads, because those uploads change bz_done* files in [config folder]/wine/drive_c/ProgramData/Backblaze/bzdata/bzbackup/bzdatacenter open the web interface, open the Backblaze settings, open the "Exclusions" tab, click on "Add Folder" and in the popup navigate to My Computer -> (D:) and naviagate to the config folder inside. For unraid template installs this is My Computer -> (D:) -> appdata -> backblaze_personal_backup. Click on OK and close the Backblaze Settings.

1. The Installation is done 🎉

1. Buy a license for your Computer in the Backblaze Dashboard, just like for a normal Windows/Mac installation

## Troubleshooting

- The Backblaze Installer says it recognized a server operating system

  ![Bildschirmfoto von 2022-01-16 14-41-04](https://user-images.githubusercontent.com/28999431/149662713-b7b27862-59b6-432a-a3c3-327f939a7292.png)

  - **Explanation**: I don't know what can cause this, it seems to randomly occur on some installations

  - **Solution**: Stop the docker, delete the config directory, restart installation from beginning

  - (**Speculation**: I think this only happens, when no volume is mounted at /config/ and docker manages the folder instead of the volume)

- The backup folder mounted as drive D is not being backed up

  - **Explanation**: Depending on when you added drive D to your wine configuration, the Backblaze installer might not recognize it

  - **Solution**:
    - Open the Backblaze settings
    - In the section "Hard Drives" in the first tab "Settings" enable the checkbox for next to the drive D:\ 

  - **Still not working**:
    - Run
      ````shell
      docker exec --user app backblaze_personal_backup ls -la /config/wine/dosdevices/
      ````

    - The output should look like this:
      ````
        drwxr-xr-x 2 app app 4096 Jan 16 13:43 .
        drwxr-xr-x 4 app app 4096 Jan 16 14:08 ..
        lrwxrwxrwx 1 app app   10 Jan 16 13:43 c: -> ../drive_c
        lrwxrwxrwx 1 app app   10 Jan 16 13:43 d: -> /drive_d/
        lrwxrwxrwx 1 app app    1 Jan 16 13:43 z: -> /
      ````

     - If it doesn't confirm you've mounted the volume in the container correctly for automatic attachment or followed the manual instructions in [volumes](#volumes)
	 
- I can only see a black screen when I start the container

  - **Explanation**: The Docker container may have insufficient permissions to download and install Backblaze.

  - **Solution**:
    - Try a different run command where you explicitly pass the root ID 0 to the container:

    ````shell
    docker run \
        -p 8080:5800 \
        --init \
        -e USER_ID=0 \
        -e GROUP_ID=0 \
        --name backblaze_personal_backup \
        -v "[backup folder]/:/drive_d/" \
        -v "[config folder]/:/config/" \
        tessypowder/backblaze-personal-wine:latest
    ````

  - **Additional 'black screen' troubleshooting for Synology devices**:
    - It may be necessary to run the container with even higher permissions (--privileged)

    ````shell
    docker run \
        -p 8080:5800 \
        --init \
        --privileged \
        -e USER_ID=0 \
        -e GROUP_ID=0 \
        --name backblaze_personal_backup \
        -v "[backup folder]/:/drive_d/" \
        -v "[config folder]/:/config/" \
        tessypowder/backblaze-personal-wine:latest
    ````

  - **For More Information**: See [#98](https://github.com/JonathanTreffler/backblaze-personal-wine-container/issues/98), [#99](https://github.com/JonathanTreffler/backblaze-personal-wine-container/issues/99)
  
## Additional Information

1. Warning: The Backblaze client is not an init system (who knew) and doesn't clean up its zombie children. This will cause it to fill up your system's PID limit within a few hours which prevents new processes from being created system-wide, would not recommend.  
The `--init` flag installs a tiny process that can actually do a few init things like wait()ing children in place of the backblaze client as PID 1.  
2. Backblaze will create a `.bzvol` directory in the root of every hard drive it's configured to back up in which it'll store a full copy of files >100M split into 10M parts. Mount accordingly if you want to preserve SSD erase cycles.
3. You can browse the files accessible to Backblaze using:
    ````shell
    docker exec --user app backblaze_personal_backup wine explorer
    ````
4. You can open the Wine Config using:
    ````shell
    docker exec --user app backblaze_personal_backup winecfg
    ````
5. We are using Wine's virtual desktop mode as default and are using a default screen resoluzion of 900x700 pixels. It's larger than the Backblaze UI window itself to make room for the Backblaze restore app. You can always modify the resolution as you like with DISPLAY_WIDTH and DISPLAY_HEIGHT:
    ````shell
    docker run ... -e "DISPLAY_WIDTH=1280" -e "DISPLAY_HEIGHT=800" ...
    ````

# Credits
This was originally developed by @Atemu (https://github.com/Atemu/backblaze-personal-wine-container).

The Backblaze name, logo and application is the property of Backblaze, Inc.

This docker does not redistribute the Backblaze application. It gets downloaded from the official Backblaze Servers or Internet Archive during the install process.

This docker image is based on @jlesage 's excellent [base image](https://github.com/jlesage/docker-baseimage-gui).

## Contributors:
This project was made by:

<a href="https://github.com/JonathanTreffler/backblaze-personal-wine-container/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=JonathanTreffler/backblaze-personal-wine-container" />
</a>
