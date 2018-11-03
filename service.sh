#!/bin/bash
# trap ctrl-c and call ctrl_c()
trap terminate INT SIGTERM

export teslacam_path="/"
export teslacam_file="teslacam.bin"
export teslacam_previous=$teslacam_path"previous_"$teslacam_file
export teslacam_mount="/mnt/teslacam"
export teslacam=$teslacam_path$teslacam_file
export teslacam_storage="/data/TeslaCam"

function terminate() {
  echo "** Trapped CTRL-C"
  #UnMount $teslacam_mount"
  umount -v $teslacam_mount 
  #Remove $teslacam Mass stroage device
  sudo modprobe -v -r -C /tmp/teslacam.conf g_mass_storage
  #Mount $teslacam to $teslacam_mount
  mount -v -o iocharset=utf8 -o shortname=mixed $teslacam $teslacam_mount
  #Rsync files from $teslacam_mount to $teslacam_storage
  [ "$(ls -A $teslacam_mount/TeslaCam)" ] && rsync -av $teslacam_mount/TeslaCam/* $teslacam_storage
  #UnMount $teslacam_mount
  umount -v $teslacam_mount
  #Remove $teslacam
  rm -v $teslacam
  #Run remotesync hook...
  [ -x /home/pi/remotesync.sh ] && /home/pi/remotesync.sh $teslacam_storage
  exit 0
}

#Create required directories
[ -d $teslacam_storage ] || mkdir -p -v $teslacam_storage
[ -d $teslacam_mount ] || mkdir -p -v $teslacam_mount

#Remove $teslacam_previous
[ -e $teslacam_previous ] && rm -v $teslacam_previous

#Move $teslacam to $teslacam_previous
[ -e $teslacam ]  && mv -v $teslacam $teslacam_previous

#Create new $teslacam
fallocate -v -l "2048"MB $teslacam

#Format $teslacam
mkdosfs $teslacam -v -F 32 -I 

#Mount $teslacam to $teslacam_mount
mount -v $teslacam $teslacam_mount

#Create $teslacam_mount/TeslaCam directory
mkdir -p -v $teslacam_mount/TeslaCam

#UnMount $teslacam_mount
umount -v $teslacam_mount

#Enable $teslacam Mass stroage device
echo "options g_mass_storage file=$teslacam removeable=1 ro=0 stall=0 iSerialNumber=123456" > /tmp/teslacam.conf
modprobe -v -C /tmp/teslacam.conf g_mass_storage

#Mount $teslacam_previous to $teslacam_mount
[ -e $teslacam_previous ] && mount -v $teslacam_previous $teslacam_mount

#Rsync files from $teslacam_mount to $teslacam_storage
[ "$(ls -A $teslacam_mount/TeslaCam)" ] && rsync -av $teslacam_mount/TeslaCam/* $teslacam_storage

#UnMount $teslacam_mount
[ -e $teslacam_previous ] && umount -v $teslacam_mount

#Remove $teslacam_previous
[ -e $teslacam_previous ] && rm -v $teslacam_previous

echo "loop...."
while true; do 
  sleep 600 
  #Mount $teslacam to $teslacam_mount (read only)
  mount -v -o iocharset=utf8 -o shortname=mixed -o ro $teslacam $teslacam_mount

  #Rsync files from $teslacam_mount to $teslacam_storage
  [ "$(ls -A $teslacam_mount/TeslaCam)" ] && rsync -av $teslacam_mount/TeslaCam/* $teslacam_storage

  #UnMount $teslacam_mount
  umount -v $teslacam_mount

done

exit 0
