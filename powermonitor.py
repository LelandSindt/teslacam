#!/usr/bin/python 
import pijuice
import os
import time
import sys
pj=pijuice.PiJuice(1, 0x14)
pj.power.SetWakeUpOnCharge(0)
pj.power.SetSystemPowerSwitch(0)
powerloss = 0
sleeptime = 30
while True:
  time.sleep(int(sleeptime))
  sys.stdout.write(time.strftime("%Y-%m-%d %H:%M") + " Charge State: " + pj.status.GetStatus()['data']['powerInput5vIo'] + " Charge Percent: " +  str(pj.status.GetChargeLevel()['data']) + " Power Loss Count: " + str(powerloss) + "\n")
  sys.stdout.flush()
  if pj.status.GetStatus()['data']['powerInput5vIo'] == "NOT_PRESENT":
    powerloss = powerloss + 1
    sleeptime = 5
  else:
    powerloss = 0
    sleeptime = 30
  if powerloss > 10:
    sys.stdout.write("Stopping TeslaCam... \n")
    sys.stdout.flush()
    os.system("sudo systemctl stop teslacam")
    sys.stdout.write("Powering Down... \n")
    sys.stdout.flush()
    pj.power.SetSystemPowerSwitch(0)
    pj.power.SetPowerOff(30)
    os.system("sudo halt")
