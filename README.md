# Labs bootstrap initramfs
Framework to generate initramfs with the primary purpose of deploying new base images to our labs, or "How I accidentally created a Linux distribution".

## Emergency guide

Did you FUBAR? Or did the previous guy ragequit? Do not despair!
Only one command is needed to recreate everything as before.

```
$ git clone git@atenas.rnl.tecnico.ulisboa.pt:rnlinux/labs-bootstrap.git
$ cd labs-bootstrap
$ make all
```

Disclaimer: It still doesn't recreate the chroot and kernel, but this is a work in progress.

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
```
$ make packages
```
This will create all already pre-defined packages in `/var/www/geminio/packages/`.
The initramfs will get the packages from there automatically, nothing more neeeded to do.

### Create a new package
For example to create a package for rsync.

First make sure the program is installed in the gentoo chroot, searching for the executable, or in a more exquisite way like this:

```
$ ./chroot-gentoo -c "which rsync"
/usr/bin/rsync
```

It's installed in this case, but if it was not, install it like you would normally do in a chrooted gentoo system.
If you don't know this last words, just run the following:

```
$ ./chroot-gentoo -c "emerge -av rsync"
$ make rsync
...
/var/www/geminio/packages/rsync.tar.gz created, enjoy!
```
The package should now be available for the initramfs like with pre-defined packages.

### Install a package

Packages created with the procedure above can be installed by using the `emerge` command inside the initramfs, like this:

```
[initramfs] stuart:~ # emerge rsync
 * rsync - Installation done
```

## How does this all work?

The various components will be listed with a detailed explanation of its purpose and funcionality.

### mk-labs-bootstrap

This is the core of the framework, responsible for creating the initramfs and packages.
It is written to be relatively generic, with only the minimal initramfs stuff hardcoded,
with all the details being defined in commnand line options.

This script supports the creation of initramfs and packages based on executables of a chroot system,
or from the running system, but only the former is recommended and is used in the other scripts below.

### create-initramfs

Wrapper of the `mk-labs-bootstrap` that defines all options to create a functional initramfs customized for use in the labs workstations.

It currently sets the following options:
 * sshd config
 * SSH host keys
 * SSH authorized_keys
 * root password
 * Our self-signed CA certificate
 
This script doesn't need to run with any additional options.
```
$ ./create-initramfs
```

### create-package

Wrapper of the `mk-labs-bootstrap` to simplify the creation of simple packages of one executable.

```
./create-package <executable path> <archive path>
```

Example:
```sh
$ ./create-package "/usr/sbin/lspci" "/var/www/geminio/packages/lspci.tar.gz"
```

### chroot-gentoo

This is just a script to automate the usage of the chroot system, by mount and
umountthe necessary stuff before and after running the actual chroot call.

This is used by other scripts the execute thigs insied the chroot, and is also
for manual use, to compile/install the necessary stuff to use in the initramfs.

Simply calling the script will spawn a `sh` shell:
```
$ ./chroot-gentoo 
(gentoo chroot) / $
```

To execute only one command inside the chroot (to automate for example) it can be called like this:
```
$ ./chroot-gentoo -c "uname -a"
```
### Makefile / make

This is the high-level interface to the framework, to simplify its usage primarly
when recreating the pre-configured initramfs and packages.

It has a generic target that can quikcly create a simple package for one executable,
without the need for this specific exetuable to be listed of pre-configured anywhere.
It just needs to be available in the initramfs.

For example:
```
$ make rsync
...
/var/www/geminio/packages/rsync.tar.gz created, enjoy!
```

But for some packages, the archive needs to include more that the executable and
linked libraries to function. For exemple the transmission-daemon package needs to
include the files in `/usr/share/transmission/web` if we want to be able to use the
web interface.

This type of cases have specific targets in the `Makefile` with this extra options
to simplify the recreation in the future.

List of all available Makefile targets.

 * initramfs - Create the functional initramfs (just calls ./create-initramfs).
 * packages - Creates the packages pre-defined in the Makefile.
 * all - Creates both initramfs and packages.
 * kernel - To be done.
 
The pre-defined packages include the packages that have specific rules because of
extra files, and other packages that are considered useful to have available like
strace for debugging, or scp to manually copy files.

**The contents of this Makefile should help understand the general workings of complex
packages creation**, and most of it should be self-explanatory, but basic understanding
of Makefiles may be advisable.

### scripts directory

In the `scripts` directory are all scripts that are not meant to be called directly
by you. Most are to be included unchanged in the final initramfs, but there may also
be some to help creating the initramfs or packages.

 * init.sh - **THE** init script that is called when the kernel finishes booting up.
 * profile.sh - Various alias and functions to improve the initramfs shell experience.
 * dhcp_script.sh - Called by busybox's udhcpc to set up the network settings.
 * completeScript.sh - Called by transmission when a torrents finishes.
 * transmission_config_filter.awk - Used by the Makefile to adapt the labs transmission config to the initramfs.