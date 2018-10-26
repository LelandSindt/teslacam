#!/bin/bash
# trap ctrl-c and call ctrl_c()
trap terminate INT SIGTERM

teslacam_path="/"
teslacam_file="teslacam.bin"
teslacam_previous=$teslacam_path"previous_"$teslacam_file
teslacam_mount="/mnt/teslacam"
teslacam=$teslacam_path$teslacam_file
teslacam_storage="/data/TeslaCam"

function terminate() {
  echo "** Trapped CTRL-C"
  echo "UnMount $teslacam_mount"
  umount -v $teslacam_mount 
  echo "Remove $teslacam Mass stroage device..."
  sudo modprobe -v -r -C /tmp/teslacam.conf g_mass_storage
  echo "Mount $teslacam to $teslacam_mount"
  mount -v -o iocharset=utf8 -o shortname=mixed $teslacam $teslacam_mount
  echo "Rsync files from $teslacam_mount to $teslacam_storage"
  rsync -av --progress $teslacam_mount/TeslaCam/* $teslacam_storage
  echo "UnMount $teslacam_mount"
  umount -v $teslacam_mount
  echo "Remove $teslacam"
  rm -v $teslacam
  exit 0
}

echo "Create required directories"
mkdir -p -v $teslacam_storage $teslacam_mount

echo "Remove $teslacam_previous..."
rm -v $teslacam_previous || echo "no previous teslacam found (this is a good thing...)"

echo "Move $teslacam to $teslacam_previous..."
mv -v $teslacam $teslacam_previous || echo "move failed... "

echo "Create new $teslacam"
fallocate -v -l "2048"MB $teslacam || echo "creation failed..." 

echo "Format $teslacam"
mkdosfs $teslacam -v -F 32 -I 

echo "Mount $teslacam to $teslacam_mount"
mount -v $teslacam $teslacam_mount

echo "Create $teslacam_mount/TeslaCam directory"
mkdir -p -v $teslacam_mount/TeslaCam

echo "UnMount $teslacam_mount"
umount -v $teslacam_mount

echo "Enable $teslacam Mass stroage device..."
echo "options g_mass_storage file=$teslacam removeable=1 ro=0 stall=0 iSerialNumber=123456" > /tmp/teslacam.conf
modprobe -v -C /tmp/teslacam.conf g_mass_storage

echo "Mount $teslacam_previous to $teslacam_mount"
mount -v $teslacam_previous $teslacam_mount

echo "Rsync files from $teslacam_mount to $teslacam_storage"
rsync -v --progress $teslacam_mount/TeslaCam/* $teslacam_storage

echo "UnMount $teslacam_mount"
umount -v $teslacam_mount

echo "Remove $teslacam_previous"
rm -v $teslacam_previous

echo "loop...."
while true; do 
  sleep 600 
  echo "Mount $teslacam to $teslacam_mount (read only)" 
  mount -v  -o iocharset=utf8 -o shortname=mixed -o ro $teslacam $teslacam_mount

  echo "Rsync files from $teslacam_mount to $teslacam_storage"
  rsync -av --progress $teslacam_mount/TeslaCam/* $teslacam_storage

  echo "UnMount $teslacam_mount"
  umount -v $teslacam_mount
done

exit 0
