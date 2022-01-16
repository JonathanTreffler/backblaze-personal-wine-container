FROM jlesage/baseimage-gui:ubuntu-20.04

RUN apt-get update

RUN apt-get install -y curl wget software-properties-common gnupg2 winbind xvfb

RUN dpkg --add-architecture i386
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key
RUN apt-key add winehq.key
RUN add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main'
RUN apt-get update
RUN apt-get install -y winehq-stable

RUN apt-get install -y winetricks

RUN apt-get clean -y
RUN apt-get autoremove -y

#ENV DISPLAY :0

ENV WINEPREFIX /config/wine/

RUN \
    APP_ICON_URL=https://www.backblaze.com/pics/cloud-blaze.png && \
    install_app_icon.sh "$APP_ICON_URL"

ENV APP_NAME="Backblaze Personal Backup"

# Disable WINE Debug messages
ENV WINEDEBUG -all

EXPOSE 5900

COPY startapp.sh /startapp.sh