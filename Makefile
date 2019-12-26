WEB_DIR = "/var/www/rnlinux_deploy"
PKG_DIR = "packages"
CHROOT = "gentoo-stage3"

# Pre-defined packages. This will be automatically created when running 'make packages' or 'make all'
PACKAGES = scp parted mkfs.ext4 mkfs.fat lspci grub transmission tmux pigz partclone.ntfs

# Packages that may be usefull but not are needed for the deploy
EXTRA_PACKAGES = htop ping rsync screen strace bash amixer alsamixer mpv

.PHONY: packages extra_packages initramfs all clean deepclean
.PHONY: install

help:
	@echo "Run 'make all' if you really want to build everything."

all: initramfs packages kernel

clean:
	@echo Use deepclean if you also want to clean the kernel and stage3
	$(RM) labs-bootstrap-initramfs

deepclean:
	$(RM) labs-bootstrap-initramfs labs-bootstrap-kernel
	$(RM) -r gentoo-stage3

initramfs:
	@./create-initramfs

packages: $(PACKAGES)

extra_packages: $(EXTRA_PACKAGES)

# not adding dependencies so they're not compiled twice
install:
	cp labs-bootstrap-initramfs ${WEB_DIR}
	cp labs-bootstrap-kernel ${WEB_DIR}
	cp -r ${PKG_DIR} ${WEB_DIR}/

# By running any command the script will generate the stage3 if it doesn't exist
# This doesn't need to be in target 'all' or as a dependency since it is called by the other scripts
stage3:
	@./chroot-gentoo -c true

# Compile the kernel inside the chroot and copy it here
kernel:
	./chroot-gentoo -c "emerge -uv gentoo-sources"
	cp -f "helpers/labs-bootstrap-kernel-config" "$(CHROOT)/usr/src/linux/.config"
	./chroot-gentoo -c "cd /usr/src/linux && make olddefconfig"
	./chroot-gentoo -c "cd /usr/src/linux && make -j2"
	cp -f "$(CHROOT)/usr/src/linux/arch/x86_64/boot/bzImage" labs-bootstrap-kernel

# Generic rule for packages
%:
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz


### Specific packages creation below ###

lspci:
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz --pkg-hint "sys-apps/pciutils" \
		--add-file "/usr/share/misc/pci.ids.gz" "/usr/share/misc/pci.ids.gz"

grub:
	@./create-package --name "grub-install" --dest "$(PKG_DIR)/$@.tar.gz" --pkg-hint "sys-boot/grub" \
		--copy-dir "/usr/lib/grub" "/usr/lib/grub"

screen:
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz --pkg-hint "app-misc/screen"

amixer:
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz --pkg-hint "media-sound/alsa-utils"

# Not in the pre-defined packages because it takes long time to compile and obviosly
# it is not really necessary to deploy the labs
mpv:
	@# Make sure the necessary mpv flags are set since mpv will be emerged
	@# the first time this target runs in a new stage3
	@mkdir -p "$(CHROOT)/etc/portage/profile/package.use.mask"
	@echo "media-video/mpv -libcaca" > "$(CHROOT)/etc/portage/profile/package.use.mask/mpv"
	@echo "media-video/mpv libcaca" >  "$(CHROOT)/etc/portage/package.use/mpv"
	@echo 'audio:x:1000:' > /tmp/audio_group
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz \
		--copy-dir "/usr/share/alsa" "/usr/share/alsa" \
		--add-external-file "/tmp/audio_group" "/etc/group"
	@rm -f /tmp/audio_group

transmission:
	@./custom.sh transmission
	@helpers/transmission_config_filter.awk "/dev/shm/settings.json" > /tmp/transmission_settings.json
	@./create-package --name "/usr/bin/transmission-daemon" --dest "$(PKG_DIR)/$@.tar.gz" --pkg-hint "net-p2p/transmission" \
		--copy-dir /usr/share/transmission/web /usr/share/transmission/web \
		--add-external-file /tmp/transmission_settings.json /var/lib/transmission/settings.json \
		--add-external-file scripts/completeScript.sh /completeScript.sh \
		--create-dir /torrents \
		--create-dir /downloads \
		--create-dir /incomplete \

PARTCLONE_VERSION = 0.3.11
partclone.ntfs:
	./chroot-gentoo -c "emerge -uv ntfs3g"
	./chroot-gentoo -c "wget https://github.com/Thomas-Tsai/partclone/archive/$(PARTCLONE_VERSION).tar.gz -O partclone.tar.gz --progress=dot:mega"
	./chroot-gentoo -c "tar xf partclone.tar.gz"
	./chroot-gentoo -c "cd partclone-$(PARTCLONE_VERSION) && ./autogen && ./configure --enable-ntfs && make install"
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz --create-dir /var/log

mkfs.fat:
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz --pkg-hint "sys-fs/dosfstools"
