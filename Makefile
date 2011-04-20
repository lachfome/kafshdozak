ver=$(shell date +%Y.%m.%d)

WORKDIR=work
NAME=kafshdozak
INSTALL_DIR=kafshdozak
COMPRESS=xz

ARCH?=$(shell uname -m)

PWD=$(shell pwd)
FULLNAME=$(PWD)/$(NAME)-$(ver)-$(ARCH).iso

PACKAGES="$(shell cat packages.list)"

kver_FILE=$(WORKDIR)/root-image/etc/mkinitcpio.d/kernel26.kver

all: kafshdozak-iso

# Rules for each type of image
kafshdozak-iso: $(FULLNAME)

$(FULLNAME): base-fs
	mkarchiso -D $(INSTALL_DIR) -c $(COMPRESS) iso $(WORKDIR) $@

# This is the main rule for make the working filesystem.
base-fs: root-image bootfiles initcpio overlay iso-mounts


# Rules for make the root-image for base filesystem.
root-image: $(WORKDIR)/root-image/.arch-chroot
$(WORKDIR)/root-image/.arch-chroot:
	mkarchiso -D $(INSTALL_DIR) -p base create $(WORKDIR)
	mkarchiso -D $(INSTALL_DIR) -p $(PACKAGES) create $(WORKDIR)

# Rule for make /boot
bootfiles: root-image
	mkdir -p $(WORKDIR)/iso/$(INSTALL_DIR)/boot/$(ARCH)
	cp $(WORKDIR)/root-image/boot/System.map26 $(WORKDIR)/iso/$(INSTALL_DIR)/boot/$(ARCH)/
	cp $(WORKDIR)/root-image/boot/vmlinuz26 $(WORKDIR)/iso/$(INSTALL_DIR)/boot/$(ARCH)/
	mkdir -p $(WORKDIR)/iso/syslinux
	cp $(WORKDIR)/root-image/usr/lib/syslinux/isolinux.bin $(WORKDIR)/iso/syslinux/
	cp boot-files/syslinux/syslinux.cfg $(WORKDIR)/iso/syslinux/syslinux.cfg

# Rules for initcpio images
initcpio: $(WORKDIR)/iso/$(INSTALL_DIR)/boot/$(ARCH)/archiso.img
$(WORKDIR)/iso/$(INSTALL_DIR)/boot/$(ARCH)/archiso.img: mkinitcpio.conf $(WORKDIR)/root-image/.arch-chroot
	mkdir -p $(WORKDIR)/iso/$(INSTALL_DIR)/boot/$(ARCH)/
	mkinitcpio -c ./mkinitcpio.conf -b $(WORKDIR)/root-image -k $(shell grep ^ALL_kver $(kver_FILE) | cut -d= -f2) -g $@


# overlay filesystem
overlay:
	cp -r overlay $(WORKDIR)/


# Rule to process isomounts file.
iso-mounts: $(WORKDIR)/iso/$(INSTALL_DIR)/isomounts
$(WORKDIR)/iso/$(INSTALL_DIR)/isomounts: isomounts root-image
	sed "s|@ARCH@|$(ARCH)|g" isomounts > $@


# Clean-up all work
clean:
	rm -rf $(WORKDIR) $(FULLNAME)


.PHONY: all kafshdozak-iso
.PHONY: base-fs
.PHONY: root-image bootfiles initcpio overlay iso-mounts
.PHONY: clean
