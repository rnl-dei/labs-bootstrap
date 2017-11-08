#!/bin/sh
set -e

logfile=deploy.log

redo_partitions=false
redo_windows=false
redo_linux=false

case "$1" in
  "--redo-all")
    redo_partitions=true
    redo_windows=true
    redo_linux=true
    shift
    ;;
  "--redo-partitions")
    redo_partitions=true
    shift
    ;;
  "--redo-windows")
    redo_windows=true
    shift
    ;;
  "--redo-linux")
    redo_linux=true
    shift
    ;;
  *)
    printf "Unrecognized option $1\n" | tee -a $logfile
    shift
    ;;
esac


if [[ $redo_partitions  ]];then
  echo Making Partition table | tee -a $logfile
  parted -s /dev/sda -- mklabel msdos 2>&1 | tee -a $logfile

  echo Creating Linux Partition  | tee -a $logfile
  parted -s /dev/sda -- mkpart primary ext3 2048s 2734079s
  parted -s /dev/sda -- mkpart primary ext2 2736128s 3123199s
  parted -s /dev/sda -- mkpart primary ntfs 3125248s 354686975s
  parted -s /dev/sda -- mkpart extended 354686976s -1s
  parted -s /dev/sda -- mkpart logical linux-swap 354689024s 358594559s
  parted -s /dev/sda -- mkpart logical ext4 358596608s 768555007s
  parted -s /dev/sda -- mkpart logical ext4 768751616s -1s
  parted -s /dev/sda -- set 3 "boot" "on" # set boot flag for windows partition
fi


echo Make filesystems  | tee -a $logfile

if [[ $redo_linux ]];then
  echo Making SDA3 Filesystem  | tee -a $logfile
  mkfs.ext4 -F /dev/sda6 2>&1 | tee -a $logfile

  echo Making SDA7 Filesystem  | tee -a $logfile
  mkfs.ext4 -F /dev/sda7 2>&1 | tee -a $logfile


  echo Making chroot dir  | tee -a $logfile
  mkdir /mnt/suse 2>&1 | tee -a $logfile

  echo Mouting chroot dir  | tee -a $logfile
  mount /dev/sda6 /mnt/suse 2>&1 | tee -a $logfile
  tar xf root.tar.xz -C /mnt/suse 2>&1 | tee -a $logfile

  echo Removing grub files  | tee -a $logfile
  rm -f /mnt/suse/etc/grub.d/05_suse_theme 2>&1 | tee -a $logfile
  rm -f /mnt/suse/etc/grub.d/30_os-prober 2>&1 | tee -a $logfile
  rm -f /mnt/suse/etc/grub.d/20_linux_xen 2>&1 | tee -a $logfile
  rm -f /mnt/suse/etc/grub.d/40_custom 2>&1 | tee -a $logfile
  rm -f /mnt/suse/etc/grub.d/41_custom 2>&1 | tee -a $logfile

  echo Create DFS mount point  | tee -a $logfile
  mkdir -p /mnt/suse/mnt/DFS 2>&1 | tee -a $logfile

  echo Copying FSTAB  | tee -a $logfile
  cp fstab /mnt/suse/etc/fstab 2>&1 | tee -a $logfile

  echo Adding Ansible Service
  cp ansible.service /mnt/suse/etc/systemd/system/ansible.service 2>&1 | tee -a $logfile

  #echo Copy Initial Deploy script
  #mkdir -p /mnt/suse/usr/lib/ansible | tee -a $logfile
  #cp ansible.sh /mnt/suse/usr/lib/ansible/ansible.sh 2>&1 | tee -a $logfile
  #cp nologin /mnt/suse/etc/nologin 2>&1 | tee -a $logfile

  echo Creating PROC directory  | tee -a $logfile
  mkdir -p /mnt/suse/proc 2>&1 | tee -a $logfile

  echo Creating DEV directory  | tee -a $logfile
  mkdir -p /mnt/suse/dev 2>&1 | tee -a $logfile

  echo Creating SYS directory  | tee -a $logfile
  mkdir -p /mnt/suse/sys 2>&1 | tee -a $logfile

  echo Mounting PROC directory  | tee -a $logfile
  mount -t proc none /mnt/suse/proc/ 2>&1 | tee -a $logfile

  echo Mounting DEV directory  | tee -a $logfile
  mount -o bind /dev /mnt/suse/dev/ 2>&1 | tee -a $logfile

  echo Mounting SYS directory  | tee -a $logfile
  mount -t sysfs /sys /mnt/suse/sys/ 2>&1 | tee -a $logfile

  sync

  echo Update existing grub install on MBR  | tee -a $logfile
  chroot /mnt/suse /usr/sbin/grub2-install /dev/sda 2>&1 | tee -a $logfile
  chroot /mnt/suse /sbin/mkinitrd 2>&1 | tee -a $logfile
  chroot /mnt/suse /usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg 2>&1 | tee -a $logfile
  chroot /mnt/suse /usr/bin/grub2-editenv - set count=0 2>&1 | tee -a $logfile

  echo Enabling Ansible Service on Boot
#chroot /mnt/suse zypper --non-interactive in tmux 2>&1 | tee -a $logfile
#chroot /mnt/suse systemctl enable ansible.service 2>&1 | tee -a $logfile

  echo "Umount /mnt/suse"
#  umount -R /mnt/suse/proc 2>&1 | tee -a $logfile
  #temporary fix for rebooting, sleep needed to give time to execute operation
  echo s > /proc/sysrq-trigger
  sleep 1
  echo u > /proc/sysrq-trigger
  sleep 1
  echo b > /proc/sysrq-trigger
fi

