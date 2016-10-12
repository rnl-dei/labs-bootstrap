# Labs bootstrap initramfs
Framework to generate initramfs with the primary purpose of deploying new base images to our labs, or "How I accidentally created a Linux distribution".

## Quick How-to

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
The initramfs will get the packages from there automatically, nothing more neeeded to do.

### Create a new package
For example to create a package for rsync.

First make sure the program is installed in the gentoo chroot, searching for the executable, or in a more exquisite way like this:

```sh
$ ./chroot-gentoo -c "which rsync"
/usr/bin/rsync
```

It's installed in this case, but if it was not, install it like you would normally do in a chrooted gentoo system.
If you don't know this last words, just run the following:

```sh
$ ./chroot-gentoo -c "emerge -av rsync"
$ make rsync
```
The package should now be available for the initramfs like with pre-defined packages.

### Install a package

Packages created with the procedure above can be installed by using the `emerge` command inside the initramfs, like this:

```
[initramfs] stuart:~ # emerge rsync
 * rsync - Installation done
```