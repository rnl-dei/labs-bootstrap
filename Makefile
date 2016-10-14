PKG_DIR = "/var/www/geminio/packages"
TRANSMISSION_CONFIG = "/root/rnlinux/roles/transmission/files/var/lib/transmission/.config/transmission/settings.json"

PACKAGES = scp strace parted mkfs.ext4 lspci grub mpv

.PHONY: packages initramfs all

all: initramfs packages

initramfs:
	@./create-initramfs

stage3:
	@./chroot-gentoo -c "true"

packages: $(PACKAGES)

# Generic rule
%:
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz

lspci:
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz --pkg-hint "pciutils" \
		--add-file "/usr/share/misc/pci.ids.gz" "/usr/share/misc/pci.ids.gz"

grub:
	@./create-package --name "grub-install" --dest "${PKG_DIR}/$@.tar.gz" --pkg-hint "grub" \
		--copy-dir "/usr/lib/grub" "/usr/lib/grub"

mpv:
	@# Make sure the necessary mpv flags are set since mpv will be emerged
	@# the first time this target runs in a new stage3
	@mkdir -p "gentoo-stage3/etc/portage/profile/package.use.mask"
	@echo "media-video/mpv -libcaca" > "gentoo-stage3/etc/portage/profile/package.use.mask/mpv"
	@echo "media-video/mpv libcaca" >  "gentoo-stage3/etc/portage/package.use/mpv"
	@echo 'audio:x:1000:' > /tmp/audio_group
	@./create-package --name "$@" --dest $(PKG_DIR)/$@.tar.gz \
		--copy-dir "/usr/share/alsa" "/usr/share/alsa" \
		--add-external-file "/tmp/audio_group" "/etc/group"
	@rm -f /tmp/audio_group

transmission:
	@helpers/transmission_config_filter.awk "${TRANSMISSION_CONFIG}" > /tmp/transmission_settings.json

	@./create-package --name "/usr/bin/transmission-daemon" --dest "${PKG_DIR}/$@.tar.gz" \
		--copy-dir /usr/share/transmission/web /usr/share/transmission/web \
		--add-external-file /tmp/transmission_settings.json /var/lib/transmission/settings.json \
		--add-external-file /root/labs-bootstrap/scripts/completeScript.sh /completeScript.sh \
		--create-dir /torrents \
		--create-dir /downloads \
		--create-dir /incomplete \
