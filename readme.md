# TeslaCam
Tesla's Version 9 [2018.39.x] introducted a feature allowing users to store 1 rolling hour (60, one minute files) of video from the front facing autopilot camera. This project attempts to extend (and ultimately archive) the video storage beyond 1 hour.

# Hardware Requirements
* Raspberry Pi Zero W
* PiJuice HAT
* USB A to Micro B cable

# How it works

The ```teslacam``` service creates and makes available a 2GB USB Mass Storage device with the required "TeslaCam" directory. The Tesla sees, mounts and writes video files from the front camera to the USB Mass Stroage device. 

Every 10 minutes the ```teslacam``` service mounts (read only) the 2GB Mass Storage device and rsyncs the files to ```/data/TeslaCam```

When the ```powermonitor``` service sees that the the Tesla has cut power to the Raspberry Pi it sets the PiJuice to start the Raspberry Pi when power is restored and instructs the Raspberry Pi to shut down. 

When the ```teslacam``` service recives a ```SIGTERM``` it takes the 2GB USB Mass Storage device offline, mounts it, and complets a final rsync to ```/data/TeslaCam```

If ```/home/pi/remotesync.sh``` exists and is excutable it is executed...

Once the ```teslacam``` service is complete the Raspberry Pi shuts down. 

# Installation

Add/Solder 40 pins to the GPIO header of the Raspberry Pi Zero W.

Attach the PiJuice HAT to the Raspberry Pi Zero W, be sure to include the ```run pin``` (pogo pin) connecting TP2 on the Raspberry Pi. https://github.com/PiSupply/PiJuice/blob/master/Hardware/README.md#unpopulated

Write the rasbian image to a sufficiently large SD card. (I would suggest 16GB at minimum)

```dd if=2018-10-09-raspbian-stretch-lite.img of=/dev/sdX bs=1MB```

Mount the 'boot' partition.. 

Edit ```config.txt``` in the boot partition and add the following line to the bottom

```dtoverlay=dwc2```

Edit ```cmdline.txt``` in the boot partition and add the following after ```rootwait```

```modules-load=dwc2```

Create and empty file called ```ssh``` in the boot partition

```touch /path/to/sd/boot/ssh```

Create ```wpa_supplicant.conf``` in the boot partition and add the followig config.

```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
network={
    ssid="YOURSSID"
    psk="YOURPSK"
    key_mgmt=WPA-PSK
}
```

Unmount/Eject the SD card from your PC and use it to boot your Raspberry Pi Zero W.

At this point the Rraspberry Pi should boot and join your Wifi Network. You can find the IP address of your device from your router/DHCP server -or- you can attempt to resolve the device using the netowrk name ```raspberrypi.local```

SSH to your Raspberry Pi. (Default password is ```raspberry``` )

```ssh pi@raspberrypi.local```

Install the PiJuice command utilities/libraries 

```sudo apt-get install pijuice-base```

Enable the PiJuice ```Run Pin```

```pijuice_cli.py``` -> General -> Run pin -> INSTALLED -> Back -> Apply Settings -> Back -> Exit

Install the ```teslacam```  and ```powermonitor``` services

```
curl -o /home/pi/service.sh https://raw.githubusercontent.com/LelandSindt/teslacam/master/service.sh
curl -o /home/pi/powermonitor.py https://raw.githubusercontent.com/LelandSindt/teslacam/master/powermonitor.py
chmod -v +x powermonitor.py service.sh
sudo curl -o /etc/systemd/system/teslacam.service https://raw.githubusercontent.com/LelandSindt/teslacam/master/teslacam.service
sudo curl -o /etc/systemd/system/powermonitor.service https://raw.githubusercontent.com/LelandSindt/teslacam/master/powermonitor.service
sudo systemctl daemon-reload
sudo systemctl enable teslacam
sudo systemctl start teslacam
sudo systemctl enable powermonitor
sudo systemctl start powermonitor
```


Developed for/Tested on: 2018-10-09-raspbian-stretch-lite

Credit for some of the command/installation procedure goes to: https://www.reddit.com/r/raspberry_pi/comments/9mbgzn/tesla_v9_dash_cam_archiver/

# ToDo

* clenaup. (move the code further past POC)
* build installation script
