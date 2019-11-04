#!/bin/bash

#update host
sudo su
apt-get update
apt-get upgrade -y

# install docker
apt update
echo y | apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update
apt install docker-ce -y

#format data disk
mkdir /mnt/sickrage-data
mkfs.ext4 /dev/xvdg
mount /dev/xvdg /mnt/sickrage-data
chown -R root:root /mnt/sickrage-data/
chmod 777 /mnt/sickrage-data

# create emby server
mkdir /emby
mkdir /emby/media
docker pull emby/embyserver
docker run -d --name="emby" -e PUID=0 -e PGID=0 -v /emby:/config -v /mnt/sickrage-data:/series -p 8096:8096 emby/embyserver:latest  # patricktoledodea/emby for a stable image

# install plex media server
curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
echo deb https://downloads.plex.tv/repo/deb public main | sudo tee -a /etc/apt/sources.list.d/plexmediaserver.list
apt update
apt install plexmediaserver

# Transmission web “serverip:9091”
add-apt-repository ppa:transmissionbt/ppa -y
apt-get update
apt-get install transmission-cli transmission-common transmission-daemon -y
service transmission-daemon stop
echo "TRANSMISSION_SETTINGS_PATH=/var/lib/transmission-daemon/info/settings.json" >> ~/.profile
echo "PASSWD=${transmission_passwd}" >> ~/.profile
source ~/.profile

# create couchpotato docker
docker run -d \
  --name=couchpotato \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/London \
  -e UMASK_SET=022 \
  -p 5050:5050 \
  -v /couchpotato:/config \
  -v /couchpotato:/downloads \
  -v /couchpotato:/movies \
  -v /transmission:/torrents \
  --restart unless-stopped \
  linuxserver/couchpotato

# remember to configure sickrage to blackhole .torrent into /downloads (/transmission)
sed -i 's/"umask": 18,/"umask": 2,/g' $TRANSMISSION_SETTINGS_PATH
VALUE=`grep "rpc-password" /var/lib/transmission-daemon/info/settings.json | cut -d: -f2 | rev | cut -d, -f2 | rev`
sed -i "s|$VALUE|\"$PASSWD\"|g" $TRANSMISSION_SETTINGS_PATH
sed -i 's/"rpc-whitelist": "127.0.0.1"/"rpc-whitelist": "*.*.*.*"/g' $TRANSMISSION_SETTINGS_PATH
sed -i 's@"download-dir": "/var/lib/transmission-daemon/downloads"@"download-dir": "/mnt/sickrage-data"@g' $TRANSMISSION_SETTINGS_PATH
sed -i 's@"rpc-whitelist-enabled": true@"rpc-whitelist-enabled": false@g' $TRANSMISSION_SETTINGS_PATH
sed -i 's/"utp-enabled": true/"utp-enabled": true,/g' $TRANSMISSION_SETTINGS_PATH
sed -i 's@}@    "watch-dir": "/transmission",\n    "watch-dir-enabled": true,\n}@g' $TRANSMISSION_SETTINGS_PATH
sed -i 's@}@    "ratio-limit": 0,\n    "ratio-limit-enabled": true\n}@g' $TRANSMISSION_SETTINGS_PATH

service transmission-daemon start

# create sickrage docker
mkdir /sickrage
mkdir /media
docker pull sickrage/sickrage
docker run -d --name="sickrage" -v /sickrage:/config -e PUID=0 -e PGID=0 -v /transmission:/downloads -v /mnt/sickrage-data:/tv -v /sickrage:/config -e TZ=Canada/Pacific -p 8081:8081 sickrage/sickrage:latest  # patricktoledodea/sickrage is a stable image

# cron to delete .torrent files
echo "#!/bin/bash
rm /transmission/*.torrent" > /etc/cron.daily/remove-magnet.sh
chmod +x remove-magnet.sh

# removing sensitive data from server
sed -i '$ d' ~/.profile
source ~/.profile

#creating and starting subtitle watch directory script
mkdir /subtitles
chmod 777 /subtitles
echo "#!/bin/bash

##########################################################################################################
#  This script is supposed to be put as a daemon or executed on launch and the while will do the rest    #
#                                                                                                        #
#  It will search for an .srt subtitle on \$DOWNLOAD_PATH and copy it to it's right folder to stay beside#
#  the epsode that toy downloaded.                                                                       #
#                                                                                                        #
#  DO NOT FORGET to download the subtitle with the same name of the episode/movie before the extension   #
#                                                                                                        #
#  If used as dameon edit to remove the   while                                                          #
#                                                                                                        #
##########################################################################################################

DOWNLOAD_PATH=/subtitles

set +x

moveSubtitle() {
    if [ -f "\$DOWNLOAD_PATH/\$SERIE.srt" ]
    then
        if [[ -d "/mnt/sickrage-data/emby/\$SERIE" ]]; then
            mv \$DOWNLOAD_PATH/\$SERIE.srt /mnt/sickrage-data/\$SERIE/\$SERIE.srt
       else
            rm \$DOWNLOAD_PATH/\$SERIE.srt
       fi

    fi
}

watchDownloadsDirectory() {
    while true; do
        SERIE=\`find \$DOWNLOAD_PATH -name "*.srt" | rev | cut -f 2- -d '.' | rev | cut -d/ -f3 | head -n 1\`
        moveSubtitle
        sleep 5
    done
}

watchDownloadsDirectory;
moveSubtitle;" > watch_for_sub.sh
 
chmod +x watch_for_sub.sh
echo "bash /watch_for_sub.sh" >> ~/.profile
source ~/.profile