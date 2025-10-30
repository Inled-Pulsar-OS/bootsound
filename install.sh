#! /bin/bash

sudo cp /pearos-boot-sound/boot-sound.wav /boot/boot-sound.wav
sudo cp /pearos-boot-sound/bootsound.service /etc/systemd/system/

sudo systemctl enable bootsound.service
