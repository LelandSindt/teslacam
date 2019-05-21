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
  #UnMount $teslacam_mount
  umount -v $teslacam_mount 
  losetup -v -d /dev/loop0

  #Remove $teslacam Mass stroage device
  sudo modprobe -v -r -C /tmp/teslacam.conf g_mass_storage

  #Mount $teslacam to $teslacam_mount
  losetup -v -o $(first_partition_offset $teslacam) loop0 $teslacam
  mount -v -o iocharset=utf8 -o shortname=mixed /dev/loop0 $teslacam_mount

  #Rsync files from $teslacam_mount to $teslacam_storage
  [ "$(ls -A $teslacam_mount/TeslaCam)" ] && rsync -av $teslacam_mount/TeslaCam/* $teslacam_storage

  #UnMount $teslacam_mount
  umount -v $teslacam_mount
  losetup -v -d /dev/loop0

  #Remove $teslacam
  rm -v $teslacam

  #Run remotesync hook...
  [ -x /home/pi/remotesync.sh ] && /home/pi/remotesync.sh $teslacam_storage
  exit 0
}

#Find the partition offset.
function first_partition_offset () {
  filename="$1"
  size_in_bytes=$(sfdisk -l -o Size -q --bytes "$1" | tail -1)
  size_in_sectors=$(sfdisk -l -o Sectors -q "$1" | tail -1)
  sector_size=$(($size_in_bytes/$size_in_sectors))
  partition_start_sector=$(sfdisk -l -o Start -q "$1" | tail -1)
  echo $(($partition_start_sector*$sector_size))
}

#Create required directories
[ -d $teslacam_storage ] || mkdir -p -v $teslacam_storage
[ -d $teslacam_mount ] || mkdir -p -v $teslacam_mount

#Remove $teslacam_previous
[ -e $teslacam_previous ] && rm -v $teslacam_previous

#Move $teslacam to $teslacam_previous
[ -e $teslacam ]  && mv -v $teslacam $teslacam_previous

#Create new $teslacam
fallocate -v -l "8192"MB $teslacam

#Partition $teslacam
echo "type=c" | sfdisk $teslacam > /dev/null
losetup -v -o $(first_partition_offset $teslacam) loop0 $teslacam

#Format $teslacam
mkfs.vfat -v /dev/loop0 -F 32 -n "TESLACAM"

#Mount $teslacam to $teslacam_mount
mount -v /dev/loop0 $teslacam_mount

#Create $teslacam_mount/TeslaCam directory
mkdir -p -v $teslacam_mount/TeslaCam

#UnMount $teslacam_mount
umount -v $teslacam_mount
losetup -v -d /dev/loop0

#Enable $teslacam Mass stroage device
echo "options g_mass_storage file=$teslacam removeable=1 ro=0 stall=0 iSerialNumber=123456" > /tmp/teslacam.conf
modprobe -v -C /tmp/teslacam.conf g_mass_storage

if [ -e $teslacam_previous ]
then
  #Mount $teslacam_previous to $teslacam_mount
  losetup -v -o $(first_partition_offset $teslacam_previous) loop1 $teslacam_previous
  mount -v /dev/loop1 $teslacam_mount

  #Rsync files from $teslacam_mount to $teslacam_storage
  [ "$(ls -A $teslacam_mount/TeslaCam)" ] && rsync -av $teslacam_mount/TeslaCam/* $teslacam_storage

  #UnMount $teslacam_mount
  umount -v $teslacam_mount
  losetup -v -d /dev/loop1
  #Remove $teslacam_previous
  rm -v $teslacam_previous
fi

echo "loop...."
while true; do
  sleep 300
  set -x
  while true; do
    if [ $(df / | awk '{print $4}' | tail -1) -lt 20980000 ] #if / (root) has less than 20GB available
    then
      #Removed 50 oldest files from $teslacam_stroage
      find $teslacam_storage -type f -printf '%T@\t%p\n' | sort -r | tail -n 50 | sed 's/[0-9]*\.[0-9]*\t//' | xargs -d '\n' rm -v -f
    else
      break
    fi
  done

  #Remove empty directories
  find /data/TeslaCam -type d \( ! -name TeslaCam \) -empty -delete
  set +x
  #Mount $teslacam to $teslacam_mount (read only)
  losetup -v -o $(first_partition_offset $teslacam) loop0 $teslacam
  mount -v -o iocharset=utf8 -o shortname=mixed -o ro /dev/loop0 $teslacam_mount

  #Rsync files from $teslacam_mount to $teslacam_storage
  [ "$(ls -A $teslacam_mount/TeslaCam)" ] && rsync -av $teslacam_mount/TeslaCam/* $teslacam_storage

  #UnMount $teslacam_mount
  umount -v $teslacam_mount
  losetup -v -d /dev/loop0

done

exit 0
