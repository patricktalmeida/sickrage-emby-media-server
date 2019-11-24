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
echo "/dev/xvdg       /mnt/sickrage-data     ntfs      defaults    0      0" >> /etc/fstab

# create emby server
mkdir /emby
mkdir /emby/media
docker pull emby/embyserver
docker run -d --name="emby" -e PUID=0 -e PGID=0 -v /emby:/config -v /mnt/sickrage-data:/series -p 8096:8096 emby/embyserver:latest  # patricktoledodea/emby for a stable image

# install plex media server
mkdir /plex
docker run \
-d \
--name plex \
-p 32400:32400/tcp \
-p 3005:3005/tcp \
-p 8324:8324/tcp \
-p 32469:32469/tcp \
-p 1900:1900/udp \
-p 32410:32410/udp \
-p 32412:32412/udp \
-p 32413:32413/udp \
-p 32414:32414/udp \
-e TZ="<timezone>" \
-e PLEX_CLAIM="claim-ouHZ2gYEKogdxRr3x3Ra" \
-e ADVERTISE_IP="http://tvmediaserver.com:32400/" \
-h mediaserver \
-v /plex:/config \
-v /plex:/transcode \
-v /mnt/sickrage-data:/data \
plexinc/pms-docker

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

#!/bin/bash

DOWNLOAD_PATH=/subtitles
DIR_PATH=/mnt/sickrage-data

set +x

findSubLocation() {
    SERIES_DIRECTORY=\$(find \$DIR_PATH -type d | rev | cut -d / -f1 | grep -o '..E..S.*' | rev)
    array=(`echo \$SERIES_DIRECTORY | sed 's/\s/\n/g'`)
    SUB_NAME=$(find \$DOWNLOAD_PATH -iname ".srt" | rev | cut -d / -f1 | grep -o '..E..S.*' | rev | head -n1)
}

moveSubtitle() {
    if [ -f "\$DOWNLOAD_PATH/\$SERIE.srt" ]
    then
        findSubLocation;
        for i in \${array[@]}
        do
            if [[ "\$i" = "\$SUB_NAME" ]]; then
                REAL_DIR=$(find \$DIR_PATH/\$i* -type d | cut -d / -f4 | head -n1)
	            mv \$DOWNLOAD_PATH/\$SERIE.srt \$DIR_PATH/\$REAL_DIR/\$SERIE.srt 2> /errorlog
            fi
        done
    fi
}

watchDownloadsDirectory() {
    while true; do
        SERIE=`find \$DOWNLOAD_PATH -name "*.srt" | rev | cut -f 2- -d '.' | rev | cut -d/ -f3 | head -n 1`
        if [[ \$SERIE != '' ]]; then
            moveSubtitle;
        fi
        sleep 2
    done
}

watchDownloadsDirectory;
moveSubtitle;" > watch_for_sub.sh
 
chmod +x watch_for_sub.sh
echo "bash /watch_for_sub.sh" >> ~/.profile
source ~/.profile