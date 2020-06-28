# Labs bootstrap initramfs framework
Framework to generate an initramfs with the primary purpose of deploying new base images to our labs, or "How I accidentally created a Linux distribution".

If you want to make a USB drive with the rescue image, take a look at mkrescue.

## Emergency guide

Did you FUBAR? Or did the previous guy ragequit? Do not despair!
Only one command is needed to recreate everything as before.

```
$ git clone <this repo URL>
$ cd labs-bootstrap
$ make all
$ make install
```

This will take a while since it first has to download and setup a new
[gentoo stage3](https://wiki.gentoo.org/wiki/Stage_tarball)
and [emerge](https://wiki.gentoo.org/wiki/Portage) the necessary packages.

## Quick How-to

What you need to quickly work with what the tools are already configured for.

Before anything else, change to the labs-bootstrap directory.

```sh
$ cd labs-boostrap
```

### Create a new initramfs

```sh
$ make initramfs
```
This should create the file `labs-bootstrap-initramfs`.
This file should be placed in the `/boot` folder/partition of the machine.
Don't forget to add it to the `initrd` parameter of the corresponding GRUB entry.

### Create a new kernel

```sh
$ make kernel
```
This should create the file `labs-bootstrap-kernel`.
This file should be placed in the `/boot` folder/partition of the machine
and added as the `kernel` parameter of the corresponding GRUB entry.

### Create the pre-defined packages
```
$ make packages
```
This will create all pre-defined packages.
The initramfs will get the packages from there automatically, nothing more needed to do,
given that a web server is already working to serve files from there.

Don't forget to copy the packages to the webroot dir using `make install`.

### Create a new package
For example, to create a package for `rsync`, just run the following:
```
$ make rsync
...
packages/rsync.tar.gz created, enjoy!
```
Then, copy the package to the webroot packages dir.

The package should now be available for the initramfs like with pre-defined packages.

If the program is not already installed on the stage3,
the script will try to guess which package is needed and install it.
If the script is unable to guess, you can always chroot to the stage3 and do whatever is needed.

To find out if the executable is installed you,
can run something like this like this:
```
$ ./chroot-gentoo -c "which rsync"
/usr/bin/rsync
```

In this example, rsync is already installed.
If it was not available, you could install it like you would normally do in a chrooted gentoo system:
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

The various components will be listed with a detailed explanation of its purpose and functionality.

### mk-labs-bootstrap

This is the core of the framework, responsible for creating the initramfs and packages.
It is written to be relatively generic, with only the minimal initramfs stuff hard-coded,
with all the details being defined in command line options.

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
$ ./create-package --name "rsync" --dest "/var/www/deploy/webroot/packages/rsync.tar.gz"
$ ./create-package --name "/usr/bin/scp" --dest "/var/www/deploy/webroot/packages/scp.tar.gz"
$ ./create-package --name "grub-install" --dest "/var/www/deploy/webroot/packages/scp.tar.gz" --pkg-hint "grub"
```

The `--name` argument can be the name of the executable to find in the stage3, or
a direct path to it.

The `--pkg-hint` is optional, and can be given when the script cannot guess the
package from the executable name, like when these do not match.

### chroot-gentoo

This is just a script to automate the setup and usage of the chroot system, by doing
necessary the stuff before and after running the actual chroot call.

This is used by other scripts the execute things inside the chroot, and is also
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

This is the high-level interface to the framework, to simplify its usage primarily
when recreating the pre-configured initramfs and packages.

It has a generic target that can quickly create a simple package for one executable,
without the need for this specific executable to be listed of pre-configured anywhere.
It just needs to be available in the initramfs.

For example:
```
$ make rsync
...
/var/www/deploy/webroot/packages/rsync.tar.gz created, enjoy!
```

But for some packages, the archive needs to include more that the executable and
linked libraries to function. For example the transmission-daemon package needs to
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
 * **install** - Copies the generated files (initramfs, kernel and packages) into the deploy webroot folder.

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

## Webserver

 Altough the initramfs can function standalone, it was made with the purpose of
 relying on a web server for on-the-fly customization, so that the initramfs doesn't
 need to be updated to do new stuff, and even install and run new software.

### Packages

When the initramfs tries to install a new package it tries `<server>/packages/<package name>.tar.gz`.

The Makefile has the variable `PKG_DIR` that defines where it should put new packages.
This variable should have the root directory of the URL above.

### do.sh

After the init script finishes booting, and before it enter the login loop, it
downloads `<server>/do.sh`, and sources it. Therefore, this URL should return an
`sh` script, that can call the init script functions, and either can finish or
enter an endless loop that never returns.

Since this script is downloaded each time, it can be used to change the actions the
initramfs perform each time, and accordingly to the machine that runs it.

A php backend to this was previously on this repository but as since moved to its own repository.

The only detail to keep in mind for compatibility is that the init script includes all kernel
boot options in the do.sh URL, like `/do.sh?option1&option2=value2&option3`.
