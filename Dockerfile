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

ENV WINEDEBUG=fixme-all


#RUN dpkg --add-architecture i386
#RUN apt update
#RUN apt install -y curl wine wine64 wine32 libwine fonts-wine

#RUN echo "https://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
#RUN apk --no-cache add wine

#ENV DISPLAY :0
ENV WINEPREFIX /config/wine/

# Disable WINE Debug messages
#ENV WINEDEBUG -all

EXPOSE 5900

COPY startapp.sh /startapp.sh

#CMD sh /start.sh
