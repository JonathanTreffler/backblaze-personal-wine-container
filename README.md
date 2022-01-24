This Docker container runs the Backblaze personal backup client via WINE, so that you can back up your files with the separation and portability capabilities of Docker.

It runs the Backblaze client and starts a virtual X server with Openbox and a VNC server, so that you can interact with it.

## Installation:
````shell
docker run \
    -p 8080:5800 \
    --init \
    --name backblaze_personal_backup \
    -v "[backup folder]/:/drive_d/" \
    -v "[config folder]/:/config/" \
    tessypowder/backblaze-personal-wine
````

1. Open the Web Interface (on the port you specified in the docker run command, in this example 8080):

    ![Step 1](https://user-images.githubusercontent.com/28999431/149661532-b4fac1b2-eb40-4e5a-b466-b2551372d6f4.png)

    ![Bildschirmfoto von 2022-01-16 02-46-05](https://user-images.githubusercontent.com/28999431/149661717-f066a8b6-4add-41af-bd2d-1a20c481aa07.png)

1. Click "Install" to install Mono

      ![Bildschirmfoto von 2022-01-16 14-17-55](https://user-images.githubusercontent.com/28999431/149661561-6a14cf08-9d76-415e-bb51-e1b62bf0b796.png)

1. Wait for the Download to finish

      ![Bildschirmfoto von 2022-01-16 14-19-08](https://user-images.githubusercontent.com/28999431/149661613-272402f9-7a5e-44a2-940b-7a5314cb3924.png)

1. Click "Install" to install Wine Gecko

      ![Bildschirmfoto von 2022-01-16 14-21-08](https://user-images.githubusercontent.com/28999431/149661702-9e5e27dd-8219-4462-b04b-53c13e9d49f1.png)

1. Wait for the Download to finish

      ![Bildschirmfoto von 2022-01-16 14-36-25](https://user-images.githubusercontent.com/28999431/149662398-2964b467-e362-4b60-a6ad-8f2a025c8c97.png)

1. Click "Install" to install Wine Gecko (second dialog for Gecko)

1. Wait for the Download to finish

1. Add your storage path as a wine drive, so Backblaze can access it

    ````shell
    docker exec --user app backblaze_personal_backup ln -s /drive_d/ /config/wine/dosdevices/d:
    ````

1. Restart the docker to get Backblaze to recognize the new drive

    ````shell
    docker restart backblaze_personal_backup
    ````

1. Reload the Web Interface

    ![Bildschirmfoto von 2022-01-16 14-49-45](https://user-images.githubusercontent.com/28999431/149662817-27f3c9e8-12ba-494c-898d-d9492541a5fb.png)

1. The UI of the first step of the Backblaze installer is broken on wine, but it doesn't matter, just insert the email to your backblaze account into the input field

    ![Bildschirmfoto von 2022-01-16 14-51-16](https://user-images.githubusercontent.com/28999431/149662881-b8527b31-e837-4982-91db-b0a3df6cc379.png)

1. Press Enter

    ![Bildschirmfoto von 2022-01-16 14-52-27](https://user-images.githubusercontent.com/28999431/149662922-b637e0e5-7932-4e5e-bf14-1e7a6678311c.png)

1. Insert your password (important: keyboard locale mismatches can mess up your inputs)

    - Tip: You can use the clipboard function of the web interface, but some passwords will still not get transferred correctly, i would reccommend setting your backblaze password to a long string without special characters

    ![Bildschirmfoto von 2022-01-16 14-57-31](https://user-images.githubusercontent.com/28999431/149663068-80b17726-860a-4614-abc3-e1dba7b1674e.png)

1. Press Enter

    ![Bildschirmfoto von 2022-01-16 15-00-44](https://user-images.githubusercontent.com/28999431/149663220-625a74f7-f59c-40a4-83fc-992d039896b8.png)

1. Wait for Backblaze to analyze your drives

    ![Bildschirmfoto von 2022-01-16 15-00-49](https://user-images.githubusercontent.com/28999431/149663225-dc2f7209-2c57-4c3a-8f87-50750957cd69.png)

1. Click Ok

    ![Bildschirmfoto von 2022-01-16 15-01-00](https://user-images.githubusercontent.com/28999431/149663289-d53c7241-5856-4032-af41-66a3fa513b36.png)

1. The Installation is done 🎉

1. Buy a license for your Computer/Server in the Backblaze Dashboard, just like for a normal Windows/Mac installation

## Troubleshooting

- The Backblaze Installer says it recognized a server operating system

  ![Bildschirmfoto von 2022-01-16 14-41-04](https://user-images.githubusercontent.com/28999431/149662713-b7b27862-59b6-432a-a3c3-327f939a7292.png)

  - Explanation: I don't know what can cause this, it seems to randomly occur on some installations

  - Solution: Stop the docker, delete the config directory, restart installation from beginning

  - (Speculation: I think this only happens, when no volume is mounted at /config/ and docker manages the folder instead of the volume)

- The backup folder mounted as drive D is not being backed up

  - Explanation: Depending on when you added drive D to your wine configuration, the Backblaze installer might not recognize it

  - Solution:
    - Open the Backblaze settings
    - In the section "Hard Drives" in the first tab "Settings" enable the checkbox for next to the drive D:\ 

  - Still not working:
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

     - If it doesn't look like above try step 8 - 9 again

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
5. The window size of Backblaze Personal Backup seems to be hardcoded, so it looks nicer (less black bars on the sides) when you set the size of the virtual VNC screen to the same size. The widest dialog the client opens is the recovery dialog with 657px and the tallest dialog are the settings with 453px. In order to fit the windows decorations i would suggest a screen size of 657x473. This can be set using environment variables when creating the docker:
    ````shell
    docker run ... -e "DISPLAY_WIDTH=657" -e "DISPLAY_HEIGHT=473" ...
    ````

# Credits
This was originally developed by @Atemu (https://github.com/Atemu/backblaze-personal-wine-container)

The Backblaze logo and application is the property of Backblaze, Inc.
