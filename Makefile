PKG_DIR = "/var/www/geminio/packages"
TRANSMISSION_CONFIG = "/root/rnlinux/roles/transmission/files/var/lib/transmission/.config/transmission/settings.json"

PACKAGES = strace parted mkfs.ext4 lspci grub mpv 

.PHONY: packages initramfs all

all: initramfs packages

initramfs:
	./create-initramfs

packages: $(PACKAGES)

define find_bin
	$(shell ./chroot-gentoo -c "which $(1)")
endef

# Generic rule
%:
	@./create-package $(call find_bin,$@) $(PKG_DIR)/$@.tar.gz

lspci:
	@./create-package $(call find_bin,$@) $(PKG_DIR)/$@.tar.gz \
		--add-file "/usr/share/misc/pci.ids.gz" "/usr/share/misc/pci.ids.gz"

grub:
	@./create-package "/usr/sbin/grub-install" "${PKG_DIR}/$@.tar.gz" \
		--copy-dir "/usr/lib/grub" "/usr/lib/grub"
	
mpv:
	@echo 'audio:x:1000:' > /tmp/audio_group
	@./create-package $(call find_bin,$@) $(PKG_DIR)/$@.tar.gz \
		--copy-dir "/usr/share/alsa" "/usr/share/alsa" \
		--add-external-file "/tmp/audio_group" "/etc/group"
	@rm -f /tmp/audio_group

transmission:
	@scripts/transmission_config_filter.awk "${TRANSMISSION_CONFIG}" > /tmp/transmission_settings.json

	@./create-package "/usr/bin/transmission-daemon" "${PKG_DIR}/$@.tar.gz" \
		--copy-dir /usr/share/transmission/web /usr/share/transmission/web \
		--add-external-file /tmp/transmission_settings.json /var/lib/transmission/settings.json \
		--add-external-file /root/labs-bootstrap/scripts/completeScript.sh /completeScript.sh \
		--create-dir /torrents \
		--create-dir /downloads \
		--create-dir /incomplete \