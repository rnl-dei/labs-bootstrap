# Labs bootstrap initramfs
Framework to generate initramfs with the primary purpose of deploying new base images to our labs, or "How I accidentally created a Linux distribution".

## Quick guide

What you need to quickly work with what the tools are already configured for.

Before anything else, change to the labs-bootstrap directory.

```sh
$ cd labs-boostrap
```

### Create new initramfs

```sh
$ make initramfs
```
This should create the file `labs-bootstrap-initramfs`.
Put this in the /boot of the machine, and as the initrd parameter of the grub entry, and it is done.


### Create pre-defined packages
```sh
$ make packages
```
This will create all already pre-defined packages in `/var/www/geminio/packages/`.
The initramfs will get the packages there automatically, nothing more to do.

### Create new package
For exemple to create a package for rsync.

First make sure the program is installed in gentoo chroot, like:

```sh
$ ./chroot-gentoo -c "whereis rsync"
rsync: /usr/bin/rsync /usr/share/rsync
```

If it is not installed, install it like you would normally do in a chrooted gentoo system, but if if doen't know what any of this words means, just run the following:

```sh
$ ./chroot-gentoo
(gentoo chroot) / $ emerge -av rsync
(gentoo chroot) / $ exit
$ make rsync
```