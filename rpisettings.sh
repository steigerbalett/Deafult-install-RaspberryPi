#!/bin/sh

# Error out if anything fails.
#set -e

#License
clear
echo 'MIT License'
echo ''
echo 'Copyright (c) 2021 steigerbalett'
echo ''
echo 'Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:'
echo ''
echo 'The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.'
echo ''
echo 'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.'
echo ''
echo 'Installation will continue in 3 seconds...'
echo ''
echo -e "\033[1;31mVERSION: 2021-09-26\033[0m"
echo -e "\033[1;31mDeafult RaspberryPi settings\033[0m"
sleep 3

# Make sure script is run as root.
echo ''
echo 'Checking root status ...'
echo ''
if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;31mDas Script muss als root ausgeführt werden, sudo./install.sh\033[0m"
    echo -e '\033[36mMust be run as root with sudo! Try: sudo ./install.sh\033[0m'
  exit 1
fi

#Create 1-G Swap
# Checking Memory Requirements
echo ''
echo "Checking minimum system memory requirements ..."
echo ''
memtotal=$(cat /proc/meminfo | grep MemTotal | grep -o '[0-9]*')
swaptotal=$(cat /proc/meminfo | grep SwapTotal | grep -o '[0-9]*')
echo "Your total system memory is $memtotal"
echo "Your total system swap is $swaptotal"
totalmem=$(($memtotal + $swaptotal))
echo "Your effective total system memory is $totalmem"

if [[ $totalmem -lt 900000 ]]
  then
    echo 'You have low memory'
  else
    echo 'You have enough memory to meet the requirements! :-)'
fi
echo 'Creating 1 G swap file...'
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null

echo "Installing dependencies..."
echo "=========================="
echo ''
apt update
apt -y full-upgrade
apt -y install ntfs-3g hdparm hfsutils hfsprogs exfat-fuse ntpdate
echo "updating date and time"
sudo ntpdate -u de.pool.ntp.org 

# Einstellen der Zeitzone und Zeitsynchronisierung per Internet: Berlin
sudo timedatectl set-timezone Europe/Berlin
sudo timedatectl set-ntp true

# Konfigurieren der lokale Sprache: deutsch 
sudo sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen 
sudo locale-gen 
sudo localectl set-locale LANG=de_DE.UTF-8 LANGUAGE=de_DE

# SSH dauerhaft aktivieren für Fernzugriff
sudo systemctl enable ssh.service
sudo systemctl start ssh.service

echo "" >> /boot/config.txt
echo "# disable the splash screen" >> /boot/config.txt
echo "disable_splash=1" >> /boot/config.txt
echo "" >> /boot/config.txt
echo "# disable overscan" >> /boot/config.txt
echo "disable_overscan=1" >> /boot/config.txt

echo "Enable Hardware watchdog"
echo "========================"
echo ''
echo "" >> /boot/config.txt
echo "# activating the hardware watchdog" >> /boot/config.txt
echo "dtparam=watchdog=on" >> /boot/config.txt

echo "Disable search for SD after USB boot"
echo "========================"
echo "" >> /boot/config.txt
echo "# stopp searching for SD-Card after boot" >> /boot/config.txt
echo "dtoverlay=sdtweak,poll_once" >> /boot/config.txt

echo '########################################################'
echo '########################################################'
echo ''
echo ''
echo 'System will reboot in 3 seconds'
sleep 3
sudo shutdown -r now
echo ''
echo ''
echo ''
echo ''
exit
