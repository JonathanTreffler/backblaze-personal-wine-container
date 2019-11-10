FROM i386/alpine

RUN apk --update --no-cache add xvfb x11vnc wine openbox

ENV DISPLAY :0
ENV WINEPREFIX /root/wine/

EXPOSE 5900

CMD Xvfb :0 -screen 0 1024x768x24 & \
    openbox & \
    while true ; do x11vnc -forever ; done &\
    wine /root/wine/drive_c/Program\ Files/Backblaze/bzbui.exe -noqiet
