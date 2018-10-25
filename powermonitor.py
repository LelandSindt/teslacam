#!/usr/bin/python 

# root's crontab 
# m h  dom mon dow   command
#  * *  *   *   *     /home/pi/powermonitor.py
import pijuice
import os
pj=pijuice.PiJuice(1, 0x14)
pj.power.SetWakeUpOnCharge(0)
if pj.status.GetStatus()['data']['powerInput5vIo'] == "NOT_PRESENT":
  os.system("sudo halt")
