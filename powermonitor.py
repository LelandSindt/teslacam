#!/usr/bin/python 
import pijuice
import os
import time
pj=pijuice.PiJuice(1, 0x14)
pj.power.SetWakeUpOnCharge(0)
pj.power.SetSystemPowerSwitch(0)
powerloss = 0
while True:
  time.sleep(2)
  print time.strftime("%Y-%m-%d %H:%M") + " Charge State: " + pj.status.GetStatus()['data']['powerInput5vIo'] + " Charge Percent: " +  str(pj.status.GetChargeLevel()['data']) + " Power Loss Count: " + str(powerloss)
  if pj.status.GetStatus()['data']['powerInput5vIo'] == "NOT_PRESENT":
    powerloss = powerloss + 1
  else:
    powerloss = 0
  if powerloss > 10:
    print("Stopping TeslaCam...")
    os.system("sudo systemctl stop teslacam")
    print("Powering Down...")
    pj.power.SetSystemPowerSwitch(0)
    pj.power.SetPowerOff(30)
    os.system("sudo halt")
