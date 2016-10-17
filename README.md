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

This will take a while since it first has to download and setup a new gentoo stage3, and emerge the necessary packages.

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
Put this in the /boot of the machine, and as the `initrd parameter` of the grub entry, and it is done.

### Create new kernel

```sh
$ make kernel
```
This should create the file `labs-bootstrap-kernel`.
Put this in the /boot of the machine, and as the `kernel parameter` of the grub entry, and it is done.

### Create pre-defined packages
```
$ make packages
```
This will create all already pre-defined packages in `/var/www/geminio/packages/`.
The initramfs will get the packages from there automatically, nothing more neeeded to do.

### Create a new package
For example to create a package for rsync, just run the following:
```
$ make rsync
...
/var/www/geminio/packages/rsync.tar.gz created, enjoy!
```
The package should now be available for the initramfs like with pre-defined packages.

In case the program isn't installed on the stage3, the script will try to guess the package needed and install it.
In case the script can't guess, you can always chroot to the stage3 and do whatever needed.

To find if the executable is installed you can run something like this like this:
```
$ ./chroot-gentoo -c "which rsync"
/usr/bin/rsync
```

It's installed in this case, but if it was not, install it like you would normally do in a chrooted gentoo system.
```
$ ./chroot-gentoo -c "emerge -av rsync"
```

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
./create-package --name <executable path> --dest <archive path>
```

Examples:
```sh
$ ./create-package --name "rsync" --dest "/var/www/geminio/packages/rsync.tar.gz"
$ ./create-package --name "/usr/bin/scp" --dest "/var/www/geminio/packages/scp.tar.gz"
$ ./create-package --name "grub-install" --dest "/var/www/geminio/packages/scp.tar.gz" --pkg-hint "grub"
```

The `--name` argument can be the name of the executable to find in the stage3, or
a direct path to it.

The `--pkg-hint` is optional, and can be given when the script cannot guess the
package from the executable name, like when these do not match.

### chroot-gentoo

This is just a script to automate the setup and usage of the chroot system, by doing
necessary the stuff before and after running the actual chroot call.

This is used by other scripts the execute thigs inside the chroot, and is also
for manual use, to compile/install the necessary stuff to use in the initramfs.

Simply calling the script will spawn a `sh` shell:
```
$ ./chroot-gentoo 
(gentoo chroot) / $
```

To execute only one command inside the chroot (to automate for example) it can be
called like this:
```
$ ./chroot-gentoo -c "uname -a"
```
In case the stage3 (`gentoo-stage3` directory) doesn't exist or doesn't have a valid
stage3, this script will download and extract a new one, and setup the necessary
configurations and packages to be usable by the other scripts.

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

 * **initramfs** - Create the functional initramfs (just calls `create-initramfs`). Generates `labs-bootstrap-initramfs`.
 * **packages** - Creates the packages pre-defined in the Makefile.
 * **stage3** - Checks if the stage3 is fine, creating a new one if it doesn't.
 * **kernel** - Compiles the kernel to be used by the initramfs. Generates `labs-bootstrap-kernel`.
 * **all** - Creates both initramfs, packages and kernel.
 
The pre-defined packages include the packages that have specific rules because of
extra files, and other packages that are considered useful to have available like
strace for debugging, or scp to manually copy files.

**The contents of this Makefile should help understand the general workings of complex
packages creation**, and most of it should be self-explanatory, but basic understanding
of Makefiles may be advisable.

### scripts directory

In the `scripts` directory are scripts that are not meant to be called directly
by you. They are to be included unchanged in the final initramfs.

 * init.sh - **THE** init script that is called when the kernel finishes booting up.
 * profile.sh - Various alias and functions to improve the initramfs shell experience.
 * dhcp_script.sh - Called by busybox's udhcpc to set up the network settings.
 * completeScript.sh - Called by transmission when a torrents finishes.
 * shutdown.sh - Installed as `shutdown` in PATH. To be called to do a clean shutdown.
 
 ### helpers directory
 
In the `helpers` directory are scripts and files to be used by other scripts to
help create the initramfs or packages.

 * transmission_config_filter.awk - Used by the Makefile to adapt the labs transmission config to the initramfs.
 * make.conf - Gentoo main config to copy to the stage3.
 * gentoo-repos.conf - Other gentoo config to topy to the stage3.
 * labs-bootstrap-kernel-config - Kernel config to be used in the stage3 kernel compilation.