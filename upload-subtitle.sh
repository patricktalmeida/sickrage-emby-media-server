#!/bin/bash

##########################################################################################################
#  This script was developed to send a .srt file from your PC to your media server.                      #
#                                                                                                        #
#  In your server there will be a script that will search for an .srt subtitle on "/subtitles"           #
#  and copy it to it's destination folder.                                                               #
#                                                                                                        #
#  DO NOT FORGET to download the subtitle with the same name of the episode/movie                        #
#                                                                                                        #
#  RUN THIS SCRIPT ONLY IF HAVE PREVIOUSLY MANUALLY DOWNLOADED THE SUBTITLE                              #
#  NO NEED TO SPECIFY THE SUBTITLE NAME                                                                  #
##########################################################################################################

echo "Enter the instance IP that you want to send the subtitle: e.g 127.0.0.1 | CTRL + C to cancel"
read SERVER_IP 

echo "Enter your private SSH key name: e.g id_rsa.pem | CTRL + C to cancel"
read SSH_KEY_NAME

echo "Enter the complete path in your computer that your subtitle(s) is/are: e.g /home/user/downloads | CTRL + C to cancel"
read SUB_LOCATION

cd $SUB_LOCATION
scp -i ~/.ssh/$SSH_KEY_NAME $SUB_LOCATION/*.srt ubuntu@${SERVER_IP}:/subtitles