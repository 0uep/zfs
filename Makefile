# SPDX-License-Identifier: CC0-1.0

PHONY += all
all:
	$(MAKE) clean
	time $(MAKE) deb-pkg
	sudo $(MAKE) install
	$(MAKE) list

PHONY += clean
clean:
	rm -rf deb-pkg

# Use "make DOCKER=podman" (or "make DOCKER=/path/to/docker") another container image builder
DOCKER ?= docker

# "make C=1" => use `ccache` and Dockerfile frontend image enabling BuildKit
ifneq ($(C),)
	ifeq ($(shell expr $(shell $(DOCKER) buildx inspect | grep ^Buildkit | sed -e 's/.\+ \([0-9]\+\).\([0-9]\+\).\([0-9]\+\)/\1\2\3/g') \>\= 2300), 1)
		C=1
	else
		C=0
	endif
endif

# Use "make Dockerfile=/path/to/a/Dockerfile" to specify an alternative Dockerfile
ifeq ($(C),0)
	Dockerfile ?= Dockerfile
else
	Dockerfile ?= Dockerfile.ccache
endif

# "make V=1" prints the detailed output of `docker build`
V ?= 0

deb-pkg:
ifeq ($(V),0)
	$(DOCKER) build -t linux-with-zfs-builtin -f $(Dockerfile) .
else
	PROGRESS_NO_TRUNC=1 $(DOCKER) build --progress plain -t linux-with-zfs-builtin -f $(Dockerfile) .
endif
	docker create --name zfs-container linux-with-zfs-builtin ""
	docker cp --quiet zfs-container:/deb-pkg/ .
	docker rm zfs-container
	ls -sh1 deb-pkg/*
	@echo '--------------------------------'
	@echo 'To continue: `sudo make install`'
	@echo '--------------------------------'

PHONY += install
install: install-headers install-image

PHONY += install-headers
install-headers:
	set -x ; dpkg -i deb-pkg/linux-headers-*+_*.deb 

PHONY += install-image
install-image:
	set -x ; dpkg -i deb-pkg/linux-image-*+_*.deb

PHONY += install-dbg
install-dbg:
	set -x ; dpkg -i deb-pkg/linux-image-*+-dbg_*.deb

PHONY += install-libc
install-image-libc:
	set -x ; dpkg -i deb-pkg/linux-libc-dev_*.deb

PHONY += install-all
install-all:
	set -x ; dpkg -i deb-pkg/*.deb

PHONY += list
list:
	ls -sh1 deb-pkg/* || :
	apt list --installed --all-versions "linux-image-*" "linux-headers-*" linux-libc-dev
	@echo '-----------------------------------------'
	@echo 'To uninstall: `sudo apt purge <pkg-name>`'
	@echo '-----------------------------------------'

PHONY += help
help:
	@echo  '     make all                - Run the following commands marked with a *'
	@echo  '*      make clean            - Remove the deb-pkg folder'
	@echo  '*      make deb-pkg          - Build linux kernel (in a container) => "deb-pkg" folder'
	@echo  '* sudo make install          - Install the linux kernel'
	@echo  '*      make list             - List installed kernel images'
	@echo  '  sudo make install-all      - Install all the following debian packages'
	@echo  '  sudo make install-headers  - Install the linux kernel headers'
	@echo  '  sudo make install-image    - Install the linux kernel image'
	@echo  '  sudo make install-dbg      - Install the debug symbols of the linux kernel image'
	@echo  '  sudo make install-libc     - Install the libc'
